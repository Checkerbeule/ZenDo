import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase db;
  late EntityRepository entityRepo;
  late TagRepository tagRepo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    tagRepo = TagRepository(db);
    entityRepo = EntityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'TagRepository create sucessfully creates new tag with correct fractional index',
    () async {
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

      expect(tag_1.name, 'Test Tag 1');
      expect(tag_1.customOrder, 'a0');
      expect(tag_2.name, 'Test Tag 2');
      expect(tag_2.customOrder, 'a1');
    },
  );

  test('TagRepository update sucessfully', () async {
    final tag = await entityRepo.createWithEntity(EntityType.tag, (
      Entity e,
    ) async {
      return await tagRepo.create(
        uuid: e.uuid,
        name: 'Test Tag',
        color: Colors.red.toARGB32(),
      );
    });

    final updated = await tagRepo.update(
      tag.copyWith(
        name: 'Changed name',
        color: Colors.green.toARGB32(),
        customOrder: 'a5',
      ),
    );

    final loadedTags = await tagRepo.readAllByUuids({tag.uuid});
    expect(updated, isTrue);
    expect(tag.customOrder, 'a0');
    expect(loadedTags.length, 1);
    expect(loadedTags.first.customOrder, 'a5');
    expect(loadedTags.first.name, 'Changed name');
    expect(loadedTags.first.color, Colors.green.toARGB32());
  });

  test('TagRepository readAll sucessfully rads tags in custom order', () async {
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
    final tag_3 = await entityRepo.createWithEntity(EntityType.tag, (
      Entity e,
    ) async {
      return await tagRepo.create(
        uuid: e.uuid,
        name: 'Test Tag 3',
        color: Colors.red.toARGB32(),
      );
    });
    await tagRepo.update(tag_1.copyWith(customOrder: 'a3'));
    await entityRepo.markAsDeleted(tag_2.uuid);

    final loadedTags = await tagRepo.readAll();

    expect(loadedTags.length, 2);
    expect(loadedTags.first.uuid, tag_3.uuid);
    expect(loadedTags.last.uuid, tag_1.uuid);
  });

  test('TagRepository readAllByUuids sucessfully rads desired tags', () async {
    await entityRepo.createWithEntity(EntityType.tag, (Entity e) async {
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
    final tag_3 = await entityRepo.createWithEntity(EntityType.tag, (
      Entity e,
    ) async {
      return await tagRepo.create(
        uuid: e.uuid,
        name: 'Test Tag 3',
        color: Colors.red.toARGB32(),
      );
    });

    final loadedTags = await tagRepo.readAllByUuids({tag_2.uuid, tag_3.uuid});

    expect(loadedTags.length, 2);
    expect(loadedTags.first.uuid, tag_2.uuid);
    expect(loadedTags.last.uuid, tag_3.uuid);
  });
}
