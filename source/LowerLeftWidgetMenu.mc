import Toybox.Application;
import Toybox.WatchUi;

class WatchFaceSettingsMenu extends WatchUi.Menu2 {
  public function initialize() {
    Menu2.initialize({ :title => Rez.Strings.SettingsTitle });
    addItem(new WatchUi.MenuItem(Rez.Strings.LowerLeftMenuTitle, null, :lowerLeft, null));
  }
}

class WatchFaceSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  public function initialize() {
    Menu2InputDelegate.initialize();
  }

  public function onSelect(item as WatchUi.MenuItem) as Void {
    if (item.getId() == :lowerLeft) {
      WatchUi.pushView(
        new LowerLeftWidgetMenu(),
        new LowerLeftWidgetMenuDelegate(),
        WatchUi.SLIDE_LEFT
      );
    }
  }
}

class LowerLeftWidgetMenu extends WatchUi.Menu2 {
  public function initialize() {
    Menu2.initialize({ :title => Rez.Strings.LowerLeftMenuTitle });
    addItem(new WatchUi.MenuItem(Rez.Strings.RainProbabilityLabel, null, 0, null));
    addItem(new WatchUi.MenuItem(Rez.Strings.PressureTrendLabel, null, 1, null));
    addItem(new WatchUi.MenuItem(Rez.Strings.BarometerChartLabel, null, 2, null));
    var selected = Application.Properties.getValue("LowerLeftWidget");
    setFocus(selected == 2 ? 2 : (selected == 1 ? 1 : 0));
  }
}

class LowerLeftWidgetMenuDelegate extends WatchUi.Menu2InputDelegate {
  public function initialize() {
    Menu2InputDelegate.initialize();
  }

  public function onSelect(item as WatchUi.MenuItem) as Void {
    Application.Properties.setValue("LowerLeftWidget", item.getId());
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    WatchUi.requestUpdate();
  }
}
