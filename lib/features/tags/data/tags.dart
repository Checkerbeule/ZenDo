import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/fractionalindex/fractional_index_table.dart';
import 'package:zen_do/core/persistence/cloudsync/syncable.dart';

@DataClassName(
  'Tag',
  extending: SyncableEntity,
  implementing: [WithFractionalIndex],
)
@TableIndex(name: 'idx_tags_fractional_index', columns: {#fractionalIndex})
class Tags extends SyncableTable with FractionalIndexTable {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 25)();
  IntColumn get color => integer()();
}
