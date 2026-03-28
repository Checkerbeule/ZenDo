import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';

/// Manages the metadata and synchronization state of all application entities.
class EntityRepository {
  final AppDatabase db;

  EntityRepository({required this.db});

  /// Creates a new entity entry and returns its unique [uuid].
  /// Sets initial timestamps (UTC) for creation and update.
  Future<String> create(EntityType type) async {
    final timestamp = DateTime.now().toUtc();
    final uuid = Uuid().v4();
    await (db
        .into(db.entities)
        .insert(
          EntitiesCompanion.insert(
            uuid: uuid,
            type: type,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ));
    return uuid;
  }

  /// Orchestrates the creation of a new entity and its specific domain data
  /// (e.g., a Tag or Todo) within a single atomic database transaction.
  ///
  /// This ensures that the metadata entry in the 'entities' table and the
  /// actual data entry are both created successfully, or neither is.
  ///
  /// Returns the generated [uuid] after both create statements have completed.
  Future<String> createWithEntity(
    EntityType type,
    Future<void> Function(String uuid) createStatement,
  ) async {
    return db.transaction(() async {
      final uuid = await create(type);
      await createStatement(uuid);
      return uuid;
    });
  }

  /// Retrieves a single entity by its [uuid]. Returns null if not found.
  Future<Entity?> read(String uuid) async {
    return await (db.select(
      db.entities,
    )..where((entity) => entity.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Retrieves all entities of a specific [type].
  Future<List<Entity>> readAllActiveByType(EntityType type) async {
    return await (db.select(db.entities)..where(
          (entity) =>
              entity.type.equalsValue(type) & entity.isDeleted.equals(false),
        ))
        .get();
  }

  /// Retrieves all existing entities across all types.
  Future<List<Entity>> readAllActive() async {
    return await (db.select(
      db.entities,
    )..where((entity) => entity.isDeleted.equals(false))).get();
  }

  /// Retrieves all entities that have pending changes not yet synced to the server.
  /// Includes new, modified, and soft-deleted records.
  Future<List<Entity>> readAllPending() async {
    return await (db.select(db.entities)..where(
          (entity) =>
              entity.lastSyncedAt.isNull() |
              entity.updatedAt.isBiggerThan(entity.lastSyncedAt),
        ))
        .get();
  }

  /// Finds all entities that are marked as deleted AND have been synced.
  /// These can be safely removed from the local database.
  Future<List<Entity>> readSyncedDeletes() async {
    return await (db.select(db.entities)..where(
          (entity) =>
              entity.isDeleted.equals(true) &
              entity.lastSyncedAt.isNotNull() &
              entity.lastSyncedAt.isBiggerOrEqual(entity.updatedAt),
        ))
        .get();
  }

  /// Provides a continuous stream of a single entity's data by [uuid].
  Stream<Entity?> watch(String uuid) {
    return (db.select(
      db.entities,
    )..where((entity) => entity.uuid.equals(uuid))).watchSingleOrNull();
  }

  /// Provides a stream of all entities of a specific [type].
  Stream<List<Entity>> watchAllByType(EntityType type) {
    return (db.select(db.entities)..where(
          (entity) =>
              entity.type.equalsValue(type) & entity.isDeleted.equals(false),
        ))
        .watch();
  }

  /// Provides a stream of all existing entities.
  Stream<List<Entity>> watchAll() {
    return (db.select(
      db.entities,
    )..where((entity) => entity.isDeleted.equals(false))).watch();
  }

  /// Updates the `updatedAt` timestamp to the current UTC time.
  /// Call this whenever the related domain data (e.g., Tag name) changes.
  Future<bool> touch(String uuid) async {
    final int updated =
        await (db.update(db.entities)
              ..where((entity) => entity.uuid.equals(uuid)))
            .write(EntitiesCompanion(updatedAt: Value(DateTime.now().toUtc())));
    return updated == 1;
  }

  /// Executes a domain-specific update within a transaction while
  /// automatically refreshing the entity's [updatedAt] timestamp.
  ///
  /// This ensures that whenever data in a specific table (e.g., tags, todos) changes,
  /// the corresponding metadata in the 'entities' table is
  /// updated to trigger a synchronization during the next sync cycle.
  ///
  /// The generic type [T] allows the [updateStatement] to return its own
  /// result (e.g., the number of rows affected or a boolean) back to the caller.
  ///
  /// Returns the result of the [updateStatement].
  Future<T> updateWithTouch<T>(
    String uuid,
    Future<T> Function() updateStatement,
  ) async {
    return db.transaction(() async {
      await touch(uuid);
      return await updateStatement();
    });
  }

  /// Sets the [lastSyncedAt] timestamp after a successful server synchronization.
  Future<bool> markAsSynced(String uuid, DateTime syncedAtUtc) async {
    final marked =
        await (db.update(db.entities)
              ..where((entity) => entity.uuid.equals(uuid)))
            .write(EntitiesCompanion(lastSyncedAt: Value(syncedAtUtc)));
    return marked == 1;
  }

  /// Marks an entity as deleted (Soft Delete) to ensure the deletion is synced.
  Future<int> markAsDeleted(String uuid) async {
    return await (db.update(
      db.entities,
    )..where((entity) => entity.uuid.equals(uuid))).write(
      EntitiesCompanion(
        isDeleted: Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Permanently removes an entity from the local database.
  /// Only call this after the server has confirmed the deletion.
  Future<int> hardDelete(String uuid) async {
    return await (db.delete(db.entities)..where(
          (entity) => entity.uuid.equals(uuid) & entity.isDeleted.equals(true),
        ))
        .go();
  }
}
