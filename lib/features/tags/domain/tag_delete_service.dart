import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/core/persistence/hive/persistence_helper.dart';

class TagDeleteService {
  final TagRepository tagRepo;

  TagDeleteService({required this.tagRepo});

  Future<void> deleteTagAndcleanupReferences(Tag tag) async {
    await PersistenceHelper.cleanupTagReferences(tag.uuid);
    await tagRepo.deleteTag(tag);
  }
}
