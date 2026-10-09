import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

class DriftLotRepository implements LotRepository {
  DriftLotRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Future<Lot> create(LotDraft draft) async {
    final now = _clock().toUtc();
    final row = await _db
        .into(_db.lots)
        .insertReturning(
          LotsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            code: requireText(draft.code, 'code'),
            supplierId: Value(blankToNull(draft.supplierId)),
            supplierName: Value(blankToNull(draft.supplierName)),
            grainType: requireText(draft.grainType, 'grainType'),
            declaredQuantity: requireNonNegative(
              draft.declaredQuantity,
              'declaredQuantity',
            ),
            quantityUnit: requireText(draft.quantityUnit, 'quantityUnit'),
            receivedAt: draft.receivedAt.toUtc(),
          ),
        );
    return row.toModel();
  }

  /// Returns archived lots too.
  @override
  Future<Lot?> get(String id) async {
    final row = await (_db.select(
      _db.lots,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Non-archived lots, most recently received first.
  @override
  Stream<List<Lot>> watchAll() {
    final query = _db.select(_db.lots)
      ..where((l) => l.archivedAt.isNull())
      ..orderBy([
        (l) => OrderingTerm.desc(l.receivedAt),
        (l) => OrderingTerm.asc(l.code),
        (l) => OrderingTerm.asc(l.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }

  /// Human action only. Nothing in this package calls it from predictions.
  @override
  Future<Lot> updateScreeningStatus(String id, ScreeningStatus status) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(_db.lots)..where((l) => l.id.equals(id))).write(
            LotsCompanion(
              screeningStatus: Value(status),
              updatedAt: Value(_clock().toUtc()),
            ),
          );
      if (updated == 0) {
        throw ArgumentError.value(id, 'id', 'unknown lot');
      }
      return (await get(id))!;
    });
  }

  /// Soft delete. Items in the lot keep their lotId. Archiving an archived
  /// lot keeps its original archivedAt.
  @override
  Future<void> archive(String id) async {
    await _db.transaction(() async {
      final lot = await get(id);
      if (lot == null) throw ArgumentError.value(id, 'id', 'unknown lot');
      if (lot.isArchived) return;
      final now = _clock().toUtc();
      await (_db.update(_db.lots)..where((l) => l.id.equals(id))).write(
        LotsCompanion(archivedAt: Value(now), updatedAt: Value(now)),
      );
    });
  }
}
