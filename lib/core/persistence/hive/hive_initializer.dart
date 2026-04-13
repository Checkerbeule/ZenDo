import 'package:hive_flutter/hive_flutter.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';

class HiveInitializer {
  static Future<void> initFlutter() async {
    await Hive.initFlutter();
    _registerAdapters();
  }

  static Future<void> initDart(String path) async {
    Hive.init(path);
    _registerAdapters();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(HiveTodoAdapter());
    Hive.registerAdapter(TodoListAdapter());
    Hive.registerAdapter(ListScopeAdapter());
  }
}
