import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Throws [ArgumentError] for a blank name or an unknown or archived
  /// parent.
  @override
  Future<Location> create(LocationDraft draft) async {
    final name = requireText(draft.name, 'name');
    final parentId = draft.parentId;
    return _db.transaction(() async {
      if (parentId != null) {
        final parent = await get(parentId);
        if (parent == null) {
          throw ArgumentError.value(parentId, 'parentId', 'unknown location');
        }
        if (parent.isArchived) {
          throw ArgumentError.value(parentId, 'parentId', 'is archived');
        }
      }
      final now = _clock().toUtc();
      final row = await _db
          .into(_db.locations)
          .insertReturning(
            LocationsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              type: draft.type,
              name: name,
              parentId: Value(parentId),
            ),
          );
      return row.toModel();
    });
  }

  /// Returns archived locations too.
  @override
  Future<Location?> get(String id) async {
    final row = await (_db.select(
      _db.locations,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Non-archived direct children, by name. Children of an archived
  /// location are still listed under it; archiving is not recursive.
  @override
  Stream<List<Location>> watchChildren(String? parentId) => _watch(
    (l) => parentId == null ? l.parentId.isNull() : l.parentId.equals(parentId),
  );

  /// Every non-archived location, by name.
  @override
  Stream<List<Location>> watchAll() => _watch((_) => const Constant(true));

  /// Soft delete. Items placed there keep their locationId. Archiving an
  /// archived location keeps its original archivedAt.
  @override
  Future<void> archive(String id) async {
    await _db.transaction(() async {
      final location = await get(id);
      if (location == null) {
        throw ArgumentError.value(id, 'id', 'unknown location');
      }
      if (location.isArchived) return;
      final now = _clock().toUtc();
      await (_db.update(_db.locations)..where((l) => l.id.equals(id))).write(
        LocationsCompanion(archivedAt: Value(now), updatedAt: Value(now)),
      );
    });
  }

  Stream<List<Location>> _watch(
    Expression<bool> Function($LocationsTable) filter,
  ) {
    final query = _db.select(_db.locations)
      ..where((l) => filter(l) & l.archivedAt.isNull())
      ..orderBy([
        (l) => OrderingTerm.asc(l.name),
        (l) => OrderingTerm.asc(l.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }
}

/// [locationId] plus every location nested below it, archived or not.
Future<Set<String>> locationSubtree(
  KernelDatabase db,
  String locationId,
) async {
  final rows = await db
      .customSelect(
        'WITH RECURSIVE sub(id) AS ('
        '  SELECT ?1'
        '  UNION'
        '  SELECT l.id FROM locations l JOIN sub ON l.parent_id = sub.id'
        ') SELECT id FROM sub',
        variables: [Variable.withString(locationId)],
        readsFrom: {db.locations},
      )
      .get();
  return {for (final row in rows) row.read<String>('id')};
}
