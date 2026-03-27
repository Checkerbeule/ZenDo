import 'package:drift/drift.dart';

enum EntityType { task, tag }

class Entities extends Table {
  TextColumn get uuid => text().withLength(min: 36, max: 36)();
  TextColumn get entityType => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uuid};
}
