//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.ActivityMonitor;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
using Toybox.Activity as Acty;
using Toybox.ActivityMonitor as Act;
using Toybox.Application as App;
using Toybox.Application;
using Toybox.Complications;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

//! This implements an ElegantAna watch face
//! Original design by Austen Harbour
class ElegantAnaView extends WatchUi.WatchFace {
  private var _font as FontResource?;
  private var _isAwake as Boolean?;
  private var _screenShape as ScreenShape;
  private var _dndIcon as BitmapResource?;
  private var _offscreenBuffer as BufferedBitmap?;
  private var _hashMarksBuffer as BufferedBitmap?;
  private var _screenCenterPoint as Array<Number>?;
  private var _fullScreenRefresh as Boolean;
  private var _hashMarksDrawn as Boolean;
  private var _partialUpdatesAllowed as Boolean;

  var background_color = Gfx.COLOR_BLACK;
  var sec_color = Gfx.COLOR_WHITE;
  var width_screen, height_screen, min_screen, max_screen;
  var sec_length, sec_width, sec_base, sec_type;
  var centerY_seconds,
    centerX_seconds,
    centerX_main,
    centerY_main,
    centerX_circle,
    centerY_circle,
    radius_circle;

  var hashMarksArray = new [24];

  var dateFont;
  var timeFont;
  var dateTextHeight;
  var timeTextHeight;

  var batt_width_rect = 12;
  var batt_height_rect = 6;
  var batt_width_rect_small = 2;
  var batt_height_rect_small = 4;
  var batt_x, batt_y, batt_x_small, batt_y_small;

  var dmd_w4;
  var dmd_yy, dmd_x;
  var dmd_w;
  var dmd_h;

  var activities_background_color = Graphics.COLOR_BLACK;
  var lowBatteryColor = 0xff3333;
  var activities_primaryColor;
  var activities_gap = 1;

  var stepGoal;
  var steps;
  var activeMinutesWeek, activeMinutesDay;
  var activeMinutesWeekGoal, activeMinutesDayGoal;
  var moveBarLevel, moveExpired;
  var info, si;
  var hasSubscreen = true;
  var iconsFont;
  var iconsFontLarge;
  var monospaceFont;

  //! Initialize variables for this view
  public function initialize() {
    WatchFace.initialize();
    _screenShape = System.getDeviceSettings().screenShape;
    _fullScreenRefresh = true;
    _hashMarksDrawn = false;
    _partialUpdatesAllowed = WatchUi.WatchFace has :onPartialUpdate;
    _isAwake = true;
    si = new ElegantAna_SunInfo();
    readStorageValues();

    // ref: https://github.com/blotspot/garmin-watchface-protomolecule/blob/414e362605f3c7634a0e21617d1b61220d085877/source/datafield/DataFieldIcons.mc#L110
    iconsFont = Ui.loadResource(Rez.Fonts.IconsFont);
    iconsFontLarge = Ui.loadResource(Rez.Fonts.IconsFontLarge);
    monospaceFont = Ui.loadResource(Rez.Fonts.MonospaceFont);
  }

  public function onHide() as Void {}

  public function onShow() as Void {
    update_ran = false;
    $.Settings_ran = true;
  }

  public function onLayout(dc as Dc) as Void {
    var offscreenBufferOptions = {
      :width => dc.getWidth(),
      :height => dc.getHeight(),
    };
    var hashMarksBufferOptions = {
      :width => dc.getWidth(),
      :height => dc.getHeight(),
    };

    if (Graphics has :createBufferedBitmap) {
      _offscreenBuffer =
        Graphics.createBufferedBitmap(offscreenBufferOptions).get() as
        BufferedBitmap;

      _hashMarksBuffer =
        Graphics.createBufferedBitmap(hashMarksBufferOptions).get() as
        BufferedBitmap;
    } else if (Graphics has :BufferedBitmap) {
      _offscreenBuffer = new Graphics.BufferedBitmap(offscreenBufferOptions);
      _hashMarksBuffer = new Graphics.BufferedBitmap(hashMarksBufferOptions);
    } else {
      _offscreenBuffer = null;
      _hashMarksBuffer = null;
    }

    _screenCenterPoint = [dc.getWidth() / 2, dc.getHeight() / 2];
    width_screen = dc.getWidth();
    if (width_screen < 166) {
      width_screen -= 8;
    }
    height_screen = dc.getHeight();
    min_screen = width_screen < height_screen ? width_screen : height_screen;
    max_screen = width_screen < height_screen ? height_screen : width_screen;
    var hm_factor = -1.08;
    if (width_screen < 166) {
      hm_factor = -1.1;
    }

    if (width_screen > 176) {
      hm_factor = -0.95;
    }

    //center of dial for second hand
    centerX_seconds = width_screen / 2;
    centerY_seconds = height_screen / 2;
    centerX_main = width_screen / 2;
    centerY_main = height_screen / 2;
    centerX_circle = 145.5; //??
    centerY_circle = 32; //??
    radius_circle = 32;
    if (WatchUi has :getSubscreen) {
      var ss = WatchUi.getSubscreen();
      hasSubscreen = true;
      radius_circle = ss.height / 2 + 1;
      centerX_circle = ss.x + radius_circle + 0.5;
      centerY_circle = ss.y + radius_circle;
    } else {
      hasSubscreen = false;
      radius_circle = height_screen / 8.0;

      centerX_circle = centerX_main + centerX_main / 2 + 1;
      centerY_circle = centerY_main - centerY_main / 2 + 1;
    }

    //get hash marks position
    for (var i = 0; i < 12; i += 1) {
      hashMarksArray[i] = new [2];
      //if(i != 0 && i != 6 && i != 12 && i != 18)
      {
        hashMarksArray[i][0] = (i / 12.0) * Math.PI * 2;
        hashMarksArray[i][1] = (hm_factor * min_screen) / 2;
      }
    }

    dateFont = Graphics.FONT_TINY;
    timeFont = Graphics.FONT_LARGE;
    dateTextHeight = dc.getFontHeight(dateFont);
    timeTextHeight = dc.getFontHeight(timeFont);

    setLayout(Rez.Layouts.WatchFace(dc));
  }

