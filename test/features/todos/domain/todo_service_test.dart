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
