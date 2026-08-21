import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as Act;
using Toybox.Complications;
using Toybox.Time.Gregorian as Calendar;

class WatchFaceData {
  private const PRESSURE_REFRESH_SECONDS = 600;
  private const PRESSURE_HISTORY_SECONDS = 10800;
  private const PRESSURE_MIN_SAMPLES = 10;
  private const PRESSURE_MIN_HOURS = 2.0;

  private var _bodyBatteryRefreshMinute = null;
  private var _bodyBatteryValue = "--";
  private var _bodyBatteryIcon = "0";
  private var _nextEventRefreshAt = 0;
  private var _nextEventString = "";
  private var _nextEventTime = null;
  private var _recoveryRefreshAt = 0;
  private var _recoveryTime = null;
  private var _dawnDuskDay = null;
  private var _dawnDuskRetryAt = 0;
  private var _dawnDuskInfo = null;
  private var _dateDay = null;
  private var _dateDayOfWeek = "";
  private var _dateDayOfMonth = "";
  private var _alternateRefreshMinute = null;
  private var _alternateTime = null;
  private var _pressureRefreshAt = 0;
  private var _pressureTrend = "--";

  public function initialize() {}

  public function refresh(nowValue) as Void {
    refreshBodyBattery(nowValue);
    refreshNextEvent(nowValue);
    refreshRecoveryTime(nowValue);
    refreshDawnDusk(nowValue);
    refreshDate();
    refreshAlternateTime(nowValue);
    refreshPressureTrend(nowValue);
  }

  public function getBodyBatteryValue() {
    return _bodyBatteryValue;
  }

  public function getBodyBatteryIcon() {
    return _bodyBatteryIcon;
  }

  public function getNextEventString() {
    return _nextEventString;
  }

  public function getNextEventTime() {
    return _nextEventTime;
  }

  public function getRecoveryTime() {
    return _recoveryTime;
  }

  public function getDawnDuskInfo() {
    return _dawnDuskInfo;
  }

  public function getDateDayOfWeek() {
    return _dateDayOfWeek;
  }

  public function getDateDayOfMonth() {
    return _dateDayOfMonth;
  }

  public function getAlternateTime() {
    return _alternateTime;
  }

  public function getPressureTrend() {
    return _pressureTrend;
  }

  // Heart rate intentionally remains live rather than using a cache.
  public function getHeartRate() {
    var heartRate = null;
    var activityInfo = Activity.getActivityInfo();
    if (activityInfo != null && activityInfo has :currentHeartRate) {
      heartRate = activityInfo.currentHeartRate;
    }

    if (heartRate == null && Act has :getHeartRateHistory) {
      var heartRateHistory = Act.getHeartRateHistory(1, true);
      if (heartRateHistory != null) {
        var heartRateSample = heartRateHistory.next();
        if (
          heartRateSample != null &&
          heartRateSample.heartRate != Act.INVALID_HR_SAMPLE
        ) {
          heartRate = heartRateSample.heartRate;
        }
      }
    }

    return heartRate != null ? heartRate.toString() : "--";
  }

  private function getBodyBatteryIterator() {
    if (
      Toybox has :SensorHistory &&
      Toybox.SensorHistory has :getBodyBatteryHistory
    ) {
      return Toybox.SensorHistory.getBodyBatteryHistory({ :period => 1 });
    }
    return null;
  }

  private function refreshBodyBattery(nowValue) as Void {
    var refreshMinute = Math.floor(nowValue / 60.0);
    if (_bodyBatteryRefreshMinute == refreshMinute) {
      return;
    }

    _bodyBatteryRefreshMinute = refreshMinute;
    _bodyBatteryValue = "--";
    _bodyBatteryIcon = "0";

    try {
      var iterator = getBodyBatteryIterator();
      if (iterator != null) {
        var sample = iterator.next();
        if (sample != null && sample.data != null) {
          var value = sample.data.toNumber();
          _bodyBatteryValue = value.toString();
          if (value <= 15) {
            _bodyBatteryIcon = "2";
          } else if (value <= 50) {
            _bodyBatteryIcon = "1";
          }
        }
      }
    } catch (ex) {
      _bodyBatteryValue = "--";
    }
  }

  private function refreshNextEvent(nowValue) as Void {
    if (nowValue < _nextEventRefreshAt) {
      return;
    }

    _nextEventRefreshAt = nowValue + 600;
    _nextEventString = "";
    _nextEventTime = null;

    try {
      var eventId = new Complications.Id(
        Complications.COMPLICATION_TYPE_CALENDAR_EVENTS
      );
      var complication = Complications.getComplication(eventId);
      if (complication.value != null) {
        _nextEventString = complication.value.toString();
        _nextEventTime = parseEventTime(_nextEventString);
      }
    } catch (ex) {
      _nextEventString = "";
      _nextEventTime = null;
    }
  }

  private function parseEventTime(value) {
    var colonIndex = value.find(":");
    if (colonIndex == null || colonIndex < 1 || value.length() < colonIndex + 4) {
      return null;
    }

    var hour = value.substring(0, colonIndex).toNumber();
    var minute = value
      .substring(colonIndex + 1, value.length() - 1)
      .toNumber();
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
      return null;
    }

    var amPm = value
      .substring(value.length() - 1, value.length())
      .toLower();
    if (amPm.equals("a")) {
      if (hour == 12) {
        hour = 0;
      }
    } else if (amPm.equals("p")) {
      if (hour != 12) {
        hour += 12;
      }
    }

