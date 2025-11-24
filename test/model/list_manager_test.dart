import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/file_lock_helper.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('ListManager sorted lists tests', () {
    test('ListManager get allLists, returns sorted lists', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);
      final monthlyList = TodoList(ListScope.monthly);
      final yearlyList = TodoList(ListScope.yearly);
      final backlog = TodoList(ListScope.backlog);

      var manager = ListManager([
        weeklyList,
        yearlyList,
        backlog,
        dailyList,
        monthlyList,
      ]);
      final lists = manager.allLists;

      expect(lists.first, dailyList);
      expect(lists[1], weeklyList);
      expect(lists[2], monthlyList);
      expect(lists[3], yearlyList);
      expect(lists.last, backlog);
    });

    test('ListManager addList, returns sorted lists', () {
      final dailyList = TodoList(ListScope.daily);
      final backlog = TodoList(ListScope.backlog);

      var manager = ListManager(
        [dailyList, backlog],
        activeScopes: {ListScope.daily, ListScope.backlog},
      );
      final monthlyListToAdd = TodoList(ListScope.monthly);
      manager.addList(monthlyListToAdd);
      final lists = manager.allLists;

      expect(lists.first, dailyList);
      expect(lists[1], monthlyListToAdd);
      expect(lists.last, backlog);
    });

    test('ListManager initialize with no list, returns all empty lists', () {
      final manager = ListManager([]);
      final lists = manager.allLists;

      expect(manager.allLists.length, ListScope.values.length);
      expect(lists.first.scope, ListScope.daily);
      expect(lists[1].scope, ListScope.weekly);
      expect(lists[2].scope, ListScope.monthly);
      expect(lists[3].scope, ListScope.yearly);
      expect(lists.last.scope, ListScope.backlog);
      expect(lists.first.todos.length, 0);
      expect(lists[1].todos.length, 0);
      expect(lists[2].todos.length, 0);
      expect(lists[3].todos.length, 0);
      expect(lists.last.todos.length, 0);
    });

    test(
      'ListManager initialize wit no list and a set of ListTypes, returns all empty lists with the given ListType set',
      () {
        final activeScopes = <ListScope>{
          ListScope.daily,
          ListScope.weekly,
          ListScope.yearly,
          ListScope.backlog,
        };
        final manager = ListManager([], activeScopes: activeScopes);
        final lists = manager.allLists;

        expect(manager.allLists.length, activeScopes.length);
        expect(lists.first.scope, ListScope.daily);
        expect(lists[1].scope, ListScope.weekly);
        expect(lists[2].scope, ListScope.yearly);
        expect(lists.last.scope, ListScope.backlog);
      },
    );
  });

  group('test using mocks', () {
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

    group('ListManager getTodosToTransfer tests', () {
      test('ListManager getTodosToTransfer: from daily list', () {
        final dailyList = TodoList(ListScope.daily);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        dailyList.addTodo(todoToTransfer);
        dailyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ); // today
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.daily.duration); // tomorrow
        final manager = ListManager([dailyList]);

        expect(dailyList.todos.length, 2);
        expect(
          manager.getTodosToTransfer(dailyList.todos, ListScope.daily).length,
          1,
        );
      });

      test('ListManager getTodosToTransfer: from weekly list', () {
        final weeklyList = TodoList(ListScope.weekly);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        weeklyList.addTodo(todoToTransfer);
        weeklyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ); // today
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.daily.duration); // tomorrow
        final manager = ListManager([weeklyList]);

        expect(weeklyList.todos.length, 2);
        expect(
          manager.getTodosToTransfer(weeklyList.todos, ListScope.daily).length,
          1,
        );
      });

      test('ListManager getTodosToTransfer: from montly list', () {
        final monthlyList = TodoList(ListScope.monthly);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        monthlyList.addTodo(todoToTransfer);
        monthlyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 6)); // add weekly duration minus 1 day
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.weekly.duration); // add weekly duration
        final manager = ListManager([monthlyList]);

        expect(monthlyList.todos.length, 2);
        expect(
          manager
              .getTodosToTransfer(monthlyList.todos, ListScope.weekly)
              .length,
          1,
        );
      });

      test('ListManager getTodosToTransfer: from yearly list', () {
        final yearlyList = TodoList(ListScope.yearly);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        yearlyList.addTodo(todoToTransfer);
        yearlyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 29)); // add monthly duration minus 1 day
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.monthly.duration); // add monthly duration
        final manager = ListManager([yearlyList]);

        expect(yearlyList.todos.length, 2);
        expect(
          manager
              .getTodosToTransfer(yearlyList.todos, ListScope.monthly)
              .length,
          1,
        );
      });
    });

    group('ListManager transferTodos tests', () {
      test('ListManager transferTodos: from weekly to daily list', () {
        final transferFrom = TodoList(ListScope.weekly);
        final transferTo = TodoList(ListScope.daily);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        transferFrom.addTodo(todoToTransfer);
        transferFrom.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ); // today
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.daily.duration); // tomorrow

        var manager = ListManager([transferTo, transferFrom]);
        manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('ListManager transferTodos: from monthly to weekly list', () {
        final transferFrom = TodoList(ListScope.monthly);
        final transferTo = TodoList(ListScope.weekly);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        transferFrom.addTodo(todoToTransfer);
        transferFrom.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 6)); // add weekly duration minus 1 day
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.weekly.duration); // add weekly duration

        var manager = ListManager([transferTo, transferFrom]);
        manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('ListManager transferTodos: from yearly to monthly list', () {
        final transferFrom = TodoList(ListScope.yearly);
        final transferTo = TodoList(ListScope.monthly);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        transferFrom.addTodo(todoToTransfer);
        transferFrom.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 29)); // add monthly duration minus 1 day
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.monthly.duration); // add monthly duration

        var manager = ListManager([transferTo, transferFrom]);
        manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('ListManager transferTodos: todo stays in list', () {
        final transferFrom = TodoList(ListScope.weekly);
        final transferTo = TodoList(ListScope.daily);
        final todoNotToTransfer = Todo(title: 'do not transfer');
        transferFrom.addTodo(todoNotToTransfer);

        var manager = ListManager([transferTo, transferFrom]);
        manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferTo.todos.length, 0);
      });

      test(
        'ListManager transferTodos: no transfer from backlog to other list',
        () {
          final backlog = TodoList(ListScope.backlog);
          final transferTo = TodoList(ListScope.weekly);
          final backlogTodo = Todo(title: 'do not transfer');
          backlog.addTodo(backlogTodo);

          var manager = ListManager([transferTo, backlog]);
          manager.transferTodos();

          expect(backlog.todos.length, 1);
          expect(transferTo.todos.length, 0);
        },
      );

      test(
        'ListManager transferTodos: todos stay in dailyList but todo is expired',
        () {
          final weeklkyList = TodoList(ListScope.weekly);
          final dailyList = TodoList(ListScope.daily);
          var expiredTodo = Todo(title: 'expired todo');
          dailyList.addTodo(expiredTodo);
          final now = DateTime.now();
          final expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).subtract(Duration(days: 1));
          expiredTodo.expirationDate = expirationDate;

          var manager = ListManager([dailyList, weeklkyList]);
          manager.transferTodos();

          expect(weeklkyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
          expect(expiredTodo.expirationDate, expirationDate);
        },
      );

      test(
        'ListManager transferTodos: todo expired yesterday moves from highest scope to dailyList',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          var expiredTodo = Todo(title: 'expired todo');
          yearlyList.addTodo(expiredTodo);
          final now = DateTime.now();
          expiredTodo.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).subtract(Duration(days: 1));

          var manager = ListManager([
            dailyList,
            monthlyList,
            weeklyList,
            yearlyList,
          ]);
          manager.transferTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
        },
      );

      test(
        'ListManager transferTodos: todo expires in 6 days moves from highest scope to weekly',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          var todoToTransfer = Todo(title: 'expires in 6 days');
          yearlyList.addTodo(todoToTransfer);
          final now = DateTime.now();
          todoToTransfer.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).add(Duration(days: 6));

          var manager = ListManager([
            dailyList,
            monthlyList,
            weeklyList,
            yearlyList,
          ]);
          manager.transferTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 1);
          expect(dailyList.todos.length, 0);
        },
      );

      test('ListManager transferTodos: skip missing ListScope', () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final monthlyList = TodoList(ListScope.monthly);
        var todoToTransfer = Todo(title: 'expired today');
        monthlyList.addTodo(todoToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        );

        var manager = ListManager([dailyList, monthlyList, weeklyList]);
        manager.transferTodos();

        expect(monthlyList.todos.length, 0);
        expect(weeklyList.todos.length, 0);
        expect(dailyList.todos.length, 1);
      });
    });

    group('ListManager toBeTransferredTomorrow tests', () {
      test(
        'ListManager toBeTransferredTomorrow: todos from daily list are never transferred',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          final backlog = TodoList(ListScope.backlog);
          final todo_1 = Todo(title: 'todo 1');
          final todo_2 = Todo(title: 'todo 2');
          dailyList.addTodo(todo_1);
          dailyList.addTodo(todo_2);
          final now = DateTime.now();
          todo_1.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).add(Duration(days: 1)); // tomorrow
          todo_2.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).add(Duration(days: 2)); // day after tomorrow
          final manager = ListManager([
            dailyList,
            weeklyList,
            monthlyList,
            yearlyList,
            backlog,
          ]);
          expect(
            manager.toBeTransferredTomorrow(todo_1, ListScope.daily),
            false,
          );
          expect(
            manager.toBeTransferredTomorrow(todo_2, ListScope.daily),
            false,
          );
        },
      );

      test('ListManager toBeTransferredTomorrow: from weekly list', () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final monthlyList = TodoList(ListScope.monthly);
        final yearlyList = TodoList(ListScope.yearly);
        final backlog = TodoList(ListScope.backlog);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        weeklyList.addTodo(todoToTransfer);
        weeklyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.daily.duration); // tomorrow
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 2)); // day after tomorrow
        final manager = ListManager([
          dailyList,
          weeklyList,
          monthlyList,
          yearlyList,
          backlog,
        ]);

        expect(
          manager.toBeTransferredTomorrow(todoToTransfer, ListScope.weekly),
          true,
        );
        expect(
          manager.toBeTransferredTomorrow(todoNotToTransfer, ListScope.weekly),
          false,
        );
      });

      test('ListManager toBeTransferredTomorrow: from monthly list', () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final monthlyList = TodoList(ListScope.monthly);
        final yearlyList = TodoList(ListScope.yearly);
        final backlog = TodoList(ListScope.backlog);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        monthlyList.addTodo(todoToTransfer);
        monthlyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.weekly.duration); // in 7 days
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 8)); // in 8 days
        final manager = ListManager([
          dailyList,
          weeklyList,
          monthlyList,
          yearlyList,
          backlog,
        ]);

        expect(
          manager.toBeTransferredTomorrow(todoToTransfer, ListScope.monthly),
          true,
        );
        expect(
          manager.toBeTransferredTomorrow(todoNotToTransfer, ListScope.monthly),
          false,
        );
      });

      test('ListManager toBeTransferredTomorrow: from yearly list', () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final monthlyList = TodoList(ListScope.monthly);
        final yearlyList = TodoList(ListScope.yearly);
        final backlog = TodoList(ListScope.backlog);
        final todoToTransfer = Todo(title: 'transfer');
        final todoNotToTransfer = Todo(title: 'do not transfer');
        yearlyList.addTodo(todoToTransfer);
        yearlyList.addTodo(todoNotToTransfer);
        final now = DateTime.now();
        todoToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(ListScope.monthly.duration); // in 30 days
        todoNotToTransfer.expirationDate = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
          0,
        ).add(Duration(days: 31)); // in 31 days
        final manager = ListManager([
          dailyList,
          weeklyList,
          monthlyList,
          yearlyList,
          backlog,
        ]);

        expect(
          manager.toBeTransferredTomorrow(todoToTransfer, ListScope.yearly),
          true,
        );
        expect(
          manager.toBeTransferredTomorrow(todoNotToTransfer, ListScope.yearly),
          false,
        );
      });

      test(
        'ListManager toBeTransferredTomorrow: todos from backlog are never transferred',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          final backlog = TodoList(ListScope.backlog);
          final todo_1 = Todo(title: 'transfer');
          final todo_2 = Todo(title: 'do not transfer');
          backlog.addTodo(todo_1);
          backlog.addTodo(todo_2);
          final now = DateTime.now();
          todo_1.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).add(ListScope.yearly.duration); // in 365 days
          todo_2.expirationDate = DateTime(
            now.year,
            now.month,
            now.day,
            0,
            0,
            0,
          ).add(Duration(days: 366)); // in 366 days
          final manager = ListManager([
            dailyList,
            weeklyList,
            monthlyList,
            yearlyList,
            backlog,
          ]);

          expect(
            manager.toBeTransferredTomorrow(todo_1, ListScope.backlog),
            false,
          );
          expect(
            manager.toBeTransferredTomorrow(todo_2, ListScope.backlog),
            false,
          );
        },
      );
    });
  });
}
