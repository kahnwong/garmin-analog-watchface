import Toybox.Graphics;
using Toybox.Graphics as Gfx;

class WidgetRenderer {
  private const DATE_OUTER_MARGIN = 5;
  private const DATE_HORIZONTAL_PADDING = 5;
  private const DATE_VERTICAL_PADDING = 2;
  private const DATE_CENTER_Y_FACTOR = 0.545;

  private var _width;
  private var _height;
  private var _circleX;
  private var _circleY;
  private var _circleRadius;
  private var _iconsFont;
  private var _monospaceFont;
  private var _pokemonFont;
  private var _materialDesignFont;
  private var _barometerBuffer as BufferedBitmap?;
  private var _barometerSamples = null;
  private var _barometerColor = null;
  private var _barometerCacheUnavailable = false;

  public function initialize(
    width,
    height,
    circleX,
    circleY,
    circleRadius,
    iconsFont,
    monospaceFont,
    pokemonFont,
    materialDesignFont
  ) {
    _width = width;
    _height = height;
    _circleX = circleX;
    _circleY = circleY;
    _circleRadius = circleRadius;
    _iconsFont = iconsFont;
    _monospaceFont = monospaceFont;
    _pokemonFont = pokemonFont;
    _materialDesignFont = materialDesignFont;
  }

  public function drawBodyBattery(dc, icon, value) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(_circleX, _circleY, _circleRadius + 2);
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

