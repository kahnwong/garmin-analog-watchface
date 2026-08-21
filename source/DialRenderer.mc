import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;
using Toybox.Graphics as Gfx;

class DialRenderer {
  private const SHAPE_FILLED = 0;
  private const SHAPE_LINE = 1;
  private const SHAPE_TRIANGLE = 2;
  private const SHAPE_TRIANGLE_OUTLINE = 5;
  private const SHAPE_CIRCLE_FILLED = 7;
  private const SHAPE_CIRCLE_BLANKED = 9;

  private var _width;
  private var _height;
  private var _maxScreen;
  private var _centerX;
  private var _centerY;
  private var _screenShape;
  private var _hashMarks;

  public function initialize(
    width,
    height,
    maxScreen,
    centerX,
    centerY,
    screenShape,
    hashMarks
  ) {
    _width = width;
    _height = height;
    _maxScreen = maxScreen;
    _centerX = centerX;
    _centerY = centerY;
    _screenShape = screenShape;
    _hashMarks = hashMarks;
  }

  public function drawHands(
    dc,
    clockHour,
    clockMinute,
    alternateTime,
    eventTime
  ) as Void {
    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    var hourWidth = 5;
    var minuteWidth = 4;
    if (_width > 176) {
      hourWidth = (5 / 176.0) * _maxScreen;
      minuteWidth = (4 / 176.0) * _maxScreen;
    }

    drawRadialShape(
      dc,
      getHourAngle(clockHour, clockMinute),
      _width * 0.41 * 0.6,
      hourWidth,
      15,
      SHAPE_FILLED,
      false,
      false
    );

    var alternateShape = SHAPE_TRIANGLE_OUTLINE;
    if (alternateTime.hour >= 6 && alternateTime.hour <= 18) {
      alternateShape = SHAPE_TRIANGLE;
    }
    drawRadialShape(
      dc,
      getHourAngle(alternateTime.hour, clockMinute),
      _width * 0.41 * 0.6,
      hourWidth,
      15,
      alternateShape,
      false,
      false
    );

    if (eventTime != null) {
      drawRadialShape(
        dc,
        getHourAngle(eventTime.hour, eventTime.min),
        _width * 0.41 * 0.6,
        hourWidth,
        15,
        SHAPE_LINE,
        false,
        false
      );
    }

    drawRadialShape(
      dc,
      (clockMinute / 60.0) * Math.PI * 2,
      _width * 0.41,
      minuteWidth,
      15,
      SHAPE_FILLED,
      false,
      false
    );
  }

  public function drawHashMarks(dc, squeeze) as Void {
    for (var i = 0; i < 12; i += 1) {
      if (i == 1 || i == 2) {
        continue;
      }
      if (
        _screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON &&
        i % 3 == 0
      ) {
        continue;
      }

      var offset = i % 3 == 0 ? 15 : 0;
      drawRadialShape(
        dc,
        _hashMarks[i][0],
        88,
        3.5,
        _hashMarks[i][1] + offset,
        SHAPE_FILLED,
        squeeze,
        squeeze
      );
    }
  }

  public function drawCenter(dc, backgroundColor) as Void {
    dc.setPenWidth(1);
    dc.setClip(0, _height / 2 - 20, _width, 40);
    dc.setColor(Gfx.COLOR_WHITE, backgroundColor);
    dc.fillCircle(_width / 2, _height / 2, 6);
    dc.setColor(backgroundColor, backgroundColor);
    dc.drawCircle(_width / 2, _height / 2, 6);
  }

  public function drawDawnDusk(dc, info, squeeze) as Void {
    if (info == null) {
      return;
    }

    for (var i = 0; i < info.size(); i++) {
      var shape = SHAPE_CIRCLE_FILLED;
      if (info[i][0].equals("Dusk")) {
        shape = SHAPE_CIRCLE_BLANKED;
      }

      drawRadialShape(
        dc,
        mod(info[i][1], Math.PI * 2),
        _width * 0.48,
        8,
        2,
        shape,
        squeeze,
        squeeze
      );
    }
  }

