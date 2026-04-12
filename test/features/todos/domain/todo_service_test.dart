import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/domain/todo_service.dart';

class SettingsServiceMock extends Mock implements AppSettingsService {}

void main() {
  late AppDatabase db;
  late TodoService todoService;
  late EntityRepository entityRepo;
  late TodoRepository todoRepo;
  late TagRepository tagRepo;
  late TodoTagsRepository todoTagsRepo;
  late SettingsServiceMock settingsServiceMock;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    todoRepo = TodoRepository(db);
    entityRepo = EntityRepository(db);
    todoTagsRepo = TodoTagsRepository(db);
    tagRepo = TagRepository(db);
    settingsServiceMock = SettingsServiceMock();

    todoService = TodoService(
      todoRepo: todoRepo,
      entityRepo: entityRepo,
      todoTagsRepo: todoTagsRepo,
      tagRepo: tagRepo,
      settingsService: settingsServiceMock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Todo> setupTodo({
    required String title,
    required ListScope scope,
    String? description,
    DateTime? expiry,
  }) async {
    return await entityRepo.createWithEntity(EntityType.todo, (Entity e) async {
      return todoRepo.create(
        uuid: e.uuid,
        title: title,
        scope: scope,
        description: description,
        expiresAt: expiry,
      );
    });
  }

  test('TodoService create successfully', () async {
    final tag_1 = await entityRepo.createWithEntity(EntityType.tag, (
      Entity e,
    ) async {
      return await tagRepo.create(
        uuid: e.uuid,
        name: 'Test Tag 1',
        color: Colors.red.toARGB32(),
      );
    });
    final tag_2 = await entityRepo.createWithEntity(EntityType.tag, (
      Entity e,
    ) async {
      return await tagRepo.create(
        uuid: e.uuid,
        name: 'Test Tag 2',
        color: Colors.green.toARGB32(),
      );
    });

    final dto = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.daily,
      description: 'Desc',
      tagUuids: {tag_1.uuid, tag_2.uuid},
    );

    final todo = await todoRepo.read(dto.uuid);
    final todoTags = await todoTagsRepo.readTagsFromTodo(dto.uuid);
    expect(dto.title, 'Test Todo');
    expect(dto.description, 'Desc');
    expect(dto.scope, ListScope.daily);
    expect(dto.expiresAt, isNotNull);
    expect(dto.createdAt, isNotNull);
    expect(dto.hasTags, isTrue);
    expect(dto.isCompleted, isFalse);
    expect(dto.completedAt, isNull);
    expect(dto.customOrder, 'a0');
    expect(todo, isNotNull);
    expect(todo!.uuid, dto.uuid);
    expect(todoTags.length, 2);
    expect(todoTags.contains(tag_1), isTrue);
    expect(todoTags.contains(tag_2), isTrue);
  });

  test('TodoService create successfully calculates expiresAt date', () async {
    final dailyTodo = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.daily,
    );
    final weeklyTodo = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.weekly,
    );
    final monthlyTodo = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.monthly,
    );
    final yearlyTodo = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.yearly,
    );
    final backlogTodo = await todoService.create(
      title: 'Test Todo',
      scope: ListScope.backlog,
    );

    final now = DateTime.now();
    expect(dailyTodo.expiresAt, now.add(Duration(days: 1)).endOfDay);
    expect(weeklyTodo.expiresAt, now.add(Duration(days: 7)).endOfDay);
    expect(monthlyTodo.expiresAt, now.add(Duration(days: 30)).endOfDay);
    expect(yearlyTodo.expiresAt, now.add(Duration(days: 365)).endOfDay);
    expect(backlogTodo.expiresAt, isNull);
  });

  group('TodoService watchAllOpendByScope tests', () {
    test(
      'TodoService watchAllOpendByScope successfully retreives open todos',
      () async {
        final openTodo = await todoService.create(
          title: 'Open Todo',
          scope: ListScope.daily,
        );
        final completedTodo = await todoService.create(
          title: 'Comleted Todo',
          scope: ListScope.daily,
        );
        await todoService.create(title: 'Weekly Todo', scope: ListScope.weekly);
        todoService.markAsCompleted(completedTodo.uuid);

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;

        expect(openTodos.length, 1);
        expect(openTodos.first.title, openTodo.title);
        expect(openTodos.first.uuid, openTodo.uuid);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with daily scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(Set<ListScope>.from(ListScope.values));
        final expired = await todoService.create(
          title: 'Expired Todo',
          scope: ListScope.daily,
        );
        await todoService.create(
          title: 'Not expired Todo',
          scope: ListScope.daily,
        );
        await todoRepo.updateDto(
          expired.copyWith(
            expiresAt: DateTime.now().endOfDay.subtract(Duration(days: 1)),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.willBeTransferred, isTrue);
        expect(openTodos.last.willBeTransferred, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with weekly scope',
      () async {
        // --- Arrange ---
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(Set<ListScope>.from(ListScope.values));
        final expired = await todoService.create(
          title: 'Expired Todo',
          scope: ListScope.weekly,
        );
        await todoService.create(
          title: 'Not expired Todo',
          scope: ListScope.weekly,
        );
        await todoRepo.updateDto(
          expired.copyWith(
            expiresAt: DateTime.now().endOfDay.add(ListScope.daily.duration),
          ),
        );

        // --- Act ---
        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.weekly)
            .first;

        // --- Assert ---
        expect(openTodos, hasLength(2));
        expect(openTodos.first.willBeTransferred, isTrue);
        expect(openTodos.last.willBeTransferred, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with monthly scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(Set<ListScope>.from(ListScope.values));
        final expired = await todoService.create(
          title: 'Expired Todo',
          scope: ListScope.monthly,
        );
        await todoService.create(
          title: 'Not expired Todo',
          scope: ListScope.monthly,
        );
        await todoRepo.updateDto(
          expired.copyWith(
            expiresAt: DateTime.now().endOfDay.add(ListScope.weekly.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.monthly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.willBeTransferred, isTrue);
        expect(openTodos.last.willBeTransferred, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with yearly scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(Set<ListScope>.from(ListScope.values));
        final expired = await todoService.create(
          title: 'Expired Todo',
          scope: ListScope.yearly,
        );
        await todoService.create(
          title: 'Not expired Todo',
          scope: ListScope.yearly,
        );
        await todoRepo.updateDto(
          expired.copyWith(
            expiresAt: DateTime.now().endOfDay.add(ListScope.monthly.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.willBeTransferred, isTrue);
        expect(openTodos.last.willBeTransferred, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with backlog scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(Set<ListScope>.from(ListScope.values));
        final backlogTodo = await todoService.create(
          title: 'Backlog Todo',
          scope: ListScope.backlog,
        );
        final backlogButExpired = await todoService.create(
          title: 'Backlog Todo is expired',
          scope: ListScope.backlog,
        );
        await todoRepo.updateDto(
          backlogTodo.copyWith(
            expiresAt: DateTime.now().endOfDay.add(ListScope.yearly.duration),
          ),
        );
        await todoRepo.updateDto(
          backlogButExpired.copyWith(
            expiresAt: DateTime.now().endOfDay.subtract(Duration(days: 1)),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.backlog)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.willBeTransferred, isFalse);
        expect(openTodos.last.willBeTransferred, isTrue);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets willBeTransferred on todos with yearly scope with inactive monthly scope',
      () async {
        final activeScopes = Set<ListScope>.from(ListScope.values)
          ..remove(ListScope.monthly);
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(activeScopes);
        final expired = await todoService.create(
          title: 'Expired Todo',
          scope: ListScope.yearly,
        );
        await todoService.create(
          title: 'Not expired Todo',
          scope: ListScope.yearly,
        );
        await todoRepo.updateDto(
          expired.copyWith(
            expiresAt: DateTime.now().endOfDay.add(ListScope.weekly.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.willBeTransferred, isTrue);
        expect(openTodos.last.willBeTransferred, isFalse);
      },
    );
  });

  test(
    'TodoService watchAllCompletedByScope successfully retreives completed todos',
    () async {
      await todoService.create(title: 'Open Todo', scope: ListScope.daily);
      final completedTodo = await todoService.create(
        title: 'Comleted Todo',
        scope: ListScope.daily,
      );
      await todoService.create(title: 'Weekly Todo', scope: ListScope.weekly);
      todoService.markAsCompleted(completedTodo.uuid);

      final completedTodos = await todoService
          .watchAllCompletedByScope(scope: ListScope.daily)
          .first;

      expect(completedTodos.length, 1);
      expect(completedTodos.first.title, completedTodo.title);
      expect(completedTodos.first.uuid, completedTodo.uuid);
    },
  );

  test(
    'TodoService watchWillBeTransfered successfully retreives count of todos that will be transfered tomorrow or are expired',
    () async {
      // --- Arrange ---
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(Set<ListScope>.from(ListScope.values));
      final expiredTodo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'Expired',
          scope: ListScope.weekly,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      (db.update(
        db.todos,
      )..where((t) => db.todos.uuid.equals(expiredTodo.uuid))).write(
        TodosCompanion(
          expiresAt: Value(DateTime.now().subtract(Duration(days: 1)).endOfDay),
        ),
      );
      final willBeTransfered = await entityRepo.createWithEntity(
        EntityType.todo,
        (Entity entity) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Transfered',
            scope: ListScope.weekly,
            expiresAt: DateTime.now().toUtc(),
          );
        },
      );
      (db.update(
        db.todos,
      )..where((t) => db.todos.uuid.equals(willBeTransfered.uuid))).write(
        TodosCompanion(
          expiresAt: Value(
            DateTime.now().add(ListScope.daily.duration).endOfDay,
          ),
        ),
      );
      final notTransfered = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'Not transfered',
          scope: ListScope.weekly,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      (db.update(
        db.todos,
      )..where((t) => db.todos.uuid.equals(notTransfered.uuid))).write(
        TodosCompanion(
          expiresAt: Value(DateTime.now().add(Duration(days: 2)).endOfDay),
        ),
      );

      // --- Act ---
      final completedTodos = await todoService
          .watchWillBeTransfered(ListScope.weekly)
          .first;

      // --- Assert ---
      expect(completedTodos, 2);
    },
  );

  test('TodoService watchExpiredCount ignores inactive ListScopes', () async {
    final activeScopes = Set<ListScope>.from(ListScope.values)
      ..remove(ListScope.monthly);
    when(
      () => settingsServiceMock.getActiveListScopes(),
    ).thenReturn(activeScopes);
    final expiredTodo = await entityRepo.createWithEntity(EntityType.todo, (
      Entity e,
    ) async {
      return await todoRepo.create(
        uuid: e.uuid,
        title: 'Expired but in inactive scope',
        scope: ListScope.monthly,
      );
    });
    final expirationDate = DateTime.now().subtract(Duration(days: 1));
    await (db.update(db.todos)..where((t) => t.uuid.isIn([expiredTodo.uuid])))
        .write(TodosCompanion(expiresAt: Value(expirationDate)));

    final expiredCount = await todoService.watchExpiredCount().first;

    expect(expiredCount, 0);
  });

  test(
    'TodoService update successfully updates with new updatedAt timestamp',
    () async {
      // --- Arrange ----
      final todo = await todoService.create(
        title: 'Test todo',
        scope: ListScope.monthly,
      );

      // --- Act ---
      final updated = await todoService.update(
        todo.copyWith(title: 'New title'),
      );

      // --- Assert ---
      final loadedTodo = await todoRepo.read(todo.uuid);
      final entity = await entityRepo.read(todo.uuid);
      expect(updated, isTrue);
      expect(loadedTodo!.title, 'New title');
      expect(entity!.updatedAt.isAfter(entity.createdAt), isTrue);
    },
  );

  test(
    'TodoService markAsCompleted successfully updates updatedAt timestamp',
    () async {
      final todo = await todoService.create(
        title: 'Test todo',
        scope: ListScope.daily,
      );

      await todoService.markAsCompleted(todo.uuid);

      final entity = await entityRepo.read(todo.uuid);
      final loadedTodo = await todoRepo.read(todo.uuid);
      expect(loadedTodo!.completedAt, isNotNull);
      expect(entity!.updatedAt.isAfter(entity.createdAt), isTrue);
    },
  );

  test(
    'TodoService restore successfully updates updatedAt timestamp',
    () async {
      // --- Arrange ---
      final todo = await todoService.create(
        title: 'Test todo',
        scope: ListScope.daily,
      );
      await todoService.markAsCompleted(todo.uuid);
      final updatedAtAfterCompleted = (await entityRepo.read(
        todo.uuid,
      ))!.updatedAt;

      // --- Act ---
      final restored = await todoService.restore(todo.uuid);

      final entity = await entityRepo.read(todo.uuid);
      final loadedTodo = await todoRepo.read(todo.uuid);
      expect(restored, isTrue);
      expect(loadedTodo!.completedAt, isNull);
      expect(entity!.updatedAt.isAfter(updatedAtAfterCompleted), isTrue);
    },
  );

  group('TodoService transferTodos tests', () {
    setUp(() {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(ListScope.values.toSet());
    });

    test('TodoService transferTodos: from weekly to daily list', () async {
      // --- Arrange ---
      final todoToTransfer = await setupTodo(
        title: 'transfer',
        scope: ListScope.weekly,
        expiry: DateTime.now().endOfDay,
      );
      final todoNotToTransfer = await setupTodo(
        title: 'do not transfer',
        scope: ListScope.weekly,
        expiry: DateTime.now().endOfDay.add(ListScope.daily.duration),
      );

      // --- Act ---
      await todoService.transferTodos();

      // --- Assert ---
      final dailyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.daily)
          .first;
      expect(dailyTodos, hasLength(1));
      expect(dailyTodos.first.uuid, todoToTransfer.uuid);

      final weeklyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.weekly)
          .first;
      expect(weeklyTodos, hasLength(1));
      expect(weeklyTodos.first.uuid, todoNotToTransfer.uuid);
    });

    test('TodoService transferTodos: from monthly to weekly list', () async {
      // --- Arrange ---
      final todoToTransfer = await setupTodo(
        title: 'transfer',
        scope: ListScope.monthly,
        expiry: DateTime.now().endOfDay.add(Duration(days: 6)),
      );
      final todoNotToTransfer = await setupTodo(
        title: 'do not transfer',
        scope: ListScope.monthly,
        expiry: DateTime.now().endOfDay.add(ListScope.weekly.duration),
      );

      // --- Act ---
      await todoService.transferTodos();

      // --- Assert ---
      final weeklyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.weekly)
          .first;
      expect(weeklyTodos, hasLength(1));
      expect(weeklyTodos.first.uuid, todoToTransfer.uuid);

      final monthlyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.monthly)
          .first;
      expect(monthlyTodos, hasLength(1));
      expect(monthlyTodos.first.uuid, todoNotToTransfer.uuid);
    });

    test('TodoService transferTodos: from yearly to monthly list', () async {
      // --- Arrange ---
      final todoToTransfer = await setupTodo(
        title: 'transfer',
        scope: ListScope.yearly,
        expiry: DateTime.now().endOfDay.add(Duration(days: 29)),
      );
      final todoNotToTransfer = await setupTodo(
        title: 'do not transfer',
        scope: ListScope.yearly,
        expiry: DateTime.now().endOfDay.add(ListScope.monthly.duration),
      );

      // --- Act ---
      await todoService.transferTodos();

      // --- Assert ---
      final monthlyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.monthly)
          .first;
      expect(monthlyTodos, hasLength(1));
      expect(monthlyTodos.first.uuid, todoToTransfer.uuid);

      final yearlyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.yearly)
          .first;
      expect(yearlyTodos, hasLength(1));
      expect(yearlyTodos.first.uuid, todoNotToTransfer.uuid);
    });

    test(
      'TodoServcie transferTodos: no transfer from backlog to other list',
      () async {
        // --- Arrange ---
        final backlogTodo = await setupTodo(
          title: 'do not transfer',
          scope: ListScope.backlog,
        );

        // --- Act ---
        await todoService.transferTodos();

        // --- Assert ---
        final backlogTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.backlog)
            .first;
        expect(backlogTodos, hasLength(1));
        expect(backlogTodos.first.uuid, backlogTodo.uuid);
      },
    );

    test(
      'TodoService transferTodos: expired todos stay in daily list',
      () async {
        // --- Arrange ---
        final expiredDailyTodo = await setupTodo(
          title: 'do not transfer',
          scope: ListScope.daily,
          expiry: DateTime.now().endOfDay.subtract(Duration(days: 1)),
        );

        // --- Act ---
        await todoService.transferTodos();

        // --- Assert ---
        final dailyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;
        expect(dailyTodos, hasLength(1));
        expect(dailyTodos.first.uuid, expiredDailyTodo.uuid);
      },
    );

    test(
      'TodoService transferTodos: expired todo moves from highest scope to lowest scope',
      () async {
        // --- Arrange ---
        final todoToTransfer = await setupTodo(
          title: 'transfer',
          scope: ListScope.yearly,
          expiry: DateTime.now().endOfDay.subtract(Duration(days: 1)),
        );

        // --- Act ---
        await todoService.transferTodos();

        // --- Assert ---
        final yearlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;
        expect(yearlyTodos, isEmpty);

        final dailyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;
        expect(dailyTodos, hasLength(1));
        expect(dailyTodos.first.uuid, todoToTransfer.uuid);
      },
    );

    test(
      'TodoService transferTodos: todo expires in 6 days moves from highest scope to weekly',
      () async {
        // --- Arrange ---
        final todoToTransfer = await setupTodo(
          title: 'transfer',
          scope: ListScope.yearly,
          expiry: DateTime.now().endOfDay.add(Duration(days: 6)),
        );

        // --- Act ---
        await todoService.transferTodos();

        // --- Assert ---
        final yearlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;
        expect(yearlyTodos, isEmpty);

        final weeklyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.weekly)
            .first;
        expect(weeklyTodos, hasLength(1));
        expect(weeklyTodos.first.uuid, todoToTransfer.uuid);
      },
    );

    test(
      'TodoService transferTodos: skip or ignore missing ListScope',
      () async {
        // --- Arrange ---
        final activeScopes = ListScope.values.toSet()
          ..remove(ListScope.monthly);
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(activeScopes);

        final todoToTransfer = await setupTodo(
          title: 'transfer',
          scope: ListScope.yearly,
          expiry: DateTime.now().endOfDay.add(Duration(days: 6)),
        );
        final todoNotToTransfer = await setupTodo(
          title: 'transfer',
          scope: ListScope.yearly,
          expiry: DateTime.now().endOfDay.add(Duration(days: 7)),
        );

        // --- Act ---
        await todoService.transferTodos();

        // --- Assert ---
        final yearlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;
        expect(yearlyTodos, hasLength(1));
        expect(yearlyTodos.first.uuid, todoNotToTransfer.uuid);

        final weeklyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.weekly)
            .first;
        expect(weeklyTodos, hasLength(1));
        expect(weeklyTodos.first.uuid, todoToTransfer.uuid);
      },
    );
  });

  group('TodoService calcFittingScope tests', () {
    setUp(() {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(ListScope.values.toSet());
    });

    test('TodoService calcFittingScope today fits daily list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(DateTime.now().endOfDay);

      // --- Assert ---
      expect(scope, ListScope.daily);
    });

    test('TodoService calcFittingScope tomorrow fits daily list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(Duration(days: 1)).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.daily);
    });

    test('TodoService calcFittingScope date fits weekly list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(ListScope.weekly.duration).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.weekly);
    });

    test('TodoService calcFittingScope date fits monthly list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now()
            .add(ListScope.weekly.duration)
            .add(Duration(days: 1))
            .endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.monthly);
    });

    test('TodoService calcFittingScope date fits monthly list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(ListScope.monthly.duration).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.monthly);
    });

    test('TodoService calcFittingScope date fits yearly list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now()
            .add(ListScope.monthly.duration)
            .add(Duration(days: 1))
            .endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.yearly);
    });

    test('TodoService calcFittingScope date fits yearly list', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(ListScope.yearly.duration).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.yearly);
    });

    test('TodoService calcFittingScope date fits backlog', () {
      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(Duration(days: 366)).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.backlog);
    });

    test('TodoService calcFittingScope skips none active scope', () {
      // --- Arrange ---
      final activeScopes = ListScope.values.toSet()..remove(ListScope.weekly);
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(activeScopes);

      // --- Act ---
      final scope = todoService.calcFittingScope(
        DateTime.now().add(Duration(days: 3)).endOfDay,
      );

      // --- Assert ---
      expect(scope, ListScope.monthly);
    });

    test(
      'TodoService calcFittingScope returns null if no fitting scope exists',
      () {
        // --- Arrange ---
        final activeScopes = ListScope.values.toSet()
          ..remove(ListScope.backlog);
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(activeScopes);

        // --- Act ---
        final scope = todoService.calcFittingScope(
          DateTime.now().add(Duration(days: 400)).endOfDay,
        );

        // --- Assert ---
        expect(scope, null);
      },
    );
  });

  group('TodoService moveToOtherList tests', () {
    test(
      'TodoService moveToOtherList successfully sets destination scope and updates timestamp',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(ListScope.values.toSet());
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.daily,
        );

        final moved = await todoService.moveToOtherList(todo, ListScope.yearly);

        final dailyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;
        final yearlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;
        final entity = await entityRepo.read(todo.uuid);
        expect(moved, isTrue);
        expect(dailyTodos.length, 0);
        expect(yearlyTodos.length, 1);
        expect(yearlyTodos.first.uuid, todo.uuid);
        expect(entity!.updatedAt.isAfter(entity.createdAt), isTrue);
      },
    );
    test(
      'TodoService moveToOtherList fails when destination scope is not active',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn({ListScope.daily});
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.daily,
        );

        final moved = await todoService.moveToOtherList(todo, ListScope.yearly);

        final dailyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;
        expect(moved, isFalse);
        expect(dailyTodos.length, 1);
      },
    );

    test('TodoService moveToNextList successfully sets next scope', () async {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(ListScope.values.toSet());
      final todo = await todoService.create(
        title: 'Test todo',
        scope: ListScope.monthly,
      );

      final moved = await todoService.moveToNextList(todo);

      final monthlyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.monthly)
          .first;
      final weeklyTodos = await todoService
          .watchAllOpenByScope(scope: ListScope.weekly)
          .first;
      expect(moved, isTrue);
      expect(monthlyTodos.length, 0);
      expect(weeklyTodos.length, 1);
      expect(weeklyTodos.first.uuid, todo.uuid);
    });

    test(
      'TodoService moveToNextList fails when origin scope is daily scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(ListScope.values.toSet());
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.daily,
        );

        final moved = await todoService.moveToNextList(todo);

        final dailyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;
        expect(moved, isFalse);
        expect(dailyTodos.length, 1);
      },
    );

    test(
      'TodoService moveToPreviousList fails when origin scope is first scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn({ListScope.weekly});
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.weekly,
        );

        final moved = await todoService.moveToPreviousList(todo);

        final weeklyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.weekly)
            .first;
        expect(moved, isFalse);
        expect(weeklyTodos.length, 1);
      },
    );

    test(
      'TodoService moveToPreviousList successfully sets previous scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(ListScope.values.toSet());
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.monthly,
        );

        final moved = await todoService.moveToPreviousList(todo);

        final monthlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.monthly)
            .first;
        final yearlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;
        expect(moved, isTrue);
        expect(monthlyTodos.length, 0);
        expect(yearlyTodos.length, 1);
        expect(yearlyTodos.first.uuid, todo.uuid);
      },
    );

    test(
      'TodoService moveToPreviousList fails when origin scope is backlog scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn(ListScope.values.toSet());
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.backlog,
        );

        final moved = await todoService.moveToPreviousList(todo);

        final backlogTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.backlog)
            .first;
        expect(moved, isFalse);
        expect(backlogTodos.length, 1);
      },
    );

    test(
      'TodoService moveToPreviousList fails when origin scope is last scope',
      () async {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn({ListScope.monthly});
        final todo = await todoService.create(
          title: 'Test todo',
          scope: ListScope.monthly,
        );

        final moved = await todoService.moveToPreviousList(todo);

        final monthlyTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.monthly)
            .first;
        expect(moved, isFalse);
        expect(monthlyTodos.length, 1);
      },
    );
  });

  group('TodoService getPreviousScope getNextScope tests', () {
    test('TodoService getPrevieousList returns correct list', () {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(ListScope.values.toSet());

      final weekly = todoService.getPreviousScope(ListScope.daily);
      final monthly = todoService.getPreviousScope(ListScope.weekly);
      final yearly = todoService.getPreviousScope(ListScope.monthly);
      final backlog = todoService.getPreviousScope(ListScope.yearly);
      final nall = todoService.getPreviousScope(ListScope.backlog);

      expect(weekly, ListScope.weekly);
      expect(monthly, ListScope.monthly);
      expect(yearly, ListScope.yearly);
      expect(backlog, ListScope.backlog);
      expect(nall, isNull);
    });

    test('TodoService getPrevieousList skips not active lists', () {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn({ListScope.yearly, ListScope.daily});

      final yearly = todoService.getPreviousScope(ListScope.daily);

      expect(yearly, ListScope.yearly);
    });

    test(
      'TodoService getPreviousList returns null if provided scope is not active',
      () {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn({ListScope.yearly, ListScope.daily});

        final nall = todoService.getPreviousScope(ListScope.monthly);

        expect(nall, isNull);
      },
    );

    test('TodoService getNextList returns correct list', () {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn(ListScope.values.toSet());

      final yearly = todoService.getNextScope(ListScope.backlog);
      final monthly = todoService.getNextScope(ListScope.yearly);
      final weekly = todoService.getNextScope(ListScope.monthly);
      final daily = todoService.getNextScope(ListScope.weekly);
      final nall = todoService.getNextScope(ListScope.daily);

      expect(yearly, ListScope.yearly);
      expect(monthly, ListScope.monthly);
      expect(weekly, ListScope.weekly);
      expect(daily, ListScope.daily);
      expect(nall, isNull);
    });

    test('TodoService getNextList skips not active lists', () {
      when(
        () => settingsServiceMock.getActiveListScopes(),
      ).thenReturn({ListScope.yearly, ListScope.daily});

      final daily = todoService.getNextScope(ListScope.yearly);

      expect(daily, ListScope.daily);
    });

    test(
      'TodoService getNextList returns null if provided scope is not active',
      () {
        when(
          () => settingsServiceMock.getActiveListScopes(),
        ).thenReturn({ListScope.yearly, ListScope.daily});

        final nall = todoService.getNextScope(ListScope.monthly);

        expect(nall, isNull);
      },
    );
  });
}
