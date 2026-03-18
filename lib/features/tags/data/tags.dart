import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/syncable.dart';

@DataClassName('Tag', extending: SyncableEntity)
class Tags extends SyncableTable {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 25)();
  IntColumn get color => integer()();
}