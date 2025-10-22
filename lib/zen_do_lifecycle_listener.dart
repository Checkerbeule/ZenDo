import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zen_do/persistance/file_lock_helper.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

class ZenDoLifecycleListener extends WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        unawaited(_releaseLockAndClose());
        break;
      case AppLifecycleState.resumed:
        unawaited(FileLockHelper.acquire(FileLockType.todoList));
        break;
      default:
        break;
    }
  }

  Future<void> _releaseLockAndClose() async {
    await PersistenceHelper.close();
    await FileLockHelper.release(FileLockType.todoList);
  }
}
