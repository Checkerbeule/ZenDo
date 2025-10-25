import 'dart:async';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/persistance/hive_initializer.dart';

Logger logger = Logger(level: Level.debug);

@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await HiveInitializer.initFlutter();
    switch (task) {
      case "transferExpiredTodos":
        await _runWithRetries(task, () async {
          return await ListManager.autoTransferExpiredTodos();
        });
        break;
      default:
        logger.e("Unknown task '$task'");
        break;
    }

    return Future.value(true);
  });
}

Future<void> _runWithRetries(
  String taskname,
  Future<bool> Function() task, {
  int maxRetries = 5,
  Duration delay = const Duration(minutes: 5),
}) async {
  logger.i("Running task '$taskname'...");
  for (int i = 0; i < maxRetries; i++) {
    final successfull = await task();
    if (successfull) {
      logger.i("[Workmanager] Task '$taskname' successfully finished");
      return;
    } else {
      logger.w(
        "[Workmanager] Task '$taskname' NOT successful – retrying in ${delay.inMinutes} min... (Attempt ${i + 1}/$maxRetries)",
      );
      await Future.delayed(delay);
    }
  }
  logger.e("[Workmanager] Task '$taskname' failed after $maxRetries attempts.");
}
