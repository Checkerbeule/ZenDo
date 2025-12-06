import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zen_do/persistence/persistence_helper.dart';

class ZenDoLifecycleListener extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        unawaited(_releaseLockAndClose());
        break;
      default:
        break;
    }
  }

  Future<void> _releaseLockAndClose() async {
    await PersistenceHelper.closeAndRelease();
  }
}
