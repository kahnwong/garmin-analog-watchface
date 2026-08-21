//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.WatchUi as Ui;

//! This implements an ElegantAna watch face
//! Original design by Austen Harbour
class ElegantAnaView extends WatchUi.WatchFace {
  private var _offscreenBuffer as BufferedBitmap?;
  private var _hashMarksBuffer as BufferedBitmap?;
  private var _screenShape;
  private var _data;
  private var _dialRenderer;
  private var _widgetRenderer;

  private var _backgroundColor = Gfx.COLOR_BLACK;
  private var _width;
  private var _height;
  private var _minScreen;
  private var _maxScreen;
  private var _centerX;
  private var _centerY;
  private var _circleX;
  private var _circleY;
  private var _circleRadius;
  private var _hashMarks = new [12];
  private var _iconsFont;
  private var _monospaceFont;
  private var _pokemonFont;
  private var _materialDesignFont;

  public function initialize() {
    WatchFace.initialize();

    _screenShape = System.getDeviceSettings().screenShape;
    _data = new WatchFaceData();
    _iconsFont = Ui.loadResource(Rez.Fonts.IconsFont);
    _monospaceFont = Ui.loadResource(Rez.Fonts.MonospaceFont);
    _pokemonFont = Ui.loadResource(Rez.Fonts.PokemonFont);
    _materialDesignFont = Ui.loadResource(Rez.Fonts.MaterialDesignFont);
  }

  public function onLayout(dc as Dc) as Void {
    var bufferOptions = {
      :width => dc.getWidth(),
      :height => dc.getHeight(),
    };

    if (Graphics has :createBufferedBitmap) {
      _offscreenBuffer =
        Graphics.createBufferedBitmap(bufferOptions).get() as BufferedBitmap;
      _hashMarksBuffer =
        Graphics.createBufferedBitmap(bufferOptions).get() as BufferedBitmap;
    } else if (Graphics has :BufferedBitmap) {
      _offscreenBuffer = new Graphics.BufferedBitmap(bufferOptions);
      _hashMarksBuffer = new Graphics.BufferedBitmap(bufferOptions);
    } else {
      _offscreenBuffer = null;
      _hashMarksBuffer = null;
    }

    _width = dc.getWidth();
    if (_width < 166) {
      _width -= 8;
    }
    _height = dc.getHeight();
    _minScreen = _width < _height ? _width : _height;
    _maxScreen = _width < _height ? _height : _width;

    var hashMarkFactor = -1.08;
    if (_width < 166) {
      hashMarkFactor = -1.1;
    } else if (_width > 176) {
      hashMarkFactor = -0.95;
    }

    _centerX = _width / 2;
    _centerY = _height / 2;
    _circleX = 145.5;
    _circleY = 32;
    _circleRadius = 32;
    if (WatchUi has :getSubscreen) {
      var subscreen = WatchUi.getSubscreen();
      _circleRadius = subscreen.height / 2 + 1;
      _circleX = subscreen.x + _circleRadius + 0.5;
      _circleY = subscreen.y + _circleRadius;
    } else {
      _circleRadius = _height / 8.0;
      _circleX = _centerX + _centerX / 2 + 1;
      _circleY = _centerY - _centerY / 2 + 1;
    }

    for (var i = 0; i < 12; i += 1) {
      _hashMarks[i] = [
        (i / 12.0) * Math.PI * 2,
        (hashMarkFactor * _minScreen) / 2,
      ];
    }

    setLayout(Rez.Layouts.WatchFace(dc));
    _dialRenderer = new DialRenderer(
      _width,
      _height,
      _maxScreen,
      _centerX,
      _centerY,
      _screenShape,
      _hashMarks
    );
    _widgetRenderer = new WidgetRenderer(
      _width,
      _height,
      _circleX,
      _circleY,
      _circleRadius,
      _iconsFont,
      _monospaceFont,
      _pokemonFont,
      _materialDesignFont
    );
    cacheHashMarks();
  }

  public function onUpdate(dc as Dc) as Void {
    var clockTime = System.getClockTime();
    var nowValue = Time.now().value();
    var targetDc = null;
    var squeeze = _width <= 176;

    dc.clearClip();
    if (null != _offscreenBuffer) {
      targetDc = _offscreenBuffer.getDc();
    } else {
      targetDc = dc;
    }

    targetDc.clearClip();
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    targetDc.clear();
    if (null != _hashMarksBuffer) {
      targetDc.drawBitmap(0, 0, _hashMarksBuffer);
    } else {
      _dialRenderer.drawHashMarks(targetDc, squeeze);
    }
    targetDc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

    _data.refresh(nowValue);
    _widgetRenderer.drawHeartRate(
      targetDc,
      Gfx.COLOR_WHITE,
      _data.getHeartRate()
    );
    _widgetRenderer.drawNextEvent(
      targetDc,
      Gfx.COLOR_WHITE,
      _data.getNextEventString()
    );
    _widgetRenderer.drawBodyBattery(
      targetDc,
      _data.getBodyBatteryIcon(),
      _data.getBodyBatteryValue()
    );
    _widgetRenderer.drawDate(
      targetDc,
      _data.getDateDayOfWeek(),
      _data.getDateDayOfMonth()
    );
    _widgetRenderer.drawRecoveryTime(
      targetDc,
      Gfx.COLOR_WHITE,
      _data.getRecoveryTime()
    );
    _dialRenderer.drawHands(
      targetDc,
      clockTime.hour,
      clockTime.min,
      _data.getAlternateTime(),
      _data.getNextEventTime()
    );
    _dialRenderer.drawCenter(targetDc, _backgroundColor);
    _dialRenderer.drawDawnDusk(
      targetDc,
      _data.getDawnDuskInfo(),
      squeeze
    );

    presentFrame(dc);
  }

  private function presentFrame(dc as Dc) as Void {
    if (null != _offscreenBuffer) {
      dc.drawBitmap(0, 0, _offscreenBuffer);
    }
  }

  private function cacheHashMarks() as Void {
    if (null == _hashMarksBuffer) {
      return;
    }

    var hashDc = _hashMarksBuffer.getDc();
    hashDc.clearClip();
    hashDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    hashDc.clear();
    hashDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    _dialRenderer.drawHashMarks(hashDc, _width <= 176);
    hashDc.clearClip();
  }
}

class ElegantAnaDelegate extends WatchUi.WatchFaceDelegate {
  public function initialize(view as ElegantAnaView) {
    WatchFaceDelegate.initialize();
  }

  public function onPowerBudgetExceeded(
    powerInfo as WatchFacePowerInfo
  ) as Void {
    System.println("Average execution time: " + powerInfo.executionTimeAverage);
    System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
  }

  public function onKey(keyEvent) {
    return true;
  }
}
