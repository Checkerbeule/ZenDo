import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus { localOnly, synced, pending, deleted }

abstract class SyncableTable extends Table {
  TextColumn get uuid => text()
      .withLength(min: 36, max: 36)
      .unique()
      .clientDefault(() => const Uuid().v4())();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text()
      .map(const EnumNameConverter(SyncStatus.values))
      .withDefault(Constant(SyncStatus.localOnly.name))();
}

abstract class SyncableEntity extends DataClass {
  String get uuid;
  SyncStatus get syncStatus;
  DateTime get updatedAt;

  const SyncableEntity();
}
