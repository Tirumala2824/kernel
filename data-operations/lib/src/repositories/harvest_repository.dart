import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

/// Farmer harvests. Sacks link to one through `GrainItem.harvestId`.
class DriftHarvestRepository implements HarvestRepository {
  DriftHarvestRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Throws [ArgumentError] for a blank name or grain type.
  @override
  Future<Harvest> create(HarvestDraft draft) async {
    final now = _clock().toUtc();
    final row = await _db
        .into(_db.harvests)
        .insertReturning(
          HarvestsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            name: requireText(draft.name, 'name'),
            grainType: requireText(draft.grainType, 'grainType'),
            harvestedAt: draft.harvestedAt.toUtc(),
            notes: Value(blankToNull(draft.notes)),
          ),
        );
    return row.toModel();
  }

  /// Returns archived harvests too.
  @override
  Future<Harvest?> get(String id) async {
    final row = await (_db.select(
      _db.harvests,
    )..where((h) => h.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Non-archived harvests, most recent harvest first.
  @override
  Stream<List<Harvest>> watchAll() {
    final query = _db.select(_db.harvests)
      ..where((h) => h.archivedAt.isNull())
      ..orderBy([
        (h) => OrderingTerm.desc(h.harvestedAt),
        (h) => OrderingTerm.asc(h.name),
        (h) => OrderingTerm.asc(h.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }

  /// Soft delete. Its sacks keep their harvestId and are not archived.
  /// Archiving an archived harvest keeps its original archivedAt.
  @override
  Future<void> archive(String id) async {
    await _db.transaction(() async {
      final harvest = await get(id);
      if (harvest == null) {
        throw ArgumentError.value(id, 'id', 'unknown harvest');
      }
      if (harvest.archivedAt != null) return;
      final now = _clock().toUtc();
      await (_db.update(_db.harvests)..where((h) => h.id.equals(id))).write(
        HarvestsCompanion(archivedAt: Value(now), updatedAt: Value(now)),
      );
    });
  }
}