    if (_width <= 176) {
      dc.drawText(
        _width * 0.82,
        _height * 0.02,
        _pokemonFont,
        icon,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        _width * 0.82,
        _height * 0.16,
        Gfx.FONT_GLANCE_NUMBER,
        value,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }

  public function drawHeartRate(dc, textColor, value) as Void {
    drawMetricRow(dc, textColor, _height * 0.5 + 20, "p", value);
  }

  public function drawRecoveryTime(dc, textColor, value) as Void {
    if (value != null && value > 1) {
      drawMetricRow(dc, textColor, _height * 0.5 + 40, "t", value);
    }
  }

  public function drawNextEvent(dc, textColor, value, relativeValue) as Void {
    if (value.equals("")) {
      return;
    }

    var iconX = _width * 0.25;
    var eventTextX = iconX + 30;

    dc.setColor(textColor, Gfx.COLOR_BLACK);
    dc.drawText(
      iconX,
      39,
      _materialDesignFont,
      "c",
      Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
    );
    dc.drawText(
      eventTextX,
      40,
      Gfx.FONT_SYSTEM_XTINY,
      value,
      Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
    );
    if (!relativeValue.equals("")) {
      var eventTextLeft = eventTextX -
        dc.getTextWidthInPixels(value, Gfx.FONT_SYSTEM_XTINY) / 2;
      dc.drawText(
        eventTextLeft,
        60,
        Gfx.FONT_SYSTEM_XTINY,
        relativeValue,
        Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  public function drawDate(dc, dayOfWeek, dayOfMonth) as Void {
    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

    var boxHeight = dc.getFontHeight(_monospaceFont) +
      DATE_VERTICAL_PADDING * 2;
    var boxY = _height * DATE_CENTER_Y_FACTOR - boxHeight / 2;
    var dayBoxWidth = dc.getTextWidthInPixels(dayOfWeek, _monospaceFont) +
      DATE_HORIZONTAL_PADDING * 2;
    var dateBoxWidth = dc.getTextWidthInPixels(dayOfMonth, _monospaceFont) +
      DATE_HORIZONTAL_PADDING * 2;

    drawBoxedText(
      dc,
      dayOfWeek,
      DATE_OUTER_MARGIN,
      boxY,
      dayBoxWidth,
      boxHeight
    );
    drawBoxedText(
      dc,
      dayOfMonth,
      _width - DATE_OUTER_MARGIN - dateBoxWidth,
      boxY,
      dateBoxWidth,
      boxHeight
    );
  }

  public function drawPressureTrend(dc, textColor, value) as Void {
    dc.setColor(textColor, Gfx.COLOR_BLACK);
    dc.drawText(
      _width * 0.25,
      _height * 0.70,
      _materialDesignFont,
      value,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }

  public function drawBarometerChart(dc, textColor, samples) as Void {
    var x = (_width * 0.12).toNumber();
    var y = (_height * 0.69).toNumber();
    var width = (_width * 0.20).toNumber();
    var height = (_height * 0.12).toNumber();

    if (!_barometerCacheUnavailable &&
        (_barometerBuffer == null || _barometerColor != textColor)) {
      try {
        var options = {
          :width => width + 1,
          :height => height + 1,
          :palette => [Gfx.COLOR_BLACK, textColor],
        };
        if (Graphics has :createBufferedBitmap) {
          _barometerBuffer = Graphics.createBufferedBitmap(options).get() as BufferedBitmap;
        } else if (Graphics has :BufferedBitmap) {
          _barometerBuffer = new Graphics.BufferedBitmap(options);
        }
        _barometerSamples = null;
      } catch (ex) {
        _barometerBuffer = null;
      }
      _barometerCacheUnavailable = _barometerBuffer == null;
    }

    if (_barometerBuffer != null) {
      // Data replaces its sample array only on refresh. Layout recreates this renderer.
      if (_barometerSamples != samples || _barometerColor != textColor) {
        var chartDc = _barometerBuffer.getDc();
        // Monochrome bitmap palettes need real colors; transparency can
        // map to white and turn the entire cached chart into a rectangle.
        chartDc.setColor(textColor, Gfx.COLOR_BLACK);
        chartDc.clear();
        renderBarometerChart(chartDc, textColor, samples, 0, 0, width, height, x + y);
        _barometerSamples = samples;
        _barometerColor = textColor;
      }
      dc.drawBitmap(x, y, _barometerBuffer);
    } else {
      renderBarometerChart(dc, textColor, samples, x, y, width, height, 0);
    }
  }

  private function renderBarometerChart(dc, textColor, samples, x, y, width, height, patternOffset) as Void {
    var minimum = null;
    var maximum = null;
    for (var i = 0; i < samples.size(); i += 1) {
      var pressure = samples[i];
      if (pressure != null) {
        if (minimum == null || pressure < minimum) {
          minimum = pressure;
        }
        if (maximum == null || pressure > maximum) {
          maximum = pressure;
        }
      }
    }

    dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
    dc.setPenWidth(1);
    dc.drawLine(x, y + height, x + width, y + height);
    if (minimum != null) {
      // Keep flat readings centered and avoid exaggerating tiny changes.
      var range = maximum - minimum;
      if (range < 1.0) {
        minimum -= (1.0 - range) / 2.0;
        range = 1.0;
      }
      var previousX = null;
      var previousY = null;
      for (var i = 0; i < samples.size(); i += 1) {
        if (samples[i] == null) {
          previousX = null;
          previousY = null;
          continue;
        }
        var pointX = x + (i * width / (samples.size() - 1)).toNumber();
        var pointY = y + height - 2 - ((samples[i] - minimum) / range * (height - 4)).toNumber();
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        // One-pixel checkerboard provides a 50% fill on monochrome displays.
        var startX = previousX != null ? previousX : pointX;
        for (var fillX = startX; fillX <= pointX; fillX += 1) {
          var topY = pointY;
          if (previousX != null && pointX > previousX) {
            topY = (previousY + (pointY - previousY) *
              (fillX - previousX) / (pointX - previousX).toFloat()).toNumber();
          }
          var firstY = topY + 1;
          if ((fillX + firstY + patternOffset) % 2 != 0) {
            firstY += 1;
          }
          for (var fillY = firstY; fillY < y + height; fillY += 2) {
            dc.drawPoint(fillX, fillY);
          }
        }
        if (previousX != null) {
          dc.drawLine(previousX, previousY, pointX, pointY);
        } else {
          dc.drawPoint(pointX, pointY);
        }
        previousX = pointX;
        previousY = pointY;
      }
    }
  }

  public function drawRainProbability(dc, textColor, value) as Void {
    var x = (_width * 0.22).toNumber();
    var y = (_height * 0.66).toNumber();

    dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
    // A pointed top and rounded base form a compact droplet icon.
    dc.fillPolygon([[x, y], [x - 5, y + 9], [x + 5, y + 9]]);
    dc.fillCircle(x, y + 9, 5);
    dc.drawText(
      x,
      y + 14,
      Gfx.FONT_SYSTEM_XTINY,
      value,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }

  private function drawMetricRow(dc, textColor, y, icon, value) as Void {
    dc.setColor(textColor, Gfx.COLOR_BLACK);
    dc.drawText(
      _width * 0.5 - 10,
      y,
      _iconsFont,
      icon,
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      _width * 0.5 + 10,
      y,
      Gfx.FONT_SYSTEM_XTINY,
      value,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }

  private function drawBoxedText(dc, text, x, y, width, height) as Void {
    dc.drawRectangle(x, y, width, height);
    dc.drawText(
      x + width / 2,
      y + DATE_VERTICAL_PADDING,
      _monospaceFont,
      text,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }
}
