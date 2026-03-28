import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/persistence/hive/persistence_helper.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';

class TagService {
  final TagRepository tagRepo;
  final EntityRepository entityRepo;

  TagService({required this.tagRepo, required this.entityRepo});

  Future<String> create({required String name, required int color}) async {
    return await entityRepo.createWithEntity(EntityType.tag, (String uuid) async {
      await tagRepo.create(uuid: uuid, name: name, color: color);
      return uuid;
    });
  }

  Stream<List<Tag>> watchAll() => tagRepo.watchAll();

  Future<bool> update(Tag tag) async {
    return await entityRepo.updateWithTouch(tag.uuid, () async {
      return await tagRepo.update(tag);
    });
  }

  Future<int> delete(Tag tag) async {
    await PersistenceHelper.cleanupTagReferences(tag.uuid); // das hier löscht die verknüfungen zu den todos (noch in Hive). Muss noch auf Drift umgestellt werden. Nur eine Zwischenlösung.
    return await entityRepo.markAsDeleted(tag.uuid);
  }
}
