import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/persistence/hive_initializer.dart';
import 'package:zen_do/utils/time_util.dart';

Logger logger = Logger(level: Level.debug);
const String autoTransferUniqueTaskName = 'de.appzen.zendo.autotransfer_task';
const String autoTransferTaskIdentifier = 'dailyExpiredTodoTransfer';

Future<void> initAndRegisterBackgroundTasks() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().cancelByUniqueName(
    'dailyTodoTransfer_v2',
  ); // TODO remove for next build
  await Workmanager().cancelByUniqueName(
    'dailyTodoTransfer',
  ); // TODO remove for next build
  await Workmanager().cancelByUniqueName(
    autoTransferUniqueTaskName,
  ); // TODO remove for next build
  final appDir = await getApplicationDocumentsDirectory();
  await Workmanager().registerPeriodicTask(
    autoTransferUniqueTaskName,
    autoTransferTaskIdentifier,
    inputData: {"dbPath": appDir.path},
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: Duration(minutes: 5),
    initialDelay: durationUntilNextMidnight(),
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

@pragma("vm:entry-point")
void callbackDispatcher() {
  logger.d("Callback-Dispatcher started");

  Workmanager().executeTask((task, inputData) async {
    try {
      logger.d("Workmanager task triggered: $task");
      WidgetsFlutterBinding.ensureInitialized();

      final String? dbPath = inputData?['dbPath'];
      if (dbPath == null) return false;

      await HiveInitializer.initDart(dbPath);

      switch (task) {
        case autoTransferTaskIdentifier:
          return await ListManager.autoTransferTodos();
        default:
          logger.e("Unknown task '$task'");
          break;
      }
      return true;
    } catch (e, s) {
      logger.e(
        "Fatal Error in Workmanager Task: $task\n"
        "Exception: $e\n"
        "Stacktrace: $s",
      );
      return false;
    }
  });
}
