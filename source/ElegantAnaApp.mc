//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class ElegantAnaWatch extends Application.AppBase {
  var mainView;

  public function initialize() {
    AppBase.initialize();

    Options = [
      infiniteSecondOption,
      secondDisplay,
      secondHandOption,
      dawnDuskMarkers,

      showBattery,
      showMinutes,

      showDayMinutes,
      showSteps,
      showMove,
      showDate,
      showMonthDay,
      hourNumbers,
      hourHashes,
      secondHashes,
      aggressiveClear,

      showBodyBattery,
    ];

    numOptions = Options.size();

    defOptions = {
      infiniteSecondOption => 2,
      secondDisplay => 0,
      secondHandOption => 1,
      dawnDuskMarkers => 0,

      showBattery => false,
      showMinutes => false,

      showDayMinutes => false,
      showSteps => false,
      showMove => true,
      showDate => true,
      showMonthDay => false,
      hourNumbers => false,
      hourHashes => true,
      secondHashes => false,
      aggressiveClear => false,

      showBodyBattery => false,

      //lastLoc_saved => [38, -94],
    };

    readStorageValues();
    defOptions = null;
  }

  public function onStart(state as Dictionary?) as Void {}

  public function onStop(state as Dictionary?) as Void {}

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

  public function getSettingsView() as [Views] or
    [Views, InputDelegates] or
    Null {
    System.println("6A");
    return [
      new $.ElegantAnaSettingsMenu(),
      new $.ElegantAnaSettingsMenuDelegate(),
    ];
  }
}

public function readStorageValues() as Void {
  if (!(Application has :Storage)) {
    $.Options_Dict = defOptions;
    return;
  }

  var temp;

  for (var i = 0; i < numOptions; i++) {
    temp = Storage.getValue(Options[i]);
    $.Options_Dict[Options[i]] = temp != null ? temp : defOptions[Options[i]];
    Storage.setValue(Options[i], $.Options_Dict[Options[i]]);
  }
}
