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

  public function drawNextEvent(dc, textColor, value) as Void {
    dc.setColor(textColor, Gfx.COLOR_BLACK);
    dc.drawText(
      40,
      30,
      _materialDesignFont,
      "c",
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      77,
      33,
      Gfx.FONT_SYSTEM_XTINY,
      value,
      Gfx.TEXT_JUSTIFY_CENTER
    );
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
