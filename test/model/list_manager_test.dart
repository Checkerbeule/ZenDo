import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/persistence/file_lock_helper.dart';
import 'package:zen_do/persistence/persistence_helper.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  final className = 'ListManager';
  test('$className get allLists, returns sorted lists', () {
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
    final lists = manager.lists;

    expect(lists.first, dailyList);
    expect(lists[1], weeklyList);
    expect(lists[2], monthlyList);
    expect(lists[3], yearlyList);
    expect(lists.last, backlog);
  });

  test('$className initialize with no list, returns all empty lists', () {
    final manager = ListManager([]);
    final lists = manager.lists;

    expect(manager.lists.length, ListScope.values.length);
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
    '$className initialize wit no list and a set of ListTypes, returns all empty lists with the given ListType set',
    () {
      final activeScopes = <ListScope>{
        ListScope.daily,
        ListScope.weekly,
        ListScope.yearly,
        ListScope.backlog,
      };
      final manager = ListManager([], activeScopes: activeScopes);
      final lists = manager.lists;

      expect(manager.lists.length, activeScopes.length);
      expect(lists.first.scope, ListScope.daily);
      expect(lists[1].scope, ListScope.weekly);
      expect(lists[2].scope, ListScope.yearly);
      expect(lists.last.scope, ListScope.backlog);
    },
  );

  test('$className addList successfully', () {
    final dailyList = TodoList(ListScope.daily);
    final backlog = TodoList(ListScope.backlog);

    var manager = ListManager(
      [dailyList, backlog],
      activeScopes: {ListScope.daily, ListScope.backlog},
    );
    final monthlyListToAdd = TodoList(ListScope.monthly);
    final added = manager.addList(monthlyListToAdd);
    final lists = manager.lists;

    expect(added, isTrue);
    expect(lists.length, 3);
    expect(lists.first, dailyList);
    expect(lists[1], monthlyListToAdd);
    expect(lists.last, backlog);
  });

  test('$className addList with dublicate scope returns false ', () {
    final dailyList_1 = TodoList(ListScope.daily);
    final backlog = TodoList(ListScope.backlog);

    var manager = ListManager(
      [dailyList_1, backlog],
      activeScopes: {ListScope.daily, ListScope.backlog},
    );
    final dailyList_2 = TodoList(ListScope.daily);
    final added = manager.addList(dailyList_2);
    final lists = manager.lists;

    expect(added, isFalse);
    expect(lists.length, 2);
    expect(lists.first, dailyList_1);
    expect(lists.last, backlog);
  });

  test('$className getListByScope returns correct list', () {
    final manager = ListManager([]);

    final list = manager.getListByScope(ListScope.monthly);

    expect(list, isNotNull);
    expect(list!.scope, ListScope.monthly);
  });

  test('$className getListByScope returns null on nonexisting list', () {
    final manager = ListManager(
      [],
      activeScopes: {ListScope.daily, ListScope.backlog},
    );

    final list = manager.getListByScope(ListScope.monthly);

    expect(list, isNull);
  });

  group('$className getPreviousList getNextList tests', () {
    test('$className getPrevieousList returns correct list', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);
      final backlog = TodoList(ListScope.backlog);
      final activeScopes = {
        ListScope.daily,
        ListScope.weekly,
        ListScope.backlog,
      };
      final manager = ListManager([
        backlog,
        weeklyList,
        dailyList,
      ], activeScopes: activeScopes);

      final previousList = manager.getPreviousList(ListScope.weekly);

      expect(previousList, backlog);
    });

    test(
      '$className getPrevieousList returns null if current list is last list',
      () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final backlog = TodoList(ListScope.backlog);
        final activeScopes = {
          ListScope.daily,
          ListScope.weekly,
          ListScope.backlog,
        };
        final manager = ListManager([
          dailyList,
          weeklyList,
          backlog,
        ], activeScopes: activeScopes);

        final previousList = manager.getPreviousList(ListScope.backlog);

        expect(previousList, isNull);
      },
    );

    test('$className getNextList returns correct list', () {
      final dailyList = TodoList(ListScope.daily);
      final weeklyList = TodoList(ListScope.weekly);
      final backlog = TodoList(ListScope.backlog);
      final activeScopes = {
        ListScope.daily,
        ListScope.weekly,
        ListScope.backlog,
      };
      final manager = ListManager([
        backlog,
        weeklyList,
        dailyList,
      ], activeScopes: activeScopes);

      final previousList = manager.getNextList(ListScope.weekly);

      expect(previousList, dailyList);
    });

    test(
      '$className getNextList returns null if current list is first list',
      () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final backlog = TodoList(ListScope.backlog);
        final activeScopes = {
          ListScope.daily,
          ListScope.weekly,
          ListScope.backlog,
        };
        final manager = ListManager([
          dailyList,
          weeklyList,
          backlog,
        ], activeScopes: activeScopes);

        final previousList = manager.getNextList(ListScope.daily);

        expect(previousList, isNull);
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

    test(
      '$className isTodoTitleVacant returns false even with leading and tailing spaces',
      () {
        final dailyList = TodoList(ListScope.daily);
        final title = 'title';
        final todo = Todo(title: title);
        dailyList.addTodo(todo);
        final manager = ListManager([dailyList]);

        final isVacant = manager.isTodoTitleVacant(
          '   $title   ',
          ListScope.daily,
        );

        expect(isVacant, isFalse);
      },
    );

    group('$className getTodosToTransfer tests', () {
      test('$className getTodosToTransfer: from daily list', () {
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

      test('$className getTodosToTransfer: from weekly list', () {
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

      test('$className getTodosToTransfer: from montly list', () {
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

      test('$className getTodosToTransfer: from yearly list', () {
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

    group('$className transferTodos tests', () {
      test('$className transferTodos: from weekly to daily list', () async {
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
        await manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('$className transferTodos: from monthly to weekly list', () async {
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
        await manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('$className transferTodos: from yearly to monthly list', () async {
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
        await manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferFrom.todos.first, todoNotToTransfer);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, todoToTransfer);
      });

      test('$className transferTodos: todo stays in list', () async {
        final transferFrom = TodoList(ListScope.weekly);
        final transferTo = TodoList(ListScope.daily);
        final todoNotToTransfer = Todo(title: 'do not transfer');
        transferFrom.addTodo(todoNotToTransfer);

        var manager = ListManager([transferTo, transferFrom]);
        await manager.transferTodos();

        expect(transferFrom.todos.length, 1);
        expect(transferTo.todos.length, 0);
      });

      test(
        '$className transferTodos: no transfer from backlog to other list',
        () async {
          final backlog = TodoList(ListScope.backlog);
          final transferTo = TodoList(ListScope.weekly);
          final backlogTodo = Todo(title: 'do not transfer');
          backlog.addTodo(backlogTodo);

          var manager = ListManager([transferTo, backlog]);
          await manager.transferTodos();

          expect(backlog.todos.length, 1);
          expect(transferTo.todos.length, 0);
        },
      );

      test(
        '$className transferTodos: todos stay in dailyList but todo is expired',
        () async {
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
          await manager.transferTodos();

          expect(weeklkyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
          expect(expiredTodo.expirationDate, expirationDate);
        },
      );

      test(
        '$className transferTodos: todo expired yesterday moves from highest scope to dailyList',
        () async {
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
          await manager.transferTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
        },
      );

      test(
        '$className transferTodos: todo expires in 6 days moves from highest scope to weekly',
        () async {
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
          await manager.transferTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 1);
          expect(dailyList.todos.length, 0);
        },
      );

      test('$className transferTodos: skip missing ListScope', () async {
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
        await manager.transferTodos();

        expect(monthlyList.todos.length, 0);
        expect(weeklyList.todos.length, 0);
        expect(dailyList.todos.length, 1);
      });
    });

    group('$className toBeTransferredTomorrow tests', () {
      test(
        '$className toBeTransferredTomorrow: todos from daily list are never transferred',
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
          expect(manager.toBeTransferredTomorrow(todo_1), false);
          expect(manager.toBeTransferredTomorrow(todo_2), false);
        },
      );

      test('$className toBeTransferredTomorrow: from weekly list', () {
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

        expect(manager.toBeTransferredTomorrow(todoToTransfer), true);
        expect(manager.toBeTransferredTomorrow(todoNotToTransfer), false);
      });

      test('$className toBeTransferredTomorrow: from monthly list', () {
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

        expect(manager.toBeTransferredTomorrow(todoToTransfer), true);
        expect(manager.toBeTransferredTomorrow(todoNotToTransfer), false);
      });

      test('$className toBeTransferredTomorrow: from yearly list', () {
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

        expect(manager.toBeTransferredTomorrow(todoToTransfer), true);
        expect(manager.toBeTransferredTomorrow(todoNotToTransfer), false);
      });

      test(
        '$className toBeTransferredTomorrow: todos from backlog are never transferred',
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

          expect(manager.toBeTransferredTomorrow(todo_1), false);
          expect(manager.toBeTransferredTomorrow(todo_2), false);
        },
      );
    });

    group('$className move todo tests', () {
      test('$className moveToNextList sucessfully', () async {
        final manager = ListManager([]);
        final todo = Todo(title: 'todo to move to next list');
        manager.getListByScope(ListScope.monthly)!.addTodo(todo);

        final moved = await manager.moveToNextList(todo);

        expect(moved, isTrue);
        expect(manager.getListByScope(ListScope.monthly)!.todos.length, 0);
        expect(manager.getListByScope(ListScope.weekly)!.todos.length, 1);
        expect(manager.getListByScope(ListScope.weekly)!.todos.first, todo);
      });

      test(
        '$className moveToNextList not possible if todo allready exists in destination list',
        () async {
          final manager = ListManager([]);
          final title = 'todo to move to next list';
          final todo_1 = Todo(title: title);
          final todo_2 = Todo(title: title);
          manager.getListByScope(ListScope.monthly)!.addTodo(todo_1);
          manager.getListByScope(ListScope.weekly)!.addTodo(todo_2);

          final moved = await manager.moveToNextList(todo_1);

          expect(moved, isFalse);
          expect(manager.getListByScope(ListScope.monthly)!.todos.length, 1);
          expect(
            manager.getListByScope(ListScope.monthly)!.todos.first,
            todo_1,
          );
          expect(manager.getListByScope(ListScope.weekly)!.todos.length, 1);
          expect(manager.getListByScope(ListScope.weekly)!.todos.first, todo_2);
        },
      );

      test('$className moveToPreviousList sucessfully', () async {
        final manager = ListManager([]);
        final todo = Todo(title: 'todo to move to next list');
        manager.getListByScope(ListScope.daily)!.addTodo(todo);

        final moved = await manager.moveToPreviousList(todo);

        expect(moved, isTrue);
        expect(manager.getListByScope(ListScope.daily)!.todos.length, 0);
        expect(manager.getListByScope(ListScope.weekly)!.todos.length, 1);
        expect(manager.getListByScope(ListScope.weekly)!.todos.first, todo);
      });

      test(
        '$className moveToPreviousList not possible if todo allready exists in destination list',
        () async {
          final manager = ListManager([]);
          final title = 'todo to move to next list';
          final todo_1 = Todo(title: title);
          final todo_2 = Todo(title: title);
          manager.getListByScope(ListScope.daily)!.addTodo(todo_1);
          manager.getListByScope(ListScope.weekly)!.addTodo(todo_2);

          final moved = await manager.moveToPreviousList(todo_1);

          expect(moved, isFalse);
          expect(manager.getListByScope(ListScope.daily)!.todos.length, 1);
          expect(manager.getListByScope(ListScope.daily)!.todos.first, todo_1);
          expect(manager.getListByScope(ListScope.weekly)!.todos.length, 1);
          expect(manager.getListByScope(ListScope.weekly)!.todos.first, todo_2);
        },
      );

      test('$className moveAndUpdateTodo sucessfully moves todo', () async {
        final manager = ListManager([]);
        final todo = Todo(title: 'todo to move to next list');
        manager.getListByScope(ListScope.daily)!.addTodo(todo);
        final now = DateTime.now();
        final expectedDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: 365));

        final moved = await manager.moveAndUpdateTodo(
          todo: todo,
          destination: ListScope.yearly,
        );

        expect(moved, isTrue);
        expect(manager.getListByScope(ListScope.daily)!.todos.length, 0);
        expect(manager.getListByScope(ListScope.yearly)!.todos.length, 1);
        expect(manager.getListByScope(ListScope.yearly)!.todos.first, todo);
        expect(
          manager.getListByScope(ListScope.yearly)!.todos.first.expirationDate,
          expectedDate,
        );
      });

      test(
        '$className moveAndUpdateTodo sucessfully moves updated todo',
        () async {
          final manager = ListManager([]);
          final todo = Todo(title: 'todo to move to next list');
          manager.getListByScope(ListScope.daily)!.addTodo(todo);
          final updatedTodo = todo.copyWith(
            title: 'updated title',
            description: 'updated description',
          );

          final moved = await manager.moveAndUpdateTodo(
            oldTodo: todo,
            todo: updatedTodo,
            destination: ListScope.yearly,
          );

          expect(moved, isTrue);
          expect(manager.getListByScope(ListScope.daily)!.todos.length, 0);
          expect(manager.getListByScope(ListScope.yearly)!.todos.length, 1);
          expect(
            manager.getListByScope(ListScope.yearly)!.todos.first,
            updatedTodo,
          );
        },
      );

      test(
        '$className moveAndUpdateTodo not possible if destination list does not exist',
        () async {
          final manager = ListManager(
            [],
            activeScopes: {
              ListScope.daily,
              ListScope.weekly,
              ListScope.yearly,
              ListScope.backlog,
            },
          );
          final todo = Todo(title: 'todo to move to next list');
          manager.getListByScope(ListScope.daily)!.addTodo(todo);

          final moved = await manager.moveAndUpdateTodo(
            todo: todo,
            destination: ListScope.monthly,
          );

          expect(moved, isFalse);
          expect(manager.getListByScope(ListScope.daily)!.todos.length, 1);
        },
      );
    });
  });
}
