import 'package:async/async.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

void main() {
  late AppDatabase db;
  late TodoRepository todoRepo;
  late EntityRepository entityRepo;
  late TagRepository tagRepo;
  late TodoTagsRepository todoTagsRepo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    todoRepo = TodoRepository(db);
    entityRepo = EntityRepository(db);
    tagRepo = TagRepository(db);
    todoTagsRepo = TodoTagsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TodoRepository create tests', () {
    test('TodoRepository create todo successfully', () async {
      final title = 'Title';
      final description = 'Desc';
      final expirationDate = DateTime.now();

      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: title,
          description: description,
          scope: ListScope.daily,
          expiresAt: expirationDate,
        );
      });

      expect(todo.uuid, isNotNull);
      expect(todo.uuid, isNotEmpty);
      expect(todo.title, title);
      expect(todo.description, description);
      expect(todo.scope, ListScope.daily);
      expect(todo.expiresAt, expirationDate);
      expect(todo.customOrder, 'a0');
      expect(todo.completedAt, isNull);
    });

    test(
      'TodoRepository create todo generates correct fractional index',
      () async {
        final todo_1 = await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo 1',
            scope: ListScope.daily,
          );
        });

        final todo_2 = await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo 1',
            scope: ListScope.daily,
          );
        });

        expect(todo_1.uuid, isNotNull);
        expect(todo_1.uuid, isNotEmpty);
        expect(todo_1.scope, ListScope.daily);
        expect(todo_1.customOrder, 'a0');
        expect(todo_1.completedAt, isNull);

        expect(todo_2.customOrder, 'a1');
      },
    );
  });

  group('TodoRepository read tests', () {
    test('TodoRepository read single todo successfully', () async {
      final title = 'Title';
      final description = 'Desc';
      final expirationDate = DateTime.now().toUtc();

      final createdTodo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: title,
          description: description,
          scope: ListScope.daily,
          expiresAt: expirationDate,
        );
      });

      final todo = await todoRepo.read(createdTodo.uuid);

      expect(todo, isNotNull);
      expect(todo!.uuid, isNotNull);
      expect(todo.uuid, isNotEmpty);
      expect(todo.title, title);
      expect(todo.description, description);
      expect(todo.scope, ListScope.daily);
      expect(todo.expiresAt, expirationDate);
      expect(todo.customOrder, 'a0');
      expect(todo.completedAt, isNull);
    });

    test('TodoRepository read complleted todo successfully', () async {
      late final Entity entity;
      final createdTodo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        entity = e;
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Completed todo',
          scope: ListScope.daily,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      final completedAt = DateTime.now().toUtc();
      todoRepo.update(
        TodoDto.fromDb(
          todo: createdTodo,
          entity: entity,
        ).copyWith(completedAt: completedAt),
      );

      final todo = await todoRepo.read(createdTodo.uuid);

      expect(todo, isNotNull);
      expect(todo!.title, 'Completed todo');
      expect(todo.completedAt, completedAt);
    });

    test('TodoRepository watchAllByScope successfully', () async {
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Daily todo $i',
            scope: ListScope.daily,
          );
        });
      }
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Weekly todo $i',
            scope: ListScope.weekly,
          );
        });
      }
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Backlog todo $i',
            scope: ListScope.backlog,
          );
        });
      }

      final dailyTodos = await todoRepo
          .watchAllByScope(scope: ListScope.daily, isCompleted: false)
          .first;
      final weeklyTodos = await todoRepo
          .watchAllByScope(scope: ListScope.weekly, isCompleted: false)
          .first;
      final backlogTodos = await todoRepo
          .watchAllByScope(scope: ListScope.backlog, isCompleted: false)
          .first;

      expect(dailyTodos.length, 5);
      expect(weeklyTodos.length, 5);
      expect(backlogTodos.length, 5);
      for (final todo in dailyTodos) {
        expect(todo.scope, ListScope.daily);
      }
      for (final todo in weeklyTodos) {
        expect(todo.scope, ListScope.weekly);
      }
      for (final todo in backlogTodos) {
        expect(todo.scope, ListScope.backlog);
      }
    });

    test('TodoRepository watchAllByScope ignores completed todos', () async {
      late final Entity entity;
      final createdTodo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        entity = e;
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Completed todo',
          scope: ListScope.daily,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      todoRepo.update(
        TodoDto.fromDb(
          todo: createdTodo,
          entity: entity,
        ).copyWith(completedAt: DateTime.now().toUtc()),
      );

      final open = await todoRepo
          .watchAllByScope(scope: ListScope.daily, isCompleted: false)
          .firstOrNull;
      final completed = await todoRepo
          .watchAllByScope(scope: ListScope.daily, isCompleted: true)
          .first;

      expect(open!.length, 0);
      expect(completed.length, 1);
      expect(completed.first.title, 'Completed todo');
    });

    test(
      'TodoRepository watchAllByScope ignores deleted tags linked with todos',
      () async {
        final todo = await entityRepo.createWithEntity(EntityType.todo, (
          Entity e,
        ) async {
          return await todoRepo.create(
            uuid: e.uuid,
            title: 'Completed todo',
            scope: ListScope.daily,
            expiresAt: DateTime.now().toUtc(),
          );
        });
        final tag_1 = await entityRepo.createWithEntity(EntityType.tag, (
          Entity e,
        ) async {
          return await tagRepo.create(
            uuid: e.uuid,
            name: 'Tag 1',
            color: Colors.red.toARGB32(),
          );
        });
        final tag_2 = await entityRepo.createWithEntity(EntityType.tag, (
          Entity e,
        ) async {
          return await tagRepo.create(
            uuid: e.uuid,
            name: 'Tag 2',
            color: Colors.red.toARGB32(),
          );
        });
        await todoTagsRepo.addAllTagsToTodo(
          todoUuid: todo.uuid,
          tagUuids: {tag_1.uuid, tag_2.uuid},
        );
        entityRepo.markAsDeleted(tag_1.uuid);

        final todos = await todoRepo
            .watchAllByScope(scope: ListScope.daily, isCompleted: false)
            .firstOrNull;

        expect(todos!.length, 1);
        expect(todos.first.tagUuids.length, 1);
        expect(todos.first.tagUuids.first, tag_2.uuid);
      },
    );

    test(
      'TodoRepository watchAllByScope updates stream successfully',
      () async {
        final todoStream = todoRepo.watchAllByScope(
          scope: ListScope.daily,
          isCompleted: false,
        );
        final queue = StreamQueue(todoStream);

        expect(await queue.next, isEmpty);

        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'New todo',
            scope: ListScope.daily,
          );
        });

        expect(await queue.next, hasLength(1));

        queue.cancel();
      },
    );

    test('TodoRepository watchAllByScope with ordering successful', () async {
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'B Todo',
          scope: ListScope.daily,
        );
      });
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'A Todo',
          scope: ListScope.daily,
        );
      });
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'C Todo',
          scope: ListScope.daily,
        );
      });

      final ascList = await todoRepo
          .watchAllByScope(
            scope: ListScope.daily,
            isCompleted: false,
            sortOption: TodoSortOption.title,
            sortOrder: SortOrder.ascending,
          )
          .first;
      final descList = await todoRepo
          .watchAllByScope(
            scope: ListScope.daily,
            isCompleted: false,
            sortOption: TodoSortOption.title,
            sortOrder: SortOrder.descending,
          )
          .first;

      expect(ascList.length, 3);
      expect(ascList.first.title, 'A Todo');
      expect(ascList[1].title, 'B Todo');
      expect(ascList.last.title, 'C Todo');
      expect(descList.length, 3);
      expect(descList.first.title, 'C Todo');
      expect(descList[1].title, 'B Todo');
      expect(descList.last.title, 'A Todo');
    });

    test('TodoRepository watchAllByScope with tag filter successful', () async {
      final tagA = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        await tagRepo.create(
          uuid: e.uuid,
          name: 'Tag A',
          color: Colors.red.toARGB32(),
        );
        return e.uuid;
      });
      final tagB = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        await tagRepo.create(
          uuid: e.uuid,
          name: 'Tag B',
          color: Colors.green.toARGB32(),
        );
        return e.uuid;
      });
      final tagC = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        await tagRepo.create(
          uuid: e.uuid,
          name: 'Tag C',
          color: Colors.yellow.toARGB32(),
        );
        return e.uuid;
      });
      final todo_1 = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'Todo 1',
          scope: ListScope.daily,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo_1.uuid,
        tagUuids: {tagA, tagC},
      );
      final todo_2 = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'Todo 2',
          scope: ListScope.daily,
          expiresAt: DateTime.now().toUtc(),
        );
      });
      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo_2.uuid,
        tagUuids: {tagB},
      );

      final loaded = await todoRepo
          .watchAllByScope(
            scope: ListScope.daily,
            isCompleted: false,
            tagUuidsFilter: {tagC},
          )
          .first;

      expect(loaded.length, 1);
      expect(loaded.first.title, 'Todo 1');
      expect(loaded.first.tagUuids.length, 2);
      expect(loaded.first.tagUuids.containsAll({tagA, tagC}), isTrue);
    });
  });

  group('TodoRepository update tests', () {
    test('TodoRepository update new values successfully', () async {
      late final Entity entity;
      final Todo initialTodo = await entityRepo.createWithEntity(
        EntityType.todo,
        (Entity e) async {
          entity = e;
          return await todoRepo.create(
            uuid: e.uuid,
            title: 'Todo',
            scope: ListScope.daily,
          );
        },
      );
      final now = DateTime.now().toUtc();
      final todoToUpdate = initialTodo.copyWith(
        title: 'New title',
        description: Value('Desc'),
        scope: ListScope.yearly,
        completedAt: Value(now),
        customOrder: 'a2',
      );

      todoRepo.update(TodoDto.fromDb(todo: todoToUpdate, entity: entity));
      final updatedTodo = await todoRepo.read(todoToUpdate.uuid);

      expect(updatedTodo, isNotNull);
      expect(updatedTodo!.title, 'New title');
      expect(updatedTodo.description, 'Desc');
      expect(updatedTodo.scope, ListScope.yearly);
      expect(updatedTodo.completedAt, now);
      expect(updatedTodo.customOrder, 'a2');
    });

    test('TodoRepository update set values to null successfully', () async {
      late final Entity entity;
      final Todo initialTodo = await entityRepo.createWithEntity(
        EntityType.todo,
        (Entity e) async {
          entity = e;
          return await todoRepo.create(
            uuid: e.uuid,
            title: 'Todo',
            description: 'Desc',
            scope: ListScope.daily,
            expiresAt: DateTime.now().toUtc(),
          );
        },
      );
      final todoToUpdate = TodoDto.fromDb(todo: initialTodo, entity: entity)
          .copyWith(
            title: 'New title',
            description: null,
            scope: ListScope.backlog,
            expiresAt: null,
          );

      final updated = await todoRepo.update(todoToUpdate);
      final updatedTodo = await todoRepo.read(todoToUpdate.uuid);

      expect(updated, true);
      expect(updatedTodo, isNotNull);
      expect(updatedTodo!.title, 'New title');
      expect(updatedTodo.description, isNull);
      expect(updatedTodo.scope, ListScope.backlog);
      expect(updatedTodo.expiresAt, isNull);
    });

    test('TodoRepository update on non existing todo fails', () async {
      final nonExistinTodo = TodoDto(
        uuid: Uuid().v4(),
        title: 'Not existing todo',
        scope: ListScope.daily,
        customOrder: 'a0',
        createdAt: DateTime.now().toUtc(),
      );

      final updated = await todoRepo.update(nonExistinTodo);
      final updatedTodo = await todoRepo.read(nonExistinTodo.uuid);

      expect(updated, false);
      expect(updatedTodo, isNull);
    });
  });
}
