import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';

void main() {
  late AppDatabase db;
  late EntityRepository entityRepo;
  late TodoTagsRepository todoTagsRepo;
  late TagRepository tagRepo;
  late TodoRepository todoRepo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    tagRepo = TagRepository(db);
    entityRepo = EntityRepository(db);
    todoRepo = TodoRepository(db);
    todoTagsRepo = TodoTagsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'TodoTagsRepository addAllTagsToTodo sucessfully links tags with given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });

      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo.uuid,
        tagUuids: {tag_1.uuid, tag_2.uuid},
      );

      final tagsFromTodo = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      expect(tagsFromTodo.length, 2);
      expect(tagsFromTodo.contains(tag_1), isTrue);
      expect(tagsFromTodo.contains(tag_2), isTrue);
    },
  );

  test(
    'TodoTagsRepository removeAllTagsFromTodo sucessfully removes all linked tags of given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });
      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo.uuid,
        tagUuids: {tag_1.uuid, tag_2.uuid},
      );

      await todoTagsRepo.removeAllTagsFromTodo(todo.uuid);

      final tagsFromTodo = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      final allTags = await tagRepo.readAll();
      expect(tagsFromTodo.isEmpty, isTrue);
      expect(allTags.length, 2);
    },
  );

  test(
    'TodoTagsRepository addTagToTodo sucessfully links a tag to given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });

      await todoTagsRepo.addTagToTodo(todoUuid: todo.uuid, tagUuid: tag_1.uuid);
      final tags_1 = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      await todoTagsRepo.addTagToTodo(todoUuid: todo.uuid, tagUuid: tag_2.uuid);
      final tags_2 = await todoTagsRepo.readTagsFromTodo(todo.uuid);

      expect(tags_1.length, 1);
      expect(tags_1.contains(tag_1), isTrue);
      expect(tags_2.length, 2);
      expect(tags_2.contains(tag_1), isTrue);
      expect(tags_2.contains(tag_2), isTrue);
    },
  );

  test(
    'TodoTagsRepository removeTagFromTodo sucessfully removes a linked tag from given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });

      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo.uuid,
        tagUuids: {tag_1.uuid, tag_2.uuid},
      );
      final tags_1 = await todoTagsRepo.readTagsFromTodo(todo.uuid);

      await todoTagsRepo.removeTagFromTodo(
        todoUuid: todo.uuid,
        tagUuid: tag_1.uuid,
      );

      final tags_2 = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      expect(tags_1.length, 2);
      expect(tags_1.contains(tag_1), isTrue);
      expect(tags_1.contains(tag_2), isTrue);
      expect(tags_2.length, 1);
      expect(tags_2.contains(tag_2), isTrue);
    },
  );

  test(
    'TodoTagsRepository updateTags sucessfully updates all linked linked tag of given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });
      await todoTagsRepo.addTagToTodo(todoUuid: todo.uuid, tagUuid: tag_1.uuid);

      await todoTagsRepo.updateTags(
        todoUuid: todo.uuid,
        newTagUuids: {tag_1.uuid, tag_2.uuid},
      );

      final tags = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      expect(tags.length, 2);
      expect(tags.contains(tag_1), isTrue);
      expect(tags.contains(tag_2), isTrue);
    },
  );

  test(
    'TodoTagsRepository readTagsFromTodo only active tags linked with given todo',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });
      await todoTagsRepo.addAllTagsToTodo(
        todoUuid: todo.uuid,
        tagUuids: {tag_1.uuid, tag_2.uuid},
      );
      await entityRepo.markAsDeleted(tag_1.uuid);

      final tags = await todoTagsRepo.readTagsFromTodo(todo.uuid);

      expect(tags.length, 1);
      expect(tags.contains(tag_2), isTrue);
    },
  );

  test(
    'TodoTagsRepository readTagsFromTodo loads linked tags in custom order',
    () async {
      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity e,
      ) async {
        return await todoRepo.create(
          uuid: e.uuid,
          title: 'Test todo',
          scope: ListScope.daily,
        );
      });
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
          color: Colors.red.toARGB32(),
        );
      });
      await todoTagsRepo.addTagToTodo(todoUuid: todo.uuid, tagUuid: tag_2.uuid);
      await todoTagsRepo.addTagToTodo(todoUuid: todo.uuid, tagUuid: tag_1.uuid);

      final tags = await todoTagsRepo.readTagsFromTodo(todo.uuid);

      expect(tags.length, 2);
      expect(tags.first, tag_1);
      expect(tags.last, tag_2);
    },
  );
}
