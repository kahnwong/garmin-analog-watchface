import Toybox.Graphics;
using Toybox.Graphics as Gfx;

class WidgetRenderer {
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
    dc.drawRectangle(5, 82, 41, 28);
    dc.drawRectangle(140, 82, 30, 28);
    drawCharacterRow(dc, dayOfWeek, 15, 85);
    drawCharacterRow(dc, dayOfMonth, 150, 85);
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

  private function drawCharacterRow(dc, text, x, y) as Void {
    for (var i = 0; i < text.length(); i++) {
      dc.drawText(
        x + i * 10,
        y,
        _monospaceFont,
        text.substring(i, i + 1),
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }
}
