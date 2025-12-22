import 'package:hive_flutter/hive_flutter.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';

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
    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(TodoListAdapter());
    Hive.registerAdapter(ListScopeAdapter());
  }
}
