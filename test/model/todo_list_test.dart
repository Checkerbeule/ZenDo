import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/file_lock_helper.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('compareTo tests', () {
    test('backlog compareTo backlog is 0', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final backlog_2 = TodoList(ListScope.backlog);

      expect(backlog_1.compareTo(backlog_2), 0);
    });

    test('backlog compareTo itself is 0', () {
      final backlog = TodoList(ListScope.backlog);

      expect(backlog.compareTo(backlog), 0);
    });

    test('backlog compareTo yearlyList is 1', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final yealrlyList = TodoList(ListScope.yearly);

      expect(backlog_1.compareTo(yealrlyList), 1);
    });

    test('yearlyList compareTo backlog is -1', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final yealrlyList = TodoList(ListScope.yearly);

      expect(yealrlyList.compareTo(backlog_1), -1);
    });

    test('weeklyList compareTo weeklyList is 0', () {
      final weeklyList_1 = TodoList(ListScope.weekly);
      final weeklyList_2 = TodoList(ListScope.weekly);

      expect(weeklyList_1.compareTo(weeklyList_2), 0);
    });

    test('weeklyList compareTo itself is 0', () {
      final weeklyList = TodoList(ListScope.weekly);

      expect(weeklyList.compareTo(weeklyList), 0);
    });

    test('dailyList compareTo weeklyList is -1', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);

      expect(dailyList.compareTo(weeklyList), -1);
    });

    test('monthlyList compareTo weeklyList is 1', () {
      final monthlyList = TodoList(ListScope.monthly);
      final weeklyList = TodoList(ListScope.weekly);

      expect(monthlyList.compareTo(weeklyList), 1);
    });

    test('sorted TodoList list', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);
      final monthlyList = TodoList(ListScope.monthly);
      final yearlyList = TodoList(ListScope.yearly);
      final backlog = TodoList(ListScope.backlog);

      var lists = [weeklyList, yearlyList, backlog, dailyList, monthlyList];
      lists.sort((a, b) => a.compareTo(b));

      expect(lists.first, dailyList);
      expect(lists[1], weeklyList);
      expect(lists[2], monthlyList);
      expect(lists[3], yearlyList);
      expect(lists.last, backlog);
    });
  });

  group('tests using mocks', () {
    late MockHiveInterface hiveMock;
    late MockBox<TodoList> mockBox;
    late MockILockHelper mockLockHelper;

    setUpAll(() {
      hiveMock = MockHiveInterface();
      mockBox = MockBox<TodoList>();
      PersistenceHelper.hive = hiveMock;

      when(hiveMock.openBox<TodoList>(any)).thenAnswer((_) async => mockBox);
      when(mockBox.delete(any)).thenAnswer((_) => Future<void>(() {}));
      when(mockBox.put(any, any)).thenAnswer((_) => Future<void>(() {}));
      when(mockBox.isOpen).thenReturn(false);

      mockLockHelper = MockILockHelper();
      FileLockHelper.instance = mockLockHelper as ILockHelper;
      when(
        mockLockHelper.acquire(LockType.todoList),
      ).thenAnswer((_) async => true);
      when(
        mockLockHelper.release(LockType.todoList),
      ).thenAnswer((_) async => {});
    });

    setUp(() {}); //TODO use mock for PersistentHelper and check if it is called

    group('TodoList dublicate todo title tests', () {
      test(
        'TodoList addTodo: insertion of 2 todos with same title not possible',
        () {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: 'same title');
          final todo_2 = Todo(title: 'same title');

          final firstInsertion = list.addTodo(todo_1);
          final secondInsertion = list.addTodo(todo_2);

          expect(firstInsertion, isTrue);
          expect(secondInsertion, isFalse);
          expect(list.todos.length, 1);
        },
      );

      test('TodoList addTodo: insertion of 2 equal todos not possible', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'same title');

        final firstInsertion = list.addTodo(todo);
        final secondInsertion = list.addTodo(todo);

        expect(firstInsertion, isTrue);
        expect(secondInsertion, isFalse);
        expect(list.todos.length, 1);
      });

      test(
        'TodoList addAll: insertion of 2 todos with same title not possible',
        () {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: 'same title');
          final todo_2 = Todo(title: 'same title');

          list.addAll([todo_1, todo_2]);

          expect(list.todos.length, 1);
        },
      );
    });

    group('expirationDate tests', () {
      test('inserted todo to dailyList gets expirationDate tomorrow', () {
        final dailyList = TodoList(ListScope.daily);
        final todo = Todo(title: 'todo expires tomorrow');
        dailyList.addTodo(todo);
        final now = DateTime.now();
        final expectedDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: 1));

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expectedDate);
      });

      test(
        'inserted todo to dailyList usind addAll gets no expirationDate',
        () {
          final dailyList = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo expires tomorrow');
          dailyList.addAll([todo]);

          expect(todo.expirationDate, null);
        },
      );

      test('inserted todo to weekyList gets expirationDate in 7 days', () {
        final weeklyList = TodoList(ListScope.weekly);
        final todo = Todo(title: 'todo expires in 7 days');
        weeklyList.addTodo(todo);
        final now = DateTime.now();
        final expectedDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: 7));

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expectedDate);
      });

      test('inserted todo to monthlyList gets expirationDate in 30 days', () {
        final monthlyList = TodoList(ListScope.monthly);
        final todo = Todo(title: 'todo expires in 30 days');
        monthlyList.addTodo(todo);
        final now = DateTime.now();
        final expectedDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: 30));

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expectedDate);
      });

      test('inserted todo to yearlyList gets expirationDate in 365 days', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'todo expires in 365 days');
        yearlyList.addTodo(todo);
        final now = DateTime.now();
        final expectedDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: 365));

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expectedDate);
      });

      test('inserted todo to backlog gets no expirationDate', () {
        final backlog = TodoList(ListScope.backlog);
        final todo = Todo(title: 'todo expires tomorrow');
        backlog.addTodo(todo);

        expect(todo.expirationDate == null, true);
      });

      test('restored todo keeps expirationDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'todo expires in 365 days');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);
        final expirationDate = todo.expirationDate;
        yearlyList.restoreTodo(todo);

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expirationDate);
      });
    });

    group('done todos tests', () {
      test('done todo is saved in doneList', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'todo expires in 365 days');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);

        expect(yearlyList.todos.length, 0);
        expect(yearlyList.doneTodos.length, 1);
        expect(yearlyList.doneTodos.first, todo);
      });
    });

    group('completionDate tests', () {
      test('done todo gets completionDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'done todo with completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);

        expect(todo.expirationDate != null, true);
      });

      test('restored todo has no completionDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'restored todo without completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);
        yearlyList.restoreTodo(todo);

        expect(todo.completionDate, null);
      });
    });

    group('TodoList replaceTodo tests', () {
      test('TodoList replaceTodo: different todo successfully replaced', () {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        final newTodo = Todo(title: 'different todo');
        list.addTodo(oldTodo);

        final isReplaced = list.replaceTodo(oldTodo, newTodo);

        expect(isReplaced, isTrue);
        expect(list.todos.length, 1);
        expect(list.todos.first, newTodo);
      });

      test(
        'TodoList replaceTodo: modified copy of todo successfully replaced',
        () {
          final list = TodoList(ListScope.daily);
          final oldTodo = Todo(title: 'original');
          final newTodo = Todo.copy(oldTodo);
          newTodo.title = 'new title';
          list.addTodo(oldTodo);

          final isReplaced = list.replaceTodo(oldTodo, newTodo);

          expect(isReplaced, isTrue);
          expect(list.todos.length, 1);
          expect(list.todos.first, newTodo);
        },
      );

      test('TodoList replaceTodo: replace with copy not possible', () {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        list.addTodo(oldTodo);
        final copy = Todo.copy(oldTodo);

        final isReplaced = list.replaceTodo(oldTodo, copy);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 1);
        expect(list.todos.first, oldTodo);
      });

      test('TodoList replaceTodo: replace with same not possible', () {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        list.addTodo(oldTodo);

        final isReplaced = list.replaceTodo(oldTodo, oldTodo);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 1);
        expect(list.todos.first, oldTodo);
      });

      test('TodoList replaceTodo: oldTodo not existent fails', () {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        final newTodo = Todo(title: 'original');

        final isReplaced = list.replaceTodo(oldTodo, newTodo);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 0);
      });
    });

    group('TodoList delete todo tests', () {
      test('TodoList deleteTodo: deleting existent todo successfull', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'title');
        list.addTodo(todo);

        list.deleteTodo(todo);

        expect(list.todos.length, 0);
      });

      test(
        'TodoList deleteTodo: deleting non existent todo does not effect list',
        () {
          final list = TodoList(ListScope.daily);
          final existingTodo = Todo(title: 'title');
          final nonExistingTodo = Todo(title: 'not existent');
          list.addTodo(existingTodo);

          list.deleteTodo(nonExistingTodo);

          expect(list.todos.length, 1);
          expect(list.todos.first, existingTodo);
        },
      );

      test('TodoList deleteAll: deleting existent todos successfull', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');
        list.addAll([todo_1, todo_2, todo_3]);

        list.deleteAll([todo_1, todo_3]);

        expect(list.todos.length, 1);
        expect(list.todos.first, todo_2);
      });

      test(
        'TodoList deleteAll: deleting non existent todos does not effect list',
        () {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: '1');
          final todo_2 = Todo(title: '2');
          final todo_3 = Todo(title: '3');
          list.addTodo(todo_2);

          list.deleteAll([todo_1, todo_3]);

          expect(list.todos.length, 1);
          expect(list.todos.first, todo_2);
        },
      );
    });
  });
}