  private function generateHandCoordinates(
    centerPoint as Array<Number>,
    angle as Float,
    handLength as Number,
    tailLength as Number,
    width as Number
  ) as Array<[Numeric, Numeric]> {
    // Map out the coordinates of the watch hand
    var coords = [
      [-(width / 2), tailLength],
      [-(width / 2), -handLength],
      [width / 2, -handLength],
      [width / 2, tailLength],
    ];
    var result = new Array<[Numeric, Numeric]>[4];
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);

    // Transform the coordinates
    for (var i = 0; i < 4; i++) {
      var x = coords[i][0] * cos - coords[i][1] * sin + 0.5;
      var y = coords[i][0] * sin + coords[i][1] * cos + 0.5;

      result[i] = [centerPoint[0] + x, centerPoint[1] + y];
    }

    return result;
  }

  var update_ran = false;
  var dawnDusk_ran = false;
  var dawnDusk_info = null;
  var dawnDusk_info24 = null;
  var nextEventHand_ran = false;
  var eventTime = null;
  var recoveryTimeLeft_ran = false;
  var recoveryTime = null;

  public function onUpdate(dc as Dc) as Void {
    var clockTime = System.getClockTime();
    var targetDc = null;

    update_ran = true;

    _fullScreenRefresh = true;

    var squeeze = true;
    if (width_screen > 176) {
      squeeze = false;
    }

    dc.clearClip();

    if (null != _offscreenBuffer) {
      targetDc = _offscreenBuffer.getDc();
    } else {
      targetDc = dc;
    }

    if (null != _hashMarksBuffer) {
      targetDc.drawBitmap(0, 0, _hashMarksBuffer);
    }

    // entrypoint
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    targetDc.clear();
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    targetDc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

    // drawBodyBattery(targetDc, Gfx.COLOR_WHITE);
    drawHeartRate(targetDc, Gfx.COLOR_WHITE);
    drawNextEvent(targetDc, Gfx.COLOR_WHITE);
    // drawStressScore(targetDc, Gfx.COLOR_WHITE);
    // drawDateInset(targetDc, Gfx.COLOR_WHITE, true);
    drawBodyBatteryInset(targetDc);
    drawDateMain(targetDc);

    // recovery time
    if (!recoveryTimeLeft_ran || clockTime.min % 10 == 0) {
      recoveryTimeLeft_ran = true;
      recoveryTime = getRecoveryTime();
    }
    drawRecoveryTime(targetDc, Gfx.COLOR_WHITE);

    var drawHashes = true;
    var drawHours = false;
    var avoidCircle = true;
    drawHashMarks(targetDc, drawHashes, drawHours, avoidCircle, squeeze);
    drawHands(
      targetDc,
      clockTime.hour,
      clockTime.min,
      clockTime.sec,
      Gfx.COLOR_WHITE,
      Gfx.COLOR_WHITE,
      Gfx.COLOR_WHITE
    );

    targetDc.setPenWidth(1);
    targetDc.setClip(0, height_screen / 2 - 20, width_screen, 40);

    // Draw the inner circle (at center of the 3 hands)
    targetDc.setColor(Gfx.COLOR_WHITE, background_color);
    targetDc.fillCircle(width_screen / 2, height_screen / 2, 6);
    targetDc.setColor(background_color, background_color);
    targetDc.drawCircle(width_screen / 2, height_screen / 2, 6);

    // SUNSET/SUNRISE MARKERS
    if (!dawnDusk_ran || clockTime.min % 10 == 0) {
      dawnDusk_ran = true;
      dawnDusk_info = si.getNextDawnDusk([SUNRISE, SUNSET]); // in simulator sunrise/sunset and dawn/dusk would display the same value
    }

    if (dawnDusk_info != null) {
      for (var i = 0; i < dawnDusk_info.size(); i++) {
        var sh = 7; //filled circle
        if (dawnDusk_info[i][0].equals("Dusk")) {
          sh = 9;
        }

        var radius = 2;

        var ln = width_screen * 0.48;
        var ang_rad_clock = mod(dawnDusk_info[i][1], Math.PI * 2);

        var options = {
          :dc => targetDc,
          :angle => ang_rad_clock,
          :length => ln,
          :width => 8,
          :overheadLine => radius,
          :drawCircleOnTop => false,
          :shape => sh,
          :squeezeX => squeeze,
          :squeezeY => squeeze,
          :centerX => centerX_main,
          :centerY => centerY_main,
        };
        drawHand(options);
      }
    }

    drawBackground(dc);
    _fullScreenRefresh = false;
  }

  // ------------- functions -------------
  private function getBoundingBox(
    points as Array<[Numeric, Numeric]>
  ) as Array<[Numeric, Numeric]> {
    var min = [9999, 9999];
    var max = [0, 0];

    for (var i = 0; i < points.size(); ++i) {
      if (points[i][0] < min[0]) {
        min[0] = points[i][0];
      }

      if (points[i][1] < min[1]) {
        min[1] = points[i][1];
      }

      if (points[i][0] > max[0]) {
        max[0] = points[i][0];
      }

      if (points[i][1] > max[1]) {
        max[1] = points[i][1];
      }
    }
    min[0] -= 3;
    min[1] -= 3;
    max[0] += 3;
    max[1] += 3;

    return [min, max];
  }

  private function drawBackground(dc as Dc) as Void {
    if (null != _offscreenBuffer) {
      dc.drawBitmap(0, 0, _offscreenBuffer);
    }
  }

  public function turnPartialUpdatesOff() as Void {
    _partialUpdatesAllowed = false;
  }

  function drawHand(options) {
    var dc = options[:dc];
    var angle = options[:angle];
    var length = options[:length];
    var width = options[:width];
    var overheadLine = options[:overheadLine];
    var drawCircleOnTop = options[:drawCircleOnTop];
    var shape = options[:shape];
    var squeezeX = options[:squeezeX];
    var squeezeY = options[:squeezeY];
    var centerX = options[:centerX];
    var centerY = options[:centerY];

    // Map out the coordinates of the watch hand
    var count = 4;
    var coords = new [count];

    if (shape == 1) {
      coords = [
        [0, 0 + overheadLine],
        [0, -length],
      ];
      count = 2;
    } else if (shape == 2 || shape == 5 || shape == 6) {
      //TRIANGLE/pointer

      var mult = 1;
      coords = [
        [-(width / 2) * mult, 0 + overheadLine],
        [0, -length],
        [(width / 2) * mult, 0 + overheadLine],
      ];
      count = 3;
    } else if (shape >= 7 && shape <= 9) {
      coords = [[0, -length]];
      count = 1;
    } else {
      coords = [
        [-(width / 2), 0 + overheadLine],
        [-(width / 2), -length],
        [width / 2, -length],
        [width / 2, 0 + overheadLine],
      ];
      count = 4;
    }

    var result = new [count];
    //var centerX = width_screen / 2;
    //var centerY = height_screen / 2;
    //little hand-entry of angle=PI, to make it exact
    var cos = -1;
    var sin = 0;
    //System.println("angle: " + angle);
    if ((Math.PI - angle).abs() > 0.001) {
      cos = Math.cos(angle);
      sin = Math.sin(angle);
    }

    var minY = height_screen;
    var maxY = 0;
    //var minX = width_screen;
    //var maxX = 0;

    // Transform the coordinates
    for (var i = 0; i < count; i += 1) {
      var x = coords[i][0] * cos - coords[i][1] * sin;
      var y = coords[i][0] * sin + coords[i][1] * cos;

      var X = centerX + x;
      var Y = centerY + y;
      var squeezeX_amt = 3;
      var squeezeY_amt = 2;
      //for circles we make sure the whole circle is in frame
      if (shape >= 7 && shape <= 9) {
        squeezeX_amt = 5 + overheadLine;
        squeezeY_amt = 4 + overheadLine;
      }

      if (squeezeX) {
        if (i == 0 || i == count - 1) {
          if (X > width_screen - squeezeX_amt) {
            X = width_screen - squeezeX_amt;
            if (Y < height_screen / 2 - 4) {
              Y += 1;
            } else if (Y > height_screen / 2 + 4) {
              Y -= 1;
            }
          }
          if (X < squeezeX_amt) {
            X = squeezeX_amt;
            if (Y < height_screen / 2 - 4) {
              Y += 1;
            } else if (Y > height_screen / 2 + 4) {
              Y -= 1;
            }
          }
        } else {
          //if ( X>width_screen ) {X = width_screen;}
          //if (X<1) {X=1;}
        }
      }
      if (squeezeY) {
        if (i == 0 || i == count - 1) {
          if (Y > height_screen - squeezeY_amt) {
            Y = height_screen - squeezeY_amt;
            if (X < width_screen / 2 - 4) {
              X += 1;
            } else if (X > width_screen / 2 + 4) {
              X -= 1;
            }
          }
          if (Y < squeezeY_amt) {
            Y = squeezeY_amt;
            if (X < width_screen / 2 - 4) {
              X += 1;
            } else if (X > width_screen / 2 - 4) {
              X -= 1;
            }
          }
        } else {
          //if ( Y>height_screen ) {Y = height_screen;}
          //if (Y<1) {Y=1;}
        }
      }

      result[i] = [X, Y];
      if (Y < minY) {
        minY = Y;
      }
      if (Y > maxY) {
        maxY = Y;
      }
      //if (X<minX) {minX = X;}
      //if (X>maxX) {maxX = X;}

      /*
            if(drawCircleOnTop)
            {
                if(i == 0)
                {
                    var xCircle = ((coords[i][0]+(width/2)) * cos) - ((coords[i][1] + 1) * sin);
                    var yCircle = ((coords[i][0]+(width/2)) * sin) + ((coords[i][1] + 1) * cos);
                    dc.fillCircle(centerX + xCircle, centerY + yCircle, (width/2));
                }
                else if(i == 1)
                {
                    var xCircle = ((coords[i][0]+(width/2)) * cos) - ((coords[i][1] + 1) * sin);
                    var yCircle = ((coords[i][0]+(width/2)) * sin) + ((coords[i][1] + 1) * cos);
                    dc.fillCircle(centerX + xCircle, centerY + yCircle, (width/2));
                }

            }
            */
    }
    //        dc.setClip(minX  -4 ,minY -4,maxX-minX + 8,maxY-minY + 8);

    if (shape >= 7 && shape <= 9) {
      dc.setClip(
        0,
        minY - overheadLine - 2,
        width_screen,
        2 * overheadLine + 4
      );
    } else {
      dc.setClip(0, minY - 3, width_screen, maxY - minY + 6); //don't need clip on X axis as it doesnt affect graphics/display energy usage.
    }
    //System.println("polygon:" + result);
    // Draw the polygon
    /*
        if (shape== 1) {
            dc.drawLine(result[0][0], result[0][1], result[1][0], result[1][1]);
        }
        else if (shape == 2 ){
            //dc.drawLine(result[0][0], result[0][1], result[1][0], result[1][1]);
            //if (shape>1) { dc.shape(result[3][0], result[3][1], result[1][0], result[1][1]);}
            //dc.fillPolygon([[result[0][0], result[0][1]],[result[1][0], result[1][1]],[result[2][0], result[2][1]]]);

            dc.fillPolygon(result);

        } else {
             dc.fillPolygon(result);
        }*/
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    if (shape == 1) {
      dc.drawLine(result[0][0], result[0][1], result[1][0], result[1][1]);
    } else if (shape == 3 || shape == 5) {
      //outline poly
      drawPolygon(dc, result, false);
    } else if (shape == 4 || shape == 6) {
      //black/blank outline poly
      drawPolygon(dc, result, true);
    } else if (shape == 7) {
      //filled white circle
      dc.fillCircle(result[0][0], result[0][1], overheadLine);
    } else if (shape == 8) {
      dc.drawCircle(result[0][0], result[0][1], overheadLine); //white circle non-filled/non-blanked
    } else if (shape == 9) {
      //white circle blanked
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillCircle(result[0][0], result[0][1], overheadLine);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(result[0][0], result[0][1], overheadLine);
    } else {
      //regular filled poly
      dc.fillPolygon(result);
    }

    //dc.fillPolygon(result);
    return result;
  }

  //! Draw the watch hand
  //! @param dc Device Context to Draw
  //! @param angle Angle to draw the watch hand
  //! @param length Length of the watch hand
  //! @param width Width of the watch hand
  //! @param draw a circle @ the end
  //! @param shape:
  // 0=regular filled rectangle
  // 1=thin line
  // 2=triangle/point
  // 3=rectangle outline
  // 4=blanked rectangle outline
  // 5=triangle outline
  // 6=blanked triangle outline

  function drawHandplain(dc, angle, length, width, overheadLine, shape) {
    // Map out the coordinates of the watch hand
    var count = 7;
    var coords = new [7];
    //var centerX_seconds = width_screen / 2;
    //var centerY_seconds = height_screen / 2;

    if (shape == 1) {
      //LINE

      coords = [
        [0, overheadLine],
        [0, -length],
      ];
      count = 2;
    } else if (shape == 2 || shape == 5 || shape == 6) {
      //TRIANGLE/pointer

      coords = [
        [-(width / 2), overheadLine],
        [0, -length],
        [width / 2, overheadLine],
      ];
      count = 3;
    } else {
      //RECTANGLE

      coords = [
        [-(width / 2), overheadLine],
        [-(width / 2), -length],
        [width / 2, -length],
        [width / 2, overheadLine],
      ];
      count = 4;
    }

    var result = new [count];

    //little hand-entry of angle=PI, to make it exact
    var cos = -1;
    var sin = 0;
    //System.println("angle: " + angle);
    if ((Math.PI - angle).abs() > 0.001) {
      cos = Math.cos(angle);
      sin = Math.sin(angle);
    }

    var minY = height_screen;
    var maxY = 0;
    //var minX = width_screen;
    //var maxX = 0;

    // Transform the coordinates
    for (var i = 0; i < count; i += 1) {
      var X = coords[i][0] * cos - coords[i][1] * sin + centerX_seconds;
      var Y = coords[i][0] * sin + coords[i][1] * cos + centerY_seconds;

      result[i] = [X, Y];
      if (Y < minY) {
        minY = Y;
      }
      if (Y > maxY) {
        maxY = Y;
      }
      //if (i<count-3 && Y<minY) {minY = Y;}
      //if (i<count-3 && Y>maxY) {maxY = Y;}
      //if (X<minX) {minX = X;}
      //if (X>maxX) {maxX = X;}
    }
    //dc.setClip(minX  - 1.5 ,minY -1.5,maxX-minX + 3,maxY-minY + 3);
    dc.setClip(0, minY - 1.5, width_screen, maxY - minY + 3);
    //System.println ("result: " + result);
    //System.println ("clip  :" + (minX  -1) + ", " + (minY -1) + ", " + (maxX-minX + 2) + ", " + (maxY-minY + 2));

    if (shape == 1) {
      dc.drawLine(result[0][0], result[0][1], result[1][0], result[1][1]);
    } else if (shape == 3 || shape == 5) {
      //outline poly
      drawPolygon(dc, result, false);
    } else if (shape == 4 || shape == 6) {
      //black/blank outline poly
      drawPolygon(dc, result, true);
    } else {
      //regular filled poly
      dc.fillPolygon(result);
    }
  }

  function drawPolygon(dc, points, blank) {
    if (blank) {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillPolygon(points);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    //System.println("points: " + points);
    for (var i = 0; i < points.size(); i += 1) {
      var p2 = (i + 1) % points.size();
      dc.drawLine(points[i][0], points[i][1], points[p2][0], points[p2][1]);
    }
  }

  function drawHands(
    dc,
    clock_hour,
    clock_min,
    clock_sec,
    hour_color,
    min_color,
    sec_color
  ) {
    var hour, min;

    // Draw the hour. Convert it to minutes and
    // compute the angle.
    hour = (clock_hour % 12) * 60 + clock_min;
    hour = hour / (12 * 60.0);
    hour = hour * Math.PI * 2;
    dc.setColor(hour_color, Gfx.COLOR_TRANSPARENT);
    var hr_width = 5;
    var min_width = 4;
    if (width_screen > 176) {
      hr_width = (5 / 176.0) * max_screen;
      min_width = (4 / 176.0) * max_screen;
    }

    var options = {
      :dc => dc,
      :angle => hour,
      :length => width_screen * 0.41 * 0.6,
      :width => hr_width,
      :overheadLine => 15,
      :drawCircleOnTop => false,
      :shape => 0,
      :squeezeX => false,
      :squeezeY => false,
      :centerX => centerX_main,
      :centerY => centerY_main,
    };
    drawHand(options);

    // Karn Wong: alternate timezone hand
    var clockTimeAlternate = getAlternateTimezone();

    var hourAlt = (clockTimeAlternate.hour % 12) * 60 + clock_min;
    hourAlt = hourAlt / (12 * 60.0);
    hourAlt = hourAlt * Math.PI * 2;

    var hourAltShape; // 5 = white border/black fill; 2 = white fill
    if (clockTimeAlternate.hour >= 6 && clockTimeAlternate.hour <= 18) {
      hourAltShape = 2;
    } else {
      hourAltShape = 5;
    }

    var optionsAlternate = {
      :dc => dc,
      :angle => hourAlt,
      :length => width_screen * 0.41 * 0.6,
      :width => hr_width,
      :overheadLine => 15,
      :drawCircleOnTop => false,
      :shape => hourAltShape,
      :squeezeX => false,
      :squeezeY => false,
      :centerX => centerX_main,
      :centerY => centerY_main,
    };
    drawHand(optionsAlternate);

    // next event hand
    if (!nextEventHand_ran || clock_min % 10 == 0) {
      nextEventHand_ran = true;
      eventTime = getNextEventTime();
    }

    if (eventTime != null) {
      var hourMeeting = (eventTime.hour % 12) * 60 + eventTime.min;
      hourMeeting = hourMeeting / (12 * 60.0);
      hourMeeting = hourMeeting * Math.PI * 2;

      var optionsEvent = {
        :dc => dc,
        :angle => hourMeeting,
        :length => width_screen * 0.41 * 0.6,
        :width => hr_width,
        :overheadLine => 15,
        :drawCircleOnTop => false,
        :shape => 1, // has to be different from normal time hands
        :squeezeX => false,
        :squeezeY => false,
        :centerX => centerX_main,
        :centerY => centerY_main,
      };
      drawHand(optionsEvent);
    }

    // Draw the minute
    min = (clock_min / 60.0) * Math.PI * 2;
    dc.setColor(min_color, Gfx.COLOR_TRANSPARENT);

    options = {
      :dc => dc,
      :angle => min,
      :length => width_screen * 0.41,
      :width => min_width,
      :overheadLine => 15,
      :drawCircleOnTop => false,
      :shape => 0,
      :squeezeX => false,
      :squeezeY => false,
      :centerX => centerX_main,
      :centerY => centerY_main,
    };
    //drawHand(dc, min, width_screen*.41, 4, 15, false, 0,false, false);
    drawHand(options);
  }

  function drawHashMarks(dc, drawHashes, drawHours, avoidCircle, squeeze) {
    if (drawHours) {
      // Draw the numbers
      var font = Gfx.FONT_LARGE;
      var adj1 = -1;
      var adj2 = 1;
      if (width_screen < 166) {
        adj1 = -3;
        adj2 = 0;
      }
      var adj12 = 1;
      var adj6 = -32;
      if (width_screen > 176) {
        var fact = width_screen / 25;
        adj12 = fact;
        adj6 = -dc.getFontHeight(font) - fact;
        adj1 = -fact;
        adj2 = fact;
      }

      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
      dc.drawText(width_screen / 2, adj12, font, "12", Gfx.TEXT_JUSTIFY_CENTER);
      dc.drawText(
        width_screen + adj1,
        height_screen / 2,
        font,
        "3 ",
        Gfx.TEXT_JUSTIFY_RIGHT + Gfx.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        width_screen / 2,
        height_screen + adj6,
        font,
        "6",
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        adj2,
        height_screen / 2,
        font,
        " 9",
        Gfx.TEXT_JUSTIFY_LEFT + Gfx.TEXT_JUSTIFY_VCENTER
      );
    }

    if (drawHashes) {
      var devset = System.getDeviceSettings();
      for (var i = 0; i < 12; i += 1) {
        if (
          (!drawHours || (i != 0 && i != 3 && i != 6 && i != 9)) &&
          (!avoidCircle || (i != 1 && i != 2))
        ) {
          if (
            devset.screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON &&
            i % 3 == 0
          ) {
            continue;
          } //skip the hour hashes 3, 6, 9, 12 for Instinct ; looks better that way

          var adder = 0;
          var width_adder = 0;
          if (width_screen < 166) {
            if (i == 1) {
              adder = 3;
              width_adder = 4;
            }
            if (i == 2) {
              adder = -7;
            }
          } else if (width_screen <= 176) {
            if (i == 1) {
              adder = -4;
              width_adder = 0;
            }
            if (i == 2) {
              adder = -3;
            }
          }

          if (i % 3 == 0) {
            adder = 15;
          }
          var options = {
            :dc => dc,
            :angle => hashMarksArray[i][0],
            :length => 88, // max_screen * 0.55,
            :width => 3.5 + width_adder,
            :overheadLine => hashMarksArray[i][1] + adder,
            :drawCircleOnTop => false,
            :shape => 0,
            :squeezeX => squeeze,
            :squeezeY => squeeze,
            :centerX => centerX_main,
            :centerY => centerY_main,
          };

          drawHand(options);
        }
      }
    }
  }

  function getBodyBatteryIterator() {
    // Check device for SensorHistory compatibility
    if (
      Toybox has :SensorHistory &&
      Toybox.SensorHistory has :getBodyBatteryHistory
    ) {
      // Set up the method with parameters
      return Toybox.SensorHistory.getBodyBatteryHistory({ :period => 1 });
    }
    return null;
  }
  function drawBodyBattery(dc, text_color) {
    var bbValue = "--";

    try {
      var bbIterator = getBodyBatteryIterator();
      if (bbIterator != null) {
        var sample = bbIterator.next();
        if (sample != null && sample.data != null) {
          bbValue = sample.data.toNumber().toString();
        }
      }
    } catch (ex) {
      // Handle any exceptions gracefully
      bbValue = "--";
    }
    dc.setColor(text_color, Gfx.COLOR_BLACK);

    dc.drawText(
      width_screen * 0.5 - 40,
      height_screen * 0.5 + 25,
      Gfx.FONT_SYSTEM_XTINY,
      "BB: " + bbValue,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }
  function drawBodyBatteryInset(dc) {
    var bbIcon = "o";

    // get value
    var bbValue = "--";
    try {
      var bbIterator = getBodyBatteryIterator();
      if (bbIterator != null) {
        var sample = bbIterator.next();
        if (sample != null && sample.data != null) {
          var bbIntValue = sample.data.toNumber();
          bbValue = bbIntValue.toString();

          if (bbIntValue <= 5) {
            bbIcon = "z";
          } else if (bbIntValue < 30) {
            bbIcon = "y";
          }
        }
      }
    } catch (ex) {
      // Handle any exceptions gracefully
      bbValue = "--";
    }

    // fill circle
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(centerX_circle, centerY_circle, radius_circle + 2);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

    // draw data
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

    var f1 = Gfx.FONT_GLANCE_NUMBER;
    // var f2 = Gfx.FONT_SYSTEM_TINY;

    if (width_screen <= 176) {
      var ws = 0.82;
      var hs1 = 0.02;
      var hs2 = 0.16;

      dc.drawText(
        width_screen * ws,
        height_screen * hs1,
        iconsFontLarge,
        bbIcon,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        width_screen * ws,
        height_screen * hs2,
        f1,
        bbValue,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }

  private function getAlternateTimezone() {
    var utcMoment = Time.now();

    // Determine if DST is active (simplified check)
    var utcInfo = Gregorian.utcInfo(utcMoment, Time.FORMAT_SHORT);
    var isDST =
      (utcInfo.month > 3 && utcInfo.month < 11) ||
      (utcInfo.month == 3 && utcInfo.day >= 8) ||
      (utcInfo.month == 11 && utcInfo.day < 7);

    // Apply appropriate offset
    var offset = isDST ? -7 * 3600 : -8 * 3600; // PDT or PST
    var californiaMoment = utcMoment.add(new Time.Duration(offset));
    var caTime = Gregorian.utcInfo(californiaMoment, Time.FORMAT_SHORT);

    return caTime;
  }

  private function getHeartRate() {
    var heartRate = null;

    // Check if Activity has currentHeartRate information
    var activityInfo = Acty.getActivityInfo();
    if (activityInfo != null && activityInfo has :currentHeartRate) {
      heartRate = activityInfo.currentHeartRate;
    }

    // If currentHeartRate is null, try to get it from heart rate history
    if (heartRate == null) {
      if (Act has :getHeartRateHistory) {
        var heartRateHistory = Act.getHeartRateHistory(1, true); // Get the most recent sample, excluding future samples
        if (heartRateHistory != null) {
          var heartRateSample = heartRateHistory.next(); // Get the actual sample

          if (
            heartRateSample != null &&
            heartRateSample.heartRate != Act.INVALID_HR_SAMPLE
          ) {
            heartRate = heartRateSample.heartRate;
          }
        }
      }
    }

    // Format the heart rate for display
    if (heartRate != null) {
      return heartRate.toString();
    } else {
      return "--";
    }
  }
  function drawHeartRate(dc, text_color) {
    dc.setColor(text_color, Gfx.COLOR_BLACK);
    dc.drawText(
      // width_screen * 0.5 - 40,
      // height_screen * 0.5 - 35,
      // width_screen * 0.5 + 40,
      // height_screen * 0.5 + 25,
      width_screen * 0.5 - 10, // here
      height_screen * 0.5 + 20, // here
      iconsFont,
      "p",
      Gfx.TEXT_JUSTIFY_CENTER
    );

    dc.drawText(
      width_screen * 0.5 + 10, // here
      height_screen * 0.5 + 20, // here
      Gfx.FONT_SYSTEM_XTINY,
      getHeartRate(),
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }

  function getStressScore() as Lang.Number? {
    var info = ActivityMonitor.getInfo();
    if (info != null) {
      // timeToRecovery is in hours
      var stressScore = info.stressScore;
      return stressScore;
    }
    return null; // Return null if info is not available
  }
  function drawStressScore(dc, text_color) {
    var stressScore = getStressScore();
    var text;
    if (stressScore != null) {
      text = stressScore;
    } else {
      text = "--";
    }

    dc.setColor(text_color, Gfx.COLOR_BLACK);
    dc.drawText(
      width_screen * 0.5 - 10, // here
      height_screen * 0.5 + 30, // here
      iconsFont,
      "x",
      Gfx.TEXT_JUSTIFY_CENTER
    );

    dc.drawText(
      width_screen * 0.5 + 10, // here
      height_screen * 0.5 + 30, // here
      Gfx.FONT_SYSTEM_XTINY,
      text,
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }
  function getRecoveryTime() as Lang.Number? {
    var info = ActivityMonitor.getInfo();
    if (info != null) {
      // timeToRecovery is in hours
      var timeToRecovery = info.timeToRecovery;
      return timeToRecovery;
    }
    return null; // Return null if info is not available
  }
  function drawRecoveryTime(dc, text_color) {
    if (recoveryTime != null) {
      if (recoveryTime > 1) {
        dc.setColor(text_color, Gfx.COLOR_BLACK);
        dc.drawText(
          width_screen * 0.5 - 10, // here
          height_screen * 0.5 + 40, // here
          iconsFont,
          "t",
          Gfx.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
          width_screen * 0.5 + 10, // here
          height_screen * 0.5 + 40, // here
          Gfx.FONT_SYSTEM_XTINY,
          recoveryTime,
          Gfx.TEXT_JUSTIFY_CENTER
        );
      }
    }
  }

  private function getNextEventString() {
    var nextEventTime = "";

    var myEventID = new Complications.Id(
      Complications.COMPLICATION_TYPE_CALENDAR_EVENTS
    );
    var complication = Complications.getComplication(myEventID);

    if (complication.value != null) {
      nextEventTime = complication.value as String;
    } else {
      nextEventTime = ""; // No event or data not available
    }

    return nextEventTime;
  }
  function drawNextEvent(dc, text_color) {
    dc.setColor(text_color, Gfx.COLOR_BLACK);
    dc.drawText(
      68,
      30,
      Gfx.FONT_SYSTEM_XTINY,
      "N: " + getNextEventString(),
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }
  private function getNextEventTime() {
    var nextEventTime;

    var myEventID = new Complications.Id(
      Complications.COMPLICATION_TYPE_CALENDAR_EVENTS
    );
    var complication = Complications.getComplication(myEventID);

    if (complication.value != null) {
      var nextEventTimeStr = complication.value.toString();

      // ----- extract hour and minute -----
      var hour = 0;
      var minute = 0;
      var amPmIndicator = nextEventTimeStr
        .substring(nextEventTimeStr.length() - 1, nextEventTimeStr.length())
        .toLower(); // Get 'a' or 'p'

      // Extract hour and minute strings
      var hourStr = nextEventTimeStr.substring(0, nextEventTimeStr.find(":"));
      var minuteStr = nextEventTimeStr.substring(
        nextEventTimeStr.find(":") + 1,
        nextEventTimeStr.length() - 1
      );

      hour = hourStr.toNumber();
      minute = minuteStr.toNumber();

      if (amPmIndicator.equals("a")) {
        // 12 AM (midnight) becomes 00 in 24-hour format
        if (hour == 12) {
          hour = 0;
        }
      } else if (amPmIndicator.equals("p")) {
        // For PM hours, add 12, unless it's 12 PM (noon)
        if (hour != 12) {
          hour += 12;
        }
      }

      // ----- construct time object -----
      var now = Time.now();
      var nowInfo = Gregorian.utcInfo(now, Time.FORMAT_LONG);

      var nextEventMomentOptions = {
        :year => nowInfo.year,
        :month => nowInfo.month,
        :day => nowInfo.day,
        :hour => hour,
        :minute => minute,
        :second => 0,
      };

      var nextEventMoment = Gregorian.moment(nextEventMomentOptions);
      nextEventTime = Gregorian.utcInfo(nextEventMoment, Time.FORMAT_LONG);
    } else {
      nextEventTime = null; // No event or data not available
    }

    return nextEventTime;
  }

  function drawDateInset(dc, text_color, reverse) {
    var now = Time.now();
    var info = Calendar.info(now, Time.FORMAT_LONG);
    //var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
    //System.println("DATEDATEDATE");

    //dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    //dc.drawRectangle(0,0,dc.getWidth(),dc.getHeight());

    var dateStr2 = Lang.format("$1$", [info.day]); // .format("%02d")
    var dateStr1 = Lang.format("$1$", [info.day_of_week]);

    if (reverse) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      /*if (width_screen >= 175)  {
                dc.fillCircle(144, 34, 34);
            } else if (width_screen >= 166)  {
                dc.fillCircle(144, 34, 34);
            } else {
                dc.fillCircle(130, 27, 30);  //Instinct S, smaller screen & weird. center of circle is about  131,27 & radius 27
            }*/
      dc.fillCircle(centerX_circle, centerY_circle, radius_circle + 2);
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE); //This works better on sim but worse on real watch
    } else {
      dc.setColor(text_color, Gfx.COLOR_TRANSPARENT);
      //dc.setColor(text_color, Gfx.COLOR_BLACK);//This works better on sim but worse on real watch
    }

    //dc.drawText(width_screen * .15 , (height_screen * -.04), Gfx.FONT_SYSTEM_NUMBER_THAI_HOT, dateStr2, Gfx.TEXT_JUSTIFY_CENTER);
    //dc.drawText(width_screen * .15 , (height_screen * .22), Gfx.FONT_SYSTEM_MEDIUM, dateStr1, Gfx.TEXT_JUSTIFY_CENTER);

    //var f1 = Gfx.FONT_SYSTEM_NUMBER_MEDIUM;
    //deBug ("FONT size", [radius_circle,dc.getFontHeight(Gfx.FONT_SYSTEM_LARGE),
    //dc.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_MEDIUM), dc.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_MILD), dc.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_MEDIUM
    //) ]);

    var f1 = Gfx.FONT_SYSTEM_NUMBER_MEDIUM; //good for instinct

    if (dc.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_MEDIUM) > radius_circle * 1.4) {
      if (dc.getFontHeight(Gfx.FONT_SYSTEM_LARGE) < radius_circle * 1.35) {
        f1 = Gfx.FONT_SYSTEM_LARGE; //for for 965 & some/most others?!?!?!?!?
      } else if (
        dc.getFontHeight(Gfx.FONT_SYSTEM_MEDIUM) <
        radius_circle * 1.35
      ) {
        f1 = Gfx.FONT_SYSTEM_MEDIUM; //Just in case???!~???
      } else {
        f1 = Gfx.FONT_SYSTEM_SMALL;
      }
    }
    //var f1 = Gfx.FONT_SYSTEM_LARGE; //for for 965 & some/most others?!?!?!?!?
    //var f1 = Gfx.FONT_SYSTEM_NUMBER_MEDIUM; //good for instinct
    //var f2 = Gfx.FONT_SYSTEM_SMALL;
    var f2 = Gfx.FONT_SYSTEM_TINY;

    if (width_screen <= 176) {
      var ws = 0.82;
      //var hs1 = -.03;
      var hs1 = 0.0;
      var hs2 = 0.21;

      if (width_screen < 166) {
        //case of Instinct S, smaller screen
        ws = 0.86;
        hs1 = -0.01;
        hs2 = 0.2;
        f1 = Gfx.FONT_SYSTEM_NUMBER_MEDIUM;
        f2 = Gfx.FONT_SYSTEM_TINY;
      }

      //dc.drawText(width_screen * ws , (height_screen * hs2), f2, dateStr1, Gfx.TEXT_JUSTIFY_CENTER);      //better for sim this first
      dc.drawText(
        width_screen * ws,
        height_screen * hs1,
        f1,
        dateStr2,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        width_screen * ws,
        height_screen * hs2,
        f2,
        dateStr1,
        Gfx.TEXT_JUSTIFY_CENTER
      ); //better for watch, this first
    } else {
      //LARGER SCREENS & AMOLED

      var f1_h = dc.getFontHeight(f1);
      var f2_h = dc.getFontHeight(f2);

      dc.drawText(
        centerX_circle,
        centerY_circle + f1_h * 0.075 + 2,
        f2,
        dateStr1,
        Gfx.TEXT_JUSTIFY_CENTER
      ); //better for watch, this first\
      dc.drawText(
        centerX_circle,
        centerY_circle - f1_h * 0.8,
        f1,
        dateStr2,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }

  function drawDateMain(dc) {
    var now = Time.now();
    var info = Calendar.info(now, Time.FORMAT_LONG);

    var dateStr2 = Lang.format("$1$", [info.day.format("%02d")]);
    var dateStr1 = Lang.format("$1$", [info.day_of_week]);

    // var f1 = Gfx.FONT_SMALL;
    var f2 = Gfx.FONT_SMALL;

    // var just1 = Gfx.TEXT_JUSTIFY_LEFT;
    var just2 = Gfx.TEXT_JUSTIFY_RIGHT;

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

    // -- date string - monospace font
    dc.drawRectangle(5, 82, 41, 28);
    // dc.drawText(10, 95, f1, dateStr1, just1 | Gfx.TEXT_JUSTIFY_VCENTER);
    var dateStrXOffset = 15;
    for (var i = 0; i < dateStr1.length(); i++) {
      var character = dateStr1.substring(i, i + 1);

      dc.drawText(
        dateStrXOffset + i * 10,
        85,
        monospaceFont,
        character,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }

    // -- date number
    dc.drawRectangle(140, 82, 32.5, 28);
    dc.drawText(165, 95, f2, dateStr2, just2 | Gfx.TEXT_JUSTIFY_VCENTER);
  }

  function mod(x, y) {
    var part = x / y - Math.floor(x / y);
    return part * y;
  }
}

class ElegantAnaDelegate extends WatchUi.WatchFaceDelegate {
  private var _view as ElegantAnaView;

  public function initialize(view as ElegantAnaView) {
    WatchFaceDelegate.initialize();
    _view = view;
  }

  public function onPowerBudgetExceeded(
    powerInfo as WatchFacePowerInfo
  ) as Void {
    System.println("Average execution time: " + powerInfo.executionTimeAverage);
    System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
    _view.turnPartialUpdatesOff();
  }

  public function onKey(keyEvent) {
    return true;
  }
}
