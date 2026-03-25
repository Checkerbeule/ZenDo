import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/core/persistence/hive/file_lock_helper.dart';
import 'package:zen_do/core/persistence/hive/persistence_helper.dart';
import 'package:zen_do/core/utils/time_util.dart';

import '../../core/persistence/mocks/mocks.mocks.dart';

void main() {
  group('TodoList: compareTo tests', () {
    test('TodoList: backlog compareTo backlog is 0', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final backlog_2 = TodoList(ListScope.backlog);

      expect(backlog_1.compareTo(backlog_2), 0);
    });

    test('TodoList: backlog compareTo itself is 0', () {
      final backlog = TodoList(ListScope.backlog);

      expect(backlog.compareTo(backlog), 0);
    });

    test('TodoList: backlog compareTo yearlyList is 1', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final yealrlyList = TodoList(ListScope.yearly);

      expect(backlog_1.compareTo(yealrlyList), 1);
    });

    test('TodoList: yearlyList compareTo backlog is -1', () {
      final backlog_1 = TodoList(ListScope.backlog);
      final yealrlyList = TodoList(ListScope.yearly);

      expect(yealrlyList.compareTo(backlog_1), -1);
    });

    test('TodoList: weeklyList compareTo weeklyList is 0', () {
      final weeklyList_1 = TodoList(ListScope.weekly);
      final weeklyList_2 = TodoList(ListScope.weekly);

      expect(weeklyList_1.compareTo(weeklyList_2), 0);
    });

    test('TodoList: weeklyList compareTo itself is 0', () {
      final weeklyList = TodoList(ListScope.weekly);

      expect(weeklyList.compareTo(weeklyList), 0);
    });

    test('TodoList: dailyList compareTo weeklyList is -1', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);

      expect(dailyList.compareTo(weeklyList), -1);
    });

    test('TodoList: monthlyList compareTo weeklyList is 1', () {
      final monthlyList = TodoList(ListScope.monthly);
      final weeklyList = TodoList(ListScope.weekly);

      expect(monthlyList.compareTo(weeklyList), 1);
    });

    test('TodoList: sorted TodoList list', () {
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

    group('TodoList: dublicate todo title tests', () {
      test(
        'TodoList: addTodo: insertion of 2 todos with same title not possible',
        () async {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: 'same title');
          final todo_2 = Todo(title: 'same title');

          final firstInsertion = await list.addTodo(todo_1);
          final secondInsertion = await list.addTodo(todo_2);

          expect(firstInsertion, isTrue);
          expect(secondInsertion, isFalse);
          expect(list.todos.length, 1);
        },
      );

      test(
        'TodoList: addTodo: insertion of 2 equal todos not possible',
        () async {
          final list = TodoList(ListScope.daily);
          final todo = Todo(title: 'same title');

          final firstInsertion = await list.addTodo(todo);
          final secondInsertion = await list.addTodo(todo);

          expect(firstInsertion, isTrue);
          expect(secondInsertion, isFalse);
          expect(list.todos.length, 1);
        },
      );

      test(
        'TodoList: addAll: insertion of 2 todos with same title not possible',
        () {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: 'same title');
          final todo_2 = Todo(title: 'same title');

          list.addAll([todo_1, todo_2]);

          expect(list.todos.length, 1);
        },
      );
    });

    group('TodoList: expirationDate tests', () {
      test(
        'TodoList: inserted todo to dailyList gets expirationDate tomorrow',
        () {
          final dailyList = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo expires tomorrow');
          dailyList.addTodo(todo);
          final expectedDate = DateTime.now().add(Duration(days: 1)).normalized;

          expect(todo.expirationDate != null, true);
          expect(todo.expirationDate, expectedDate);
        },
      );

      test(
        'TodoList: inserted todo to dailyList usind addAll gets no expirationDate',
        () {
          final dailyList = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo expires tomorrow');
          dailyList.addAll([todo]);

          expect(todo.expirationDate, null);
        },
      );

      test(
        'TodoList: inserted todo to weekyList gets expirationDate in 7 days',
        () {
          final weeklyList = TodoList(ListScope.weekly);
          final todo = Todo(title: 'todo expires in 7 days');
          weeklyList.addTodo(todo);
          final expectedDate = DateTime.now().add(Duration(days: 7)).normalized;

          expect(todo.expirationDate != null, true);
          expect(todo.expirationDate, expectedDate);
        },
      );

      test(
        'TodoList: inserted todo to monthlyList gets expirationDate in 30 days',
        () {
          final monthlyList = TodoList(ListScope.monthly);
          final todo = Todo(title: 'todo expires in 30 days');
          monthlyList.addTodo(todo);
          final expectedDate = DateTime.now()
              .add(Duration(days: 30))
              .normalized;

          expect(todo.expirationDate != null, true);
          expect(todo.expirationDate, expectedDate);
        },
      );

      test(
        'TodoList: inserted todo to yearlyList gets expirationDate in 365 days',
        () {
          final yearlyList = TodoList(ListScope.yearly);
          final todo = Todo(title: 'todo expires in 365 days');
          yearlyList.addTodo(todo);
          final expectedDate = DateTime.now()
              .add(Duration(days: 365))
              .normalized;

          expect(todo.expirationDate != null, true);
          expect(todo.expirationDate, expectedDate);
        },
      );

      test('TodoList: inserted todo to backlog gets no expirationDate', () {
        final backlog = TodoList(ListScope.backlog);
        final todo = Todo(title: 'todo expires tomorrow');
        backlog.addTodo(todo);

        expect(todo.expirationDate == null, true);
      });

      test(
        'TodoList: inserted todo with expirationDate keps expirationDate',
        () async {
          final list = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo with custom expirationDate');
          final now = DateTime.now().normalized;
          todo.expirationDate = now;

          final added = await list.addTodo(todo);

          expect(added, isTrue);
          expect(todo.expirationDate, now);
        },
      );

      test(
        'TodoList: inserted todo with expirationDate keps expirationDate',
        () async {
          final list = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo with custom expirationDate');
          final now = DateTime.now().add(Duration(days: 1)).normalized;
          todo.expirationDate = now;

          final added = await list.addTodo(todo);

          expect(added, isTrue);
          expect(todo.expirationDate, now);
        },
      );

      test(
        'TodoList: todo with expirationDate that does not fit the scope of the list fails to be added',
        () async {
          final list = TodoList(ListScope.daily);
          final todo = Todo(title: 'todo with custom expirationDate');
          final now = DateTime.now().add(Duration(days: 2)).normalized;
          todo.expirationDate = now;

          final added = await list.addTodo(todo);

          expect(added, isFalse);
          expect(list.todos, isEmpty);
        },
      );

      test('TodoList: restored todo keeps expirationDate', () {
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
    test('TodoList: done todo is saved in doneList', () {
      final yearlyList = TodoList(ListScope.yearly);
      final todo = Todo(title: 'todo expires in 365 days');
      yearlyList.addTodo(todo);
      yearlyList.markAsDone(todo);

      expect(yearlyList.todos.length, 0);
      expect(yearlyList.doneTodos.length, 1);
      expect(yearlyList.doneTodos.first, todo);
    });

    group('TodoList: completionDate tests', () {
      test('TodoList: done todo gets completionDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'done todo with completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);

        expect(todo.expirationDate != null, true);
      });

      test('TodoList: restored todo has no completionDate', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todo = Todo(title: 'restored todo without completionDate');
        yearlyList.addTodo(todo);
        yearlyList.markAsDone(todo);
        yearlyList.restoreTodo(todo);

        expect(todo.completionDate, null);
      });
    });

    group('TodoList: replaceTodo tests', () {
      test(
        'TodoList: replaceTodo replacement successfull and index of replacement stays the same',
        () async {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: 'todo 1');
          final todo_2 = Todo(title: 'todo 2');
          final todo_3 = Todo(title: 'todo 3');
          final newTodo = Todo(title: 'new todo');

          list.addAll([todo_1, todo_2, todo_3]);
          final isReplaced = await list.replaceTodo(todo_2, newTodo);

          expect(isReplaced, isTrue);
          expect(list.todos.length, 3);
          expect(list.todos.first, todo_1);
          expect(list.todos.elementAt(1), newTodo);
          expect(list.todos.last, todo_3);
        },
      );

      test(
        'TodoList: replaceTodo replacement with edited description successfull',
        () async {
          final list = TodoList(ListScope.daily);
          final original = Todo(title: 'todo 1');
          final copy = original.copyWith(description: 'new description');

          list.addTodo(original);
          final isReplaced = await list.replaceTodo(original, copy);

          expect(isReplaced, isTrue);
          expect(list.todos.length, 1);
          expect(list.todos.first, copy);
        },
      );

      test(
        'TodoList: replaceTodo modified copy of todo successfully replaced',
        () async {
          final list = TodoList(ListScope.daily);
          final oldTodo = Todo(title: 'original');
          final newTodo = Todo.copy(oldTodo);
          newTodo.title = 'new title';
          list.addTodo(oldTodo);

          final isReplaced = await list.replaceTodo(oldTodo, newTodo);

          expect(isReplaced, isTrue);
          expect(list.todos.length, 1);
          expect(list.todos.first, newTodo);
        },
      );

      test('TodoList: replaceTodo with copy not possible', () async {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        list.addTodo(oldTodo);
        final copy = Todo.copy(oldTodo);

        final isReplaced = await list.replaceTodo(oldTodo, copy);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 1);
        expect(list.todos.first, oldTodo);
      });

      test('TodoList: replaceTodo with same not possible', () async {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        list.addTodo(oldTodo);

        final isReplaced = await list.replaceTodo(oldTodo, oldTodo);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 1);
        expect(list.todos.first, oldTodo);
      });

      test('TodoList: replaceTodo with non existent fails', () async {
        final list = TodoList(ListScope.daily);
        final oldTodo = Todo(title: 'original');
        final newTodo = Todo(title: 'original');

        final isReplaced = await list.replaceTodo(oldTodo, newTodo);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 0);
      });

      test('TodoList: replaceTodo with same titile fails', () async {
        final list = TodoList(ListScope.daily);
        final title = 'title';
        final oldTodo = Todo(title: 'todo to replace');
        final newTodo = Todo(title: title);
        final todo_1 = Todo(title: 'another todo');
        final todoWithConflictingTitle = Todo(title: title);
        list.addAll([todo_1, oldTodo, todoWithConflictingTitle]);

        final isReplaced = await list.replaceTodo(oldTodo, newTodo);

        expect(isReplaced, isFalse);
        expect(list.todos.length, 3);
        expect(list.todos.first, todo_1);
        expect(list.todos[1], oldTodo);
        expect(list.todos.last, todoWithConflictingTitle);
      });
    });

    group('TodoList: delete todo tests', () {
      test('TodoList: deleteTodo: deleting existent todo successfull', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'title');
        list.addTodo(todo);

        list.deleteTodo(todo);

        expect(list.todos.length, 0);
      });

      test(
        'TodoList: deleteTodo: deleting non existent todo does not effect list',
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

      test('TodoList: deleteAll: deleting existent todos successfull', () {
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
        'TodoList: deleteAll: deleting non existent todos does not effect list',
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

    group('TodoList: isTodoTitleVacant tests', () {
      test('TodoList: isTodoTitleVacant returns true', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'Title');
        list.addTodo(todo);

        final isVacant = list.isTodoTitleVacant('Other title');

        expect(isVacant, isTrue);
      });

      test('TodoList: isTodoTitleVacant returns false', () {
        final title = 'same title';
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: title);
        list.addTodo(todo);

        final isVacant = list.isTodoTitleVacant(title);

        expect(isVacant, isFalse);
      });

      test(
        'TodoList: isTodoTitleVacant returns false even with leading an tailing spaces',
        () {
          final title = 'same title';
          final list = TodoList(ListScope.daily);
          final todo = Todo(title: '   $title');
          list.addTodo(todo);

          final isVacant = list.isTodoTitleVacant('$title   ');

          expect(isVacant, isFalse);
        },
      );
    });

    group('TodoList: todo order tests', () {
      test(
        'TodoList: initMaxOrderAfterLoad sets _currentMaxOrder correctly',
        () {
          final list = TodoList(ListScope.daily);
          final todo_1 = Todo(title: '1');
          final todo_2 = Todo(title: '2');
          final todo_3 = Todo(title: '3');
          list.addAll([todo_1, todo_2]);

          list.initMaxOrderAfterLoad();
          list.addTodo(todo_3);

          expect(todo_3.order, 3000);
        },
      );

      test('TodoList: addTodo sets order correctly', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');

        list.addTodo(todo_3);
        list.addTodo(todo_1);
        list.addTodo(todo_2);

        expect(list.todos.first, todo_3);
        expect(todo_3.order, 1000);
        expect(list.todos[1], todo_1);
        expect(todo_1.order, 2000);
        expect(list.todos.last, todo_2);
        expect(todo_2.order, 3000);
      });

      test('TodoList: addAll sets order correctly', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');

        list.addAll([todo_3, todo_1, todo_2]);

        expect(list.todos.first, todo_3);
        expect(todo_3.order, 1000);
        expect(list.todos[1], todo_1);
        expect(todo_1.order, 2000);
        expect(list.todos.last, todo_2);
        expect(todo_2.order, 3000);
      });

      test('TodoList: deleteTodo keeps order on todo', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'todo');

        list.addTodo(todo);
        list.deleteTodo(todo);

        expect(todo.order, 1000);
      });

      test('TodoList: deleteAll keeps order on todo', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');

        list.addAll([todo_1, todo_2]);
        list.deleteAll([todo_1, todo_2]);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 2000);
      });

      test('TodoList: markAsDone keeps order on todo', () {
        final list = TodoList(ListScope.daily);
        final todo = Todo(title: 'todo');

        list.addTodo(todo);
        list.markAsDone(todo);

        expect(todo.order, 1000);
      });

      test('TodoList: restoreTodo keeps order on todo', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');

        list.addAll([todo_1, todo_2]);
        list.markAsDone(todo_1);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 2000);
      });

      test(
        'TodoList: reorder on moved todo that is not in list not possible',
        () {
          final list = TodoList(ListScope.daily);
          final todoNotInList = Todo(title: '0');

          list.reorder(todoNotInList, null);

          expect(todoNotInList.order, isNull);
        },
      );

      test('TodoList: reorder successfull', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');
        list.addAll([todo_1, todo_2, todo_3]);

        list.reorder(todo_3, todo_1);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 2000);
        expect(todo_3.order, 1500);
      });

      test('TodoList: reorder to first elem successfull', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');
        list.addAll([todo_1, todo_2, todo_3]);
        list.reorder(todo_3, null);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 2000);
        expect(todo_3.order, 500);
      });

      test('TodoList: reorder to last elem successfull', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');
        list.addAll([todo_1, todo_2, todo_3]);
        list.reorder(todo_2, todo_3);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 4000);
        expect(todo_3.order, 3000);
      });

      test('TodoList: reorder with _normalizeOrder successfull', () {
        final list = TodoList(ListScope.daily);
        final todo_1 = Todo(title: '1');
        final todo_2 = Todo(title: '2');
        final todo_3 = Todo(title: '3');
        list.addAll([todo_1, todo_2, todo_3]);
        todo_2.order = todo_1.order! + 1;

        list.reorder(todo_3, todo_1);

        expect(todo_1.order, 1000);
        expect(todo_2.order, 2000);
        expect(todo_3.order, 1500);
      });
    });
  });
}
