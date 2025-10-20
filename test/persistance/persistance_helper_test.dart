import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/persistance_helper.dart';

@GenerateMocks([Box])
void main() {
  group('PersistanceHelper.saveList', () {
    late Box<TodoList> box;
    const boxName = 'hive_test_data';

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory('./test/$boxName'); // Ordner für Tests
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      Hive.init(dir.path);

      Hive.registerAdapter(TodoAdapter());
      Hive.registerAdapter(TodoListAdapter());
      Hive.registerAdapter(ListScopeAdapter());

      box = await Hive.openBox(boxName);
    });

    tearDown(() async {
      // Nach jedem Test Box leeren, aber offen lassen
      await box.clear();
    });

    tearDownAll(() async {
      // Ganz am Ende wieder schließen
      await box.close();
      Hive.deleteBoxFromDisk(boxName);
    });

    test('save and load a list with one todo', () async {
      final scope = ListScope.daily;
      final list = TodoList(scope);
      final title = 'test todo';
      final description = 'test description';
      final todo = Todo(title, description);
      list.addTodo(todo);

      await PersistanceHelper.saveList(list);
      final loadedList = await PersistanceHelper.loadList(scope);

      expect(loadedList.scope, ListScope.daily);
      expect(loadedList.todos.length, 1);
      expect(loadedList.todos.first.title, title);
      expect(loadedList.todos.first.description, description);
    });

    test('save a list, update it, retreive updated data', () async {
      final scope = ListScope.daily;
      final list = TodoList(scope);

      final initialTodo = Todo('initial todo');
      list.addTodo(initialTodo);
      await PersistanceHelper.saveList(list);

      final updatedTitle = 'updated';
      final updatedTodo = Todo(updatedTitle);
      list.deleteTodo(initialTodo);
      list.addTodo(updatedTodo);
      await PersistanceHelper.saveList(list);

      final loadedList = await PersistanceHelper.loadList(scope);

      expect(loadedList.todos.length, 1);
      expect(loadedList.todos.first.title, updatedTitle);
    });

    test('loadAll and retreive ${ListScope.values.length}', () async {
      final loadedLists = await PersistanceHelper.loadAll();

      expect(loadedLists.length, ListScope.values.length);
    });
  });
}
