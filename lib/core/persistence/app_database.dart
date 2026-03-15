import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/persistence/syncable.dart';
import 'package:zen_do/features/tags/data/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tags])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'zendo_local_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          await batch((batch) {
            batch.insertAll(tags, [
              TagsCompanion.insert(
                name: 'Work',
                color: material.Colors.red.toARGB32(),
              ),
              TagsCompanion.insert(
                name: 'Private',
                color: material.Colors.green.toARGB32(),
              ),
              TagsCompanion.insert(
                name: 'Focus',
                color: material.Colors.blue.toARGB32(),
              ),
              TagsCompanion.insert(
                name: 'On the Go',
                color: material.Colors.purple.toARGB32(),
              ),
            ]);
          });
        }
      },
    );
  }
}
