import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

mixin SyncTable on Table {
  TextColumn get uuid => text()
      .withLength(min: 36, max: 36)
      .unique()
      .clientDefault(() => const Uuid().v4())();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(Constant(SyncStatus.localOnly.index))();
}

enum SyncStatus { localOnly, synced, pending, deleted }

class SyncStatusConverter extends TypeConverter<SyncStatus, int> {
  const SyncStatusConverter();
  @override
  SyncStatus fromSql(int fromDb) => SyncStatus.values[fromDb];
  @override
  int toSql(SyncStatus value) => value.index;
}
