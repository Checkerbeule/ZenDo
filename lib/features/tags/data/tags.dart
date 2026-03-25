import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/cloudsync/syncable.dart';

@DataClassName('Tag', extending: SyncableEntity)
@TableIndex(
  name: 'idx_tags_custom_order',
  columns: {#customOrder},
  unique: true,
)
class Tags extends SyncableTable {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 25)();
  IntColumn get color => integer()();
  TextColumn get customOrder => text()();
}
