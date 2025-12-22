import 'dart:async';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/persistence/hive_initializer.dart';

Logger logger = Logger(level: Level.debug);

@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    logger.i("### CALLBACK DISPATCHER HIT ###"); //TODO delete this line
    final dir = await getApplicationDocumentsDirectory();
    await HiveInitializer.initDart(dir.path);

    switch (task) {
      case "transferExpiredTodos":
        return await ListManager.autoTransferTodos();
      default:
        logger.e("Unknown task '$task'");
        break;
    }

    return Future.value(true);
  });
}
