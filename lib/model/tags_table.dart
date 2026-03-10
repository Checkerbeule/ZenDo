import 'package:drift/drift.dart';
import 'package:zen_do/model/sync_table.dart';

class TagsTable extends Table with SyncTable {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 25)();
  IntColumn get color => integer()();
}