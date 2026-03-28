import 'package:drift/drift.dart';

enum EntityType { task, tag }

@TableIndex(name: 'idx_entities_type', columns: {#type})
@TableIndex(
  name: 'idx_entities_pending_sync',
  columns: {#updatedAt, #lastSyncedAt},
)
class Entities extends Table {
  TextColumn get uuid => text().withLength(min: 36, max: 36)();
  TextColumn get type =>
      text().map(const EnumNameConverter(EntityType.values))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uuid};
}
