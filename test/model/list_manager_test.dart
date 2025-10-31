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

    group('ListManager expiredTodos tests', () {
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
        final manager = ListManager([weeklyList]);

        expect(
          manager.getExpiredTodos(weeklyList.todos, ListScope.daily).length,
          2,
        );
      });
    });

    group('ListManager transferExpiredTodos tests', () {
      test('ListManager transferExpiredTodos from weekly to daily list', () {
        final transferFrom = TodoList(ListScope.weekly);
        final transferTo = TodoList(ListScope.daily);
        var expiredTodo = Todo('expired todo');
        transferFrom.addTodo(expiredTodo);
        expiredTodo.expirationDate = DateTime.now().subtract(Duration(days: 7));

        var manager = ListManager([transferTo, transferFrom]);
        manager.transferExpiredTodos();

        expect(transferFrom.todos.length, 0);
        expect(transferTo.todos.length, 1);
        expect(transferTo.todos.first, expiredTodo);
      });

      test(
        'ListManager transferExpiredTodos none expired todo stay in list',
        () {
          final transferFrom = TodoList(ListScope.weekly);
          final transferTo = TodoList(ListScope.daily);
          final noneExpiredTodo = Todo('expired title');
          transferFrom.addTodo(noneExpiredTodo);

          var manager = ListManager([transferTo, transferFrom]);
          manager.transferExpiredTodos();

          expect(transferFrom.todos.length, 1);
          expect(transferTo.todos.length, 0);
        },
      );

      test(
        'ListManager transferExpiredTodos, no transfer from backlog to other list',
        () {
          final backlog = TodoList(ListScope.backlog);
          final transferTo = TodoList(ListScope.weekly);
          final todo = Todo('todo title');
          backlog.addTodo(todo);

          var manager = ListManager([transferTo, backlog]);
          manager.transferExpiredTodos();

          expect(backlog.todos.length, 1);
          expect(transferTo.todos.length, 0);
        },
      );

      test(
        'ListManager transferExpiredTodos todos stay in dailyList but todo is expired',
        () {
          final weeklkyList = TodoList(ListScope.weekly);
          final dailyList = TodoList(ListScope.daily);
          var expiredTodo = Todo('expired todo');
          dailyList.addTodo(expiredTodo);
          DateTime expirationDate = DateTime.now().subtract(Duration(days: 1));
          expiredTodo.expirationDate = expirationDate;

          var manager = ListManager([dailyList, weeklkyList]);
          manager.transferExpiredTodos();

          expect(weeklkyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
          expect(expiredTodo.expirationDate, expirationDate);
        },
      );

      test(
        'ListManager transferExpiredTodos todo expired yesterday moves from highes scope to dailyList',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          var expiredTodo = Todo('expired todo');
          yearlyList.addTodo(expiredTodo);
          expiredTodo.expirationDate = DateTime.now().subtract(
            Duration(days: 1),
          );

          var manager = ListManager([
            dailyList,
            monthlyList,
            weeklyList,
            yearlyList,
          ]);
          manager.transferExpiredTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 0);
          expect(dailyList.todos.length, 1);
        },
      );

      test(
        'ListManager transferExpiredTodos todo expires in 7 days moves from highes scope to weekly',
        () {
          final dailyList = TodoList(ListScope.daily);
          final weeklyList = TodoList(ListScope.weekly);
          final monthlyList = TodoList(ListScope.monthly);
          final yearlyList = TodoList(ListScope.yearly);
          var expiredTodo = Todo('expired in 7 days');
          yearlyList.addTodo(expiredTodo);
          expiredTodo.expirationDate = DateTime.now().add(Duration(days: 7));

          var manager = ListManager([
            dailyList,
            monthlyList,
            weeklyList,
            yearlyList,
          ]);
          manager.transferExpiredTodos();

          expect(yearlyList.todos.length, 0);
          expect(monthlyList.todos.length, 0);
          expect(weeklyList.todos.length, 1);
          expect(dailyList.todos.length, 0);
        },
      );

      test('ListManager transferExpiredTodos and skip missing ListScope', () {
        final dailyList = TodoList(ListScope.daily);
        final weeklyList = TodoList(ListScope.weekly);
        final monthlyList = TodoList(ListScope.monthly);
        var expiredTodo = Todo('expired today');
        monthlyList.addTodo(expiredTodo);
        expiredTodo.expirationDate = DateTime.now();

        var manager = ListManager([dailyList, monthlyList, weeklyList]);
        manager.transferExpiredTodos();

        expect(monthlyList.todos.length, 0);
        expect(weeklyList.todos.length, 0);
        expect(dailyList.todos.length, 1);
      });
    });
  });
}
