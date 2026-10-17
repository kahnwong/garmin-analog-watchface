//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ElegantAnaWatch extends Application.AppBase {
  var mainView;

  public function initialize() {
    AppBase.initialize();
  }

  public function onStart(state as Dictionary?) as Void {}

  public function onStop(state as Dictionary?) as Void {}

  public function onSettingsChanged() as Void {
    WatchUi.requestUpdate();
  }

  public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
    return [new WatchFaceSettingsMenu(), new WatchFaceSettingsMenuDelegate()];
  }

  public function getInitialView() as [Views] or [Views, InputDelegates] {
    if (WatchUi has :WatchFaceDelegate) {
      var view = new $.ElegantAnaView();
      mainView = view;
      var delegate = new $.ElegantAnaDelegate(view);
      return [view, delegate];
    } else {
      return [new $.ElegantAnaView()];
    }
  }

}