    var nowInfo = Gregorian.utcInfo(Time.now(), Time.FORMAT_LONG);
    var eventMoment = Gregorian.moment({
      :year => nowInfo.year,
      :month => nowInfo.month,
      :day => nowInfo.day,
      :hour => hour,
      :minute => minute,
      :second => 0,
    });
    return Gregorian.utcInfo(eventMoment, Time.FORMAT_LONG);
  }

  private function refreshRecoveryTime(nowValue) as Void {
    if (nowValue < _recoveryRefreshAt) {
      return;
    }

    try {
      var info = ActivityMonitor.getInfo();
      _recoveryTime = info != null ? info.timeToRecovery : null;
    } catch (ex) {
      _recoveryTime = null;
    }
    _recoveryRefreshAt = nowValue + (_recoveryTime != null ? 3600 : 600);
  }

  private function refreshDawnDusk(nowValue) as Void {
    var todayValue = Time.today().value();
    if (_dawnDuskDay == todayValue && _dawnDuskInfo != null) {
      return;
    }
    if (_dawnDuskDay == todayValue && nowValue < _dawnDuskRetryAt) {
      return;
    }

    _dawnDuskDay = todayValue;
    try {
      _dawnDuskInfo = fetchDawnDuskInfo();
    } catch (ex) {
      _dawnDuskInfo = null;
    }
    if (_dawnDuskInfo == null) {
      _dawnDuskRetryAt = nowValue + 600;
    }
  }

  private function fetchDawnDuskInfo() {
    if (
      !(Toybox has :Weather) ||
      !(Weather has :getSunrise) ||
      !(Weather has :getSunset)
    ) {
      return null;
    }

    var conditions = Weather.getCurrentConditions();
    if (conditions == null || conditions.observationLocationPosition == null) {
      return null;
    }

    var today = Time.today();
    var location = conditions.observationLocationPosition;
    var sunrise = Weather.getSunrise(location, today);
    var sunset = Weather.getSunset(location, today);
    var info = [];
    if (sunrise != null) {
      info.add(["Dawn", getClockAngle(sunrise)]);
    }
    if (sunset != null) {
      info.add(["Dusk", getClockAngle(sunset)]);
    }
    return info.size() > 0 ? info : null;
  }

  private function getClockAngle(moment) {
    return ((moment.value() - Time.today().value().toDouble()) /
      (Time.Gregorian.SECONDS_PER_DAY / 2.0)) *
      Math.PI *
      2.0;
  }

  private function refreshDate() as Void {
    var todayValue = Time.today().value();
    if (_dateDay == todayValue) {
      return;
    }

    var info = Calendar.info(Time.now(), Time.FORMAT_LONG);
    _dateDay = todayValue;
    _dateDayOfWeek = Lang.format("$1$", [info.day_of_week]);
    _dateDayOfMonth = Lang.format("$1$", [info.day.format("%02d")]);
  }

  private function refreshAlternateTime(nowValue) as Void {
    var refreshMinute = Math.floor(nowValue / 60.0);
    if (_alternateRefreshMinute == refreshMinute && _alternateTime != null) {
      return;
    }

    var utcMoment = Time.now();
    var utcInfo = Gregorian.utcInfo(utcMoment, Time.FORMAT_SHORT);
    var isDst =
      (utcInfo.month > 3 && utcInfo.month < 11) ||
      (utcInfo.month == 3 && utcInfo.day >= 8) ||
      (utcInfo.month == 11 && utcInfo.day < 7);
    var offset = isDst ? -7 * 3600 : -8 * 3600;
    var alternateMoment = utcMoment.add(new Time.Duration(offset));
    _alternateTime = Gregorian.utcInfo(
      alternateMoment,
      Time.FORMAT_SHORT
    );
    _alternateRefreshMinute = refreshMinute;
  }

  private function refreshPressureTrend(nowValue) as Void {
    if (nowValue < _pressureRefreshAt) {
      return;
    }

    _pressureRefreshAt = nowValue + PRESSURE_REFRESH_SECONDS;
    if (
      !(Toybox has :SensorHistory) ||
      !(Toybox.SensorHistory has :getPressureHistory)
    ) {
      return;
    }

    try {
      var iterator = Toybox.SensorHistory.getPressureHistory({
        :period => new Time.Duration(PRESSURE_HISTORY_SECONDS),
        :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST,
      });
      var firstTimestamp = null;
      var spanHours = 0.0;
      var count = 0;
      var sumX = 0.0;
      var sumY = 0.0;
      var sumXX = 0.0;
      var sumXY = 0.0;
      var sample = iterator.next();

      while (sample != null) {
        if (sample.data != null) {
          var timestamp = sample.when.value();
          if (firstTimestamp == null) {
            firstTimestamp = timestamp;
          }

          var hours = (timestamp - firstTimestamp) / 3600.0;
          var pressure = sample.data / 100.0;
          count += 1;
          spanHours = hours;
          sumX += hours;
          sumY += pressure;
          sumXX += hours * hours;
          sumXY += hours * pressure;
        }
        sample = iterator.next();
      }

      if (count < PRESSURE_MIN_SAMPLES || spanHours < PRESSURE_MIN_HOURS) {
        return;
      }

      var denominator = count * sumXX - sumX * sumX;
      if (denominator.abs() < 0.0001) {
        return;
      }

      var slope = (count * sumXY - sumX * sumY) / denominator;
      var threeHourChange = slope * 3.0;
      if (threeHourChange <= -2.0) {
        _pressureTrend = "RN";
      } else if (threeHourChange <= -0.5) {
        _pressureTrend = "FL";
      } else if (threeHourChange >= 0.5) {
        _pressureTrend = "RS";
      } else {
        _pressureTrend = "ST";
      }
    } catch (ex) {}
  }
}
