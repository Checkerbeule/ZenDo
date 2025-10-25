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
    group('expirationDate tests', () {
      test('inserted todo to dailyList gets expirationDate tomorrow', () {
        final dailyList = TodoList(ListScope.daily);
        final todo = Todo('todo expires tomorrow');
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
          final todo = Todo('todo expires tomorrow');
          dailyList.addAll([todo]);

          expect(todo.expirationDate, null);
        },
      );

      test('inserted todo to weekyList gets expirationDate in 7 days', () {
        final weeklyList = TodoList(ListScope.weekly);
        final todo = Todo('todo expires in 7 days');
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
        final todo = Todo('todo expires in 30 days');
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
        final todo = Todo('todo expires in 365 days');
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
        final todo = Todo('todo expires tomorrow');
        backlog.addTodo(todo);

        expect(todo.expirationDate == null, true);
      });

      test('restored todo keeps expirationDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo('todo expires in 365 days');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);
        final expirationDate = todo.expirationDate;
        yearlyList.restoreTodo(todo);

        expect(todo.expirationDate != null, true);
        expect(todo.expirationDate, expirationDate);
      });

      test('get expired todos', () {
        final weeklyList = TodoList(ListScope.weekly);
        final todo_1 = Todo('expired 1');
        final todo_2 = Todo('expired 2');
        weeklyList.addTodo(todo_1);
        weeklyList.addTodo(todo_2);
        todo_1.expirationDate = todo_1.expirationDate!.subtract(
          Duration(days: 7),
        );
        todo_2.expirationDate = todo_2.expirationDate!.subtract(
          Duration(days: 8),
        );

        expect(weeklyList.getExpiredTodos(ListScope.daily.duration).length, 2);
      });
    });

    group('done todos tests', () {
      test('done todo is saved in doneList', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo('todo expires in 365 days');
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
        final todo = Todo('done todo with completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);

        expect(todo.expirationDate != null, true);
      });

      test('restored todo has no completionDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo('restored todo without completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);
        yearlyList.restoreTodo(todo);

        expect(todo.completionDate, null);
      });
    });
  });
}
