import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';

void main() {
  late AppDatabase db;
  late EntityRepository entityRepo;
  late TagRepository tagRepo;
  late TodoRepository todoRepo;
  late TodoTagsRepository todoTagsRepo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    todoRepo = TodoRepository(db);
    tagRepo = TagRepository(db);
    entityRepo = EntityRepository(db);
    todoTagsRepo = TodoTagsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'EntityRepository createWithEntity sucessfully creates new entity',
    () async {
      late final String uuid;
      await entityRepo.createWithEntity(EntityType.tag, (Entity e) async {
        uuid = e.uuid;
      });

      final entity = await entityRepo.read(uuid);

      expect(entity, isNotNull);
      expect(entity!.createdAt, isNotNull);
      expect(entity.updatedAt, isNotNull);
      expect(entity.isDeleted, isFalse);
      expect(entity.lastSyncedAt, isNull);
    },
  );

  test(
    'EntityRepository readAllActive sucessfully reads active entities',
    () async {
      final inActiveTag = await entityRepo.create(EntityType.tag);
      final activeTodo = await entityRepo.create(EntityType.todo);
      final activeTag = await entityRepo.create(EntityType.tag);
      await entityRepo.markAsDeleted(inActiveTag.uuid);

      final activeTags = await entityRepo.readAllActive();

      expect(activeTags, isNotNull);
      expect(activeTags.length, 2);
      expect(activeTags.contains(activeTag), isTrue);
      expect(activeTags.contains(activeTodo), isTrue);
      expect(activeTags.contains(inActiveTag), isFalse);
    },
  );

  test(
    'EntityRepository readAllActiveByType sucessfully reads desired entities',
    () async {
      final inActiveTag = await entityRepo.create(EntityType.tag);
      await entityRepo.create(EntityType.todo);
      final activeTag = await entityRepo.create(EntityType.tag);
      await entityRepo.markAsDeleted(inActiveTag.uuid);

      final activeTags = await entityRepo.readAllActiveByType(EntityType.tag);

      expect(activeTags, isNotNull);
      expect(activeTags.length, 1);
      expect(activeTags.first, activeTag);
    },
  );

  test(
    'EntityRepository readAllPending sucessfully reads unsynced entities',
    () async {
      final pending = await entityRepo.create(EntityType.tag);
      final synced = await entityRepo.create(EntityType.tag);
      final now = DateTime.now().toUtc();
      await (db.update(db.entities)..where((e) => e.uuid.equals(synced.uuid)))
          .write(synced.copyWith(updatedAt: now, lastSyncedAt: Value(now)));

      final pendingTags = await entityRepo.readAllPending();

      expect(pendingTags, isNotNull);
      expect(pendingTags.length, 1);
      expect(pendingTags.first, pending);
    },
  );

  test(
    'EntityRepository readAllPending sucessfully reads synced and soft deleted entities',
    () async {
      final pending = await entityRepo.create(EntityType.tag);
      Entity? synced = await entityRepo.create(EntityType.tag);
      await entityRepo.markAsDeleted(pending.uuid);
      await entityRepo.markAsDeleted(synced.uuid);
      synced = await entityRepo.read(synced.uuid);
      final now = DateTime.now().toUtc();
      await (db.update(db.entities)..where((e) => e.uuid.equals(synced!.uuid)))
          .write(synced!.copyWith(updatedAt: now, lastSyncedAt: Value(now)));

      final syncedDeletes = await entityRepo.readSyncedDeletes();

      expect(syncedDeletes, isNotNull);
      expect(syncedDeletes.length, 1);
      expect(syncedDeletes.first.uuid, synced.uuid);
    },
  );

  test(
    'EntityRepository updateWithTouch sucessfully updates updatedAt',
    () async {
      final entity = await entityRepo.create(EntityType.tag);
      await entityRepo.updateWithTouch(entity.uuid, () async {});

      final touched = await entityRepo.read(entity.uuid);

      expect(touched, isNotNull);
      expect(touched!.uuid, entity.uuid);
      expect(touched.updatedAt.isAfter(touched.createdAt), isTrue);
    },
  );

  test('EntityRepository markAsDeleted sucessfully', () async {
    final entity = await entityRepo.create(EntityType.tag);
    await entityRepo.markAsDeleted(entity.uuid);

    final deleted = await entityRepo.read(entity.uuid);

    expect(deleted, isNotNull);
    expect(deleted!.uuid, entity.uuid);
    expect(deleted.isDeleted, isTrue);
  });

  test(
    'EntityRepository markAsSynced sucessfully updates lastSyncedAt',
    () async {
      final entity = await entityRepo.create(EntityType.tag);
      final now = DateTime.now().toUtc();
      await entityRepo.markAsSynced(entity.uuid, now);

      final synced = await entityRepo.read(entity.uuid);

      expect(synced, isNotNull);
      expect(synced!.uuid, entity.uuid);
      expect(synced.lastSyncedAt, now);
      expect(synced.lastSyncedAt!.isAfter(synced.updatedAt), isTrue);
    },
  );

  test(
    'EntityRepository hardDelete not possible if not marked as deleted previously',
    () async {
      final entity = await entityRepo.create(EntityType.tag);

      final deleted = await entityRepo.hardDelete(entity.uuid);
      final notDeleted = await entityRepo.read(entity.uuid);

      expect(deleted, 0);
      expect(notDeleted, isNotNull);
      expect(notDeleted!.uuid, entity.uuid);
    },
  );

  test(
    'EntityRepository hardDelete removes entity and related object through cascade deletes sucessfully',
    () async {
      final tag_1 = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        return tagRepo.create(
          uuid: e.uuid,
          name: 'Test Tag 1',
          color: Colors.red.toARGB32(),
        );
      });
      final tag_2 = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        return tagRepo.create(
          uuid: e.uuid,
          name: 'Test Tag 2',
          color: Colors.green.toARGB32(),
        );
      });
      final todo = await entityRepo.createWithEntity(EntityType.tag, (
        Entity e,
      ) async {
        final todo = await todoRepo.create(
          uuid: e.uuid,
          scope: ListScope.day,
          title: 'Test Todo',
        );
        await todoTagsRepo.addAllTagsToTodo(
          todoUuid: todo.uuid,
          tagUuids: {tag_1.uuid, tag_2.uuid},
        );
        return todo;
      });

      final todoTags = await todoTagsRepo.readTagsFromTodo(todo.uuid);
      expect(todoTags.length, 2);
      expect(todoTags.contains(tag_1), isTrue);
      expect(todoTags.contains(tag_2), isTrue);

      await entityRepo.markAsDeleted(tag_1.uuid);
      await entityRepo.hardDelete(tag_1.uuid);
      expect(await entityRepo.read(tag_1.uuid), isNull);
      expect((await tagRepo.readAll()).length, 1);
      expect((await tagRepo.readAll()).first, tag_2);
      expect((await todoTagsRepo.readTagsFromTodo(todo.uuid)).length, 1);
      expect((await todoTagsRepo.readTagsFromTodo(todo.uuid)).first, tag_2);
      expect(await todoRepo.read(todo.uuid), todo);

      await entityRepo.markAsDeleted(todo.uuid);
      await entityRepo.markAsDeleted(tag_2.uuid);
      await entityRepo.hardDelete(todo.uuid);
      await entityRepo.hardDelete(tag_2.uuid);

      expect(await tagRepo.readAll(), isEmpty);
      expect(await todoRepo.read(todo.uuid), isNull);
      expect(await entityRepo.read(todo.uuid), isNull);
      expect(await entityRepo.read(tag_2.uuid), isNull);
      expect(await todoTagsRepo.readTagsFromTodo(todo.uuid), isEmpty);
    },
  );
}
