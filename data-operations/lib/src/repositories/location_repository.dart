import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Future<Location> create(LocationDraft draft) async {
    final name = requireText(draft.name, 'name');
    final parentId = draft.parentId;
    if (parentId != null && await get(parentId) == null) {
      throw ArgumentError.value(parentId, 'parentId', 'unknown location');
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
  }

  @override
  Future<Location?> get(String id) async {
    final row = await (_db.select(
      _db.locations,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Stream<List<Location>> watchChildren(String? parentId) {
    final query = _db.select(_db.locations)
      ..where(
        (l) => parentId == null
            ? l.parentId.isNull()
            : l.parentId.equals(parentId),
      )
      ..orderBy([
        (l) => OrderingTerm.asc(l.name),
        (l) => OrderingTerm.asc(l.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }
}

/// [locationId] plus every location nested below it.
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