  private function drawRadialShape(
    dc,
    angle,
    length,
    width,
    overheadLine,
    shape,
    squeezeX,
    squeezeY
  ) as Void {
    var count = 4;
    var coords = new [count];

    if (shape == SHAPE_LINE) {
      coords = [[0, overheadLine], [0, -length]];
      count = 2;
    } else if (
      shape == SHAPE_TRIANGLE ||
      shape == SHAPE_TRIANGLE_OUTLINE
    ) {
      coords = [
        [-(width / 2), overheadLine],
        [0, -length],
        [width / 2, overheadLine],
      ];
      count = 3;
    } else if (
      shape == SHAPE_CIRCLE_FILLED ||
      shape == SHAPE_CIRCLE_BLANKED
    ) {
      coords = [[0, -length]];
      count = 1;
    } else {
      coords = [
        [-(width / 2), overheadLine],
        [-(width / 2), -length],
        [width / 2, -length],
        [width / 2, overheadLine],
      ];
    }

    var result = new [count];
    var cos = -1;
    var sin = 0;
    if ((Math.PI - angle).abs() > 0.001) {
      cos = Math.cos(angle);
      sin = Math.sin(angle);
    }

    var minY = _height;
    var maxY = 0;
    for (var i = 0; i < count; i += 1) {
      var x = coords[i][0] * cos - coords[i][1] * sin;
      var y = coords[i][0] * sin + coords[i][1] * cos;
      var screenX = _centerX + x;
      var screenY = _centerY + y;
      var squeezeXAmount = 3;
      var squeezeYAmount = 2;
      if (
        shape == SHAPE_CIRCLE_FILLED ||
        shape == SHAPE_CIRCLE_BLANKED
      ) {
        squeezeXAmount = 5 + overheadLine;
        squeezeYAmount = 4 + overheadLine;
      }

      if (squeezeX && (i == 0 || i == count - 1)) {
        if (screenX > _width - squeezeXAmount) {
          screenX = _width - squeezeXAmount;
          if (screenY < _height / 2 - 4) {
            screenY += 1;
          } else if (screenY > _height / 2 + 4) {
            screenY -= 1;
          }
        }
        if (screenX < squeezeXAmount) {
          screenX = squeezeXAmount;
          if (screenY < _height / 2 - 4) {
            screenY += 1;
          } else if (screenY > _height / 2 + 4) {
            screenY -= 1;
          }
        }
      }

      if (squeezeY && (i == 0 || i == count - 1)) {
        if (screenY > _height - squeezeYAmount) {
          screenY = _height - squeezeYAmount;
          if (screenX < _width / 2 - 4) {
            screenX += 1;
          } else if (screenX > _width / 2 + 4) {
            screenX -= 1;
          }
        }
        if (screenY < squeezeYAmount) {
          screenY = squeezeYAmount;
          if (screenX < _width / 2 - 4) {
            screenX += 1;
          } else if (screenX > _width / 2 - 4) {
            screenX -= 1;
          }
        }
      }

      result[i] = [screenX, screenY];
      if (screenY < minY) {
        minY = screenY;
      }
      if (screenY > maxY) {
        maxY = screenY;
      }
    }

    if (
      shape == SHAPE_CIRCLE_FILLED ||
      shape == SHAPE_CIRCLE_BLANKED
    ) {
      dc.setClip(
        0,
        minY - overheadLine - 2,
        _width,
        2 * overheadLine + 4
      );
    } else {
      dc.setClip(0, minY - 3, _width, maxY - minY + 6);
    }
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    if (shape == SHAPE_LINE) {
      dc.drawLine(result[0][0], result[0][1], result[1][0], result[1][1]);
    } else if (shape == SHAPE_TRIANGLE_OUTLINE) {
      drawPolygonOutline(dc, result);
    } else if (shape == SHAPE_CIRCLE_FILLED) {
      dc.fillCircle(result[0][0], result[0][1], overheadLine);
    } else if (shape == SHAPE_CIRCLE_BLANKED) {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillCircle(result[0][0], result[0][1], overheadLine);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(result[0][0], result[0][1], overheadLine);
    } else {
      dc.fillPolygon(result);
    }
  }

  private function drawPolygonOutline(dc, points) as Void {
    for (var i = 0; i < points.size(); i += 1) {
      var next = (i + 1) % points.size();
      dc.drawLine(points[i][0], points[i][1], points[next][0], points[next][1]);
    }
  }

  private function getHourAngle(hour, minute) {
    return (((hour % 12) * 60 + minute) / (12 * 60.0)) * Math.PI * 2;
  }

  private function mod(x, y) {
    return (x / y - Math.floor(x / y)) * y;
  }
}
