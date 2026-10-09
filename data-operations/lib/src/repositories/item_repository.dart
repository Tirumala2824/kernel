import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'reminder_repository.dart';

class DriftItemRepository implements ItemRepository {
  /// [_reminders] silences and restores an item's reminder notifications
  /// on archive/unarchive; DataOperations always wires it.
  DriftItemRepository(this._db, this._clock, [this._reminders]);

  final KernelDatabase _db;
  final Clock _clock;
  final DriftReminderRepository? _reminders;

  /// Throws [ArgumentError] for blank text, a negative quantity, or a
  /// location, lot or harvest that is unknown or archived.
  @override
  Future<GrainItem> create(GrainItemDraft draft) async {
    final label = requireText(draft.label, 'label');
    final grainType = requireText(draft.grainType, 'grainType');
    final quantity = requireNonNegative(draft.quantity, 'quantity');
    final unit = requireText(draft.quantityUnit, 'quantityUnit');
    return _db.transaction(() async {
      await _checkReferences(
        locationId: draft.locationId,
        lotId: draft.lotId,
        harvestId: draft.harvestId,
      );
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
              harvestId: Value(draft.harvestId),
            ),
          );
      return row.toModel();
    });
  }

  /// Updates the user-editable fields. id, createdAt, syncState and
  /// archivedAt are kept from the stored row (use [archive]/[unarchive]);
  /// updatedAt is set to now. A changed location, lot or harvest must exist
  /// and not be archived; an unchanged one is kept as it is.
  @override
  Future<GrainItem> update(GrainItem item) async {
    final label = requireText(item.label, 'label');
    final grainType = requireText(item.grainType, 'grainType');
    final quantity = requireNonNegative(item.quantity, 'quantity');
    final unit = requireText(item.quantityUnit, 'quantityUnit');
    return _db.transaction(() async {
      final stored = await _row(item.id);
      if (stored == null) {
        throw ArgumentError.value(item.id, 'item.id', 'unknown item');
      }
      await _checkReferences(
        locationId: item.locationId,
        lotId: item.lotId,
        harvestId: item.harvestId,
        previous: stored,
      );
      await (_db.update(_db.items)..where((i) => i.id.equals(item.id))).write(
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
          harvestId: Value(item.harvestId),
        ),
      );
      return (await _row(item.id))!.toModel();
    });
  }

  /// Returns archived items too.
  @override
  Future<GrainItem?> get(String id) async => (await _row(id))?.toModel();

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

  @override
  Stream<List<GrainItem>> watchByHarvest(String harvestId) =>
      _watch((i) => i.harvestId.equals(harvestId));

  /// Soft delete. Scans, inspections and reminders stay stored; the item's
  /// pending reminder notifications are silenced until [unarchive].
  /// Archiving an archived item keeps its original archivedAt.
  @override
  Future<void> archive(String id) async {
    final changed = await _db.transaction(() async {
      final row = await _row(id);
      if (row == null) throw ArgumentError.value(id, 'id', 'unknown item');
      if (row.archivedAt != null) return false;
      final now = _clock().toUtc();
      await (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(archivedAt: Value(now), updatedAt: Value(now)),
      );
      return true;
    });
    if (changed) await _reminders?.suspendForItem(id);
  }

  /// Restores an archived item and its future reminder notifications.
  /// Reminders that fell due while archived are marked fired.
  @override
  Future<void> unarchive(String id) async {
    final changed = await _db.transaction(() async {
      final row = await _row(id);
      if (row == null) throw ArgumentError.value(id, 'id', 'unknown item');
      if (row.archivedAt == null) return false;
      await (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(
          archivedAt: const Value(null),
          updatedAt: Value(_clock().toUtc()),
        ),
      );
      return true;
    });
    if (changed) await _reminders?.resumeForItem(id);
  }

  Future<ItemRow?> _row(String id) =>
      (_db.select(_db.items)..where((i) => i.id.equals(id))).getSingleOrNull();

  /// Non-archived items matching [filter], by label.
  Stream<List<GrainItem>> _watch(
    Expression<bool> Function($ItemsTable) filter,
  ) {
    final query = _db.select(_db.items)
      ..where((i) => filter(i) & i.archivedAt.isNull())
      ..orderBy([
        (i) => OrderingTerm.asc(i.label),
        (i) => OrderingTerm.asc(i.createdAt),
        (i) => OrderingTerm.asc(i.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }

  Future<void> _checkReferences({
    required String? locationId,
    required String? lotId,
    required String? harvestId,
    ItemRow? previous,
  }) async {
    if (locationId != null && locationId != previous?.locationId) {
      final found = await (_db.select(
        _db.locations,
      )..where((l) => l.id.equals(locationId))).getSingleOrNull();
      _requireActive(found?.archivedAt, found != null, locationId, 'location');
    }
    if (lotId != null && lotId != previous?.lotId) {
      final found = await (_db.select(
        _db.lots,
      )..where((l) => l.id.equals(lotId))).getSingleOrNull();
      _requireActive(found?.archivedAt, found != null, lotId, 'lot');
    }
    if (harvestId != null && harvestId != previous?.harvestId) {
      final found = await (_db.select(
        _db.harvests,
      )..where((h) => h.id.equals(harvestId))).getSingleOrNull();
      _requireActive(found?.archivedAt, found != null, harvestId, 'harvest');
    }
  }

  static void _requireActive(
    DateTime? archivedAt,
    bool exists,
    String id,
    String kind,
  ) {
    if (!exists) throw ArgumentError.value(id, '${kind}Id', 'unknown $kind');
    if (archivedAt != null) {
      throw ArgumentError.value(id, '${kind}Id', '$kind is archived');
    }
  }
}
