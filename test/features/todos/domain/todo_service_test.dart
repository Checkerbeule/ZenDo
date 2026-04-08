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
    expect(dailyTodo.expiresAt, now.add(Duration(days: 1)).normalized);
    expect(weeklyTodo.expiresAt, now.add(Duration(days: 7)).normalized);
    expect(monthlyTodo.expiresAt, now.add(Duration(days: 30)).normalized);
    expect(yearlyTodo.expiresAt, now.add(Duration(days: 365)).normalized);
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
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with daily scope',
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
        await todoRepo.update(
          expired.copyWith(
            expiresAt: DateTime.now().normalized.subtract(Duration(days: 1)),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.daily)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isTrue);
        expect(openTodos.last.isMovingToNextScope, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with weekly scope',
      () async {
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
        await todoRepo.update(
          expired.copyWith(
            expiresAt: DateTime.now().normalized.add(ListScope.daily.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.weekly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isTrue);
        expect(openTodos.last.isMovingToNextScope, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with monthly scope',
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
        await todoRepo.update(
          expired.copyWith(
            expiresAt: DateTime.now().normalized.add(ListScope.weekly.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.monthly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isTrue);
        expect(openTodos.last.isMovingToNextScope, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with yearly scope',
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
        await todoRepo.update(
          expired.copyWith(
            expiresAt: DateTime.now().normalized.add(
              ListScope.monthly.duration,
            ),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isTrue);
        expect(openTodos.last.isMovingToNextScope, isFalse);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with backlog scope',
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
        await todoRepo.update(
          backlogTodo.copyWith(
            expiresAt: DateTime.now().normalized.add(ListScope.yearly.duration),
          ),
        );
        await todoRepo.update(
          backlogButExpired.copyWith(
            expiresAt: DateTime.now().normalized.subtract(Duration(days: 1)),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.backlog)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isFalse);
        expect(openTodos.last.isMovingToNextScope, isTrue);
      },
    );

    test(
      'TodoService watchAllOpendByScope properly sets isMovingToNextScope on todos with yearly scope with inactive monthly scope',
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
        await todoRepo.update(
          expired.copyWith(
            expiresAt: DateTime.now().normalized.add(ListScope.weekly.duration),
          ),
        );

        final openTodos = await todoService
            .watchAllOpenByScope(scope: ListScope.yearly)
            .first;

        expect(openTodos.length, 2);
        expect(openTodos.first.isMovingToNextScope, isTrue);
        expect(openTodos.last.isMovingToNextScope, isFalse);
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
          expiresAt: Value(
            DateTime.now().subtract(Duration(days: 1)).normalized,
          ),
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
            DateTime.now().add(ListScope.daily.duration).normalized,
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
          expiresAt: Value(DateTime.now().add(Duration(days: 2)).normalized),
        ),
      );

      final completedTodos = await todoService
          .watchWillBeTransfered(ListScope.weekly)
          .first;

      expect(completedTodos, 2);
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
      expect(entity!.updatedAt.isAfter(entity.createdAt), isNotNull);
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
}
