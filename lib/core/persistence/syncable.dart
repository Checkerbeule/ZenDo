import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus { localOnly, synced, pending, deleted }

mixin Syncable on Table {
  TextColumn get uuid => text()
      .withLength(min: 36, max: 36)
      .unique()
      .clientDefault(() => const Uuid().v4())();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text()
      .map(const EnumNameConverter(SyncStatus.values))
      .withDefault(Constant(SyncStatus.localOnly.name))();
}
