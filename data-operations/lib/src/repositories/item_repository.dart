import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

class DriftItemRepository implements ItemRepository {
  DriftItemRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Future<GrainItem> create(GrainItemDraft draft) async {
    final label = requireText(draft.label, 'label');
    final grainType = requireText(draft.grainType, 'grainType');
    final quantity = requireNonNegative(draft.quantity, 'quantity');
    final unit = requireText(draft.quantityUnit, 'quantityUnit');
    await _checkReferences(draft.locationId, draft.lotId);
    final now = _clock().toUtc();
    final row = await _db
        .into(_db.items)
        .insertReturning(
          ItemsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            ownerRole: draft.ownerRole,
            label: label,
            grainType: grainType,
            quantity: quantity,
            quantityUnit: unit,
            storageDate: draft.storageDate.toUtc(),
            locationId: Value(draft.locationId),
            lotId: Value(draft.lotId),
          ),
        );
    return row.toModel();
  }

  /// Updates the user-editable fields. id, createdAt and syncState are kept
  /// from the stored row; updatedAt is set to now.
  @override
  Future<GrainItem> update(GrainItem item) async {
    final label = requireText(item.label, 'label');
    final grainType = requireText(item.grainType, 'grainType');
    final quantity = requireNonNegative(item.quantity, 'quantity');
    final unit = requireText(item.quantityUnit, 'quantityUnit');
    await _checkReferences(item.locationId, item.lotId);
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.items,
          )..where((i) => i.id.equals(item.id))).write(
            ItemsCompanion(
              updatedAt: Value(_clock().toUtc()),
              ownerRole: Value(item.ownerRole),
              label: Value(label),
              grainType: Value(grainType),
              quantity: Value(quantity),
              quantityUnit: Value(unit),
              storageDate: Value(item.storageDate.toUtc()),
              locationId: Value(item.locationId),
              lotId: Value(item.lotId),
            ),
          );
      if (updated == 0) {
        throw ArgumentError.value(item.id, 'item.id', 'unknown item');
      }
      return (await get(item.id))!;
    });
  }

  @override
  Future<GrainItem?> get(String id) async {
    final row = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  @override
  Stream<List<GrainItem>> watchByRole(Role role) =>
      _watch((i) => i.ownerRole.equalsValue(role));

  /// Items placed directly at [locationId] (not in nested locations).
  @override
  Stream<List<GrainItem>> watchByLocation(String locationId) =>
      _watch((i) => i.locationId.equals(locationId));

  @override
  Stream<List<GrainItem>> watchByLot(String lotId) =>
      _watch((i) => i.lotId.equals(lotId));

  Stream<List<GrainItem>> _watch(
    Expression<bool> Function($ItemsTable) filter,
  ) {
    final query = _db.select(_db.items)
      ..where(filter)
      ..orderBy([
        (i) => OrderingTerm.asc(i.label),
        (i) => OrderingTerm.asc(i.createdAt),
        (i) => OrderingTerm.asc(i.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }

  Future<void> _checkReferences(String? locationId, String? lotId) async {
    if (locationId != null) {
      final found = await (_db.select(
        _db.locations,
      )..where((l) => l.id.equals(locationId))).getSingleOrNull();
      if (found == null) {
        throw ArgumentError.value(locationId, 'locationId', 'unknown location');
      }
    }
    if (lotId != null) {
      final found = await (_db.select(
        _db.lots,
      )..where((l) => l.id.equals(lotId))).getSingleOrNull();
      if (found == null) {
        throw ArgumentError.value(lotId, 'lotId', 'unknown lot');
      }
    }
  }
}
