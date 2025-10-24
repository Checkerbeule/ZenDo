import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/file_lock_helper.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('PersistanceHelper.saveList', () {
    const boxName = 'hive_test_data';

    late MockILockHelper mockLockHelper;

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

      mockLockHelper = MockILockHelper();
      FileLockHelper.instance = mockLockHelper as ILockHelper;
      when(
        mockLockHelper.acquire(LockType.todoList),
      ).thenAnswer((_) async => true);
      when(
        mockLockHelper.release(LockType.todoList),
      ).thenAnswer((_) async => {});
    });

    tearDown(() async {
      // Nach jedem Test Box leeren, aber offen lassen
      await PersistenceHelper.listBox!.clear();
    });

    tearDownAll(() async {
      // Ganz am Ende wieder schließen
      await PersistenceHelper.closeAndRelease();
      await Hive.deleteBoxFromDisk(boxName);
    });

    test('save and load a list with one todo', () async {
      final scope = ListScope.daily;
      final list = TodoList(scope);
      final title = 'test todo';
      final description = 'test description';
      final todo = Todo(title, description);
      list.addTodo(todo);

      await PersistenceHelper.saveList(list);
      final loadedList = await PersistenceHelper.loadList(scope);

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
      await PersistenceHelper.saveList(list);

      final updatedTitle = 'updated';
      final updatedTodo = Todo(updatedTitle);
      list.deleteTodo(initialTodo);
      list.addTodo(updatedTodo);
      await PersistenceHelper.saveList(list);

      final loadedList = await PersistenceHelper.loadList(scope);

      expect(loadedList.todos.length, 1);
      expect(loadedList.todos.first.title, updatedTitle);
    });

    test('loadAll and retreive 0', () async {
      final loadedLists = await PersistenceHelper.loadAll();

      expect(loadedLists.length, 0);
    });
  });
}
