import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';

/// Manages the metadata and synchronization state of all application entities.
class EntityRepository {
  final AppDatabase db;

  EntityRepository(this.db);

  /// Creates a new entity entry and returns its unique [uuid].
  /// Sets initial timestamps (UTC) for creation and update.
  Future<Entity> create(EntityType type) async {
    final timestamp = DateTime.now().toUtc();
    final uuid = Uuid().v4();
    return await (db
        .into(db.entities)
        .insertReturning(
          EntitiesCompanion.insert(
            uuid: uuid,
            type: type,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ));
  }

  /// Orchestrates the creation of a new entity and its specific domain data
  /// (e.g., a Tag or Todo) within a single atomic database transaction.
  ///
  /// This ensures that the metadata entry in the 'entities' table and the
  /// actual data entry are both created successfully, or neither is.
  ///
  /// Generates a new UUID, passes it to the [createStatement], and returns
  /// the statement's result upon successful completion of the transaction.
  Future<T> createWithEntity<T>(
    EntityType type,
    Future<T> Function(Entity entity) createStatement,
  ) async {
    return db.transaction(() async {
      final entity = await create(type);
      return await createStatement(entity);
    });
  }

  /// Retrieves a single entity by its [uuid], regardless if it is marked as deleted.
  /// Returns null if not found.
  Future<Entity?> read(String uuid) async {
    return await (db.select(
      db.entities,
    )..where((entity) => entity.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Retrieves all entities of a specific [type], that are not marked as deleted.
  Future<List<Entity>> readAllActiveByType(EntityType type) async {
    return await (db.select(db.entities)..where(
          (entity) =>
              entity.type.equalsValue(type) & entity.isDeleted.equals(false),
        ))
        .get();
  }

  /// Retrieves all existing entities across all types, that are not marked as deleted.
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
  /// Note: Returns the entity even if [isDeleted] is true.
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

  /// Sets the [lastSyncedAt] timestamp after a successful server synchronization.
  Future<bool> markAsSynced(String uuid, DateTime syncedAtUtc) async {
    final marked =
        await (db.update(db.entities)
              ..where((entity) => entity.uuid.equals(uuid)))
            .write(EntitiesCompanion(lastSyncedAt: Value(syncedAtUtc)));
    return marked == 1;
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
