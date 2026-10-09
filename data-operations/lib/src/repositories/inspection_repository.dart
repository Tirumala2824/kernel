import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

/// Human inspections. The verified finding is entered by a person and is
/// never derived from, or copied into, a scan result. Once stored it cannot
/// be changed; only the follow-up status moves.
class DriftInspectionRepository implements InspectionRepository {
  DriftInspectionRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Future<Inspection> create(InspectionDraft draft) async {
    final inspector = requireText(draft.inspector, 'inspector');
    return _db.transaction(() async {
      final item = await (_db.select(
        _db.items,
      )..where((i) => i.id.equals(draft.itemId))).getSingleOrNull();
      if (item == null) {
        throw ArgumentError.value(draft.itemId, 'itemId', 'unknown item');
      }
      final scanId = draft.scanId;
      if (scanId != null) {
        final scan = await (_db.select(
          _db.scans,
        )..where((s) => s.id.equals(scanId))).getSingleOrNull();
        if (scan == null) {
          throw ArgumentError.value(scanId, 'scanId', 'unknown scan');
        }
        if (scan.itemId != draft.itemId) {
          throw ArgumentError.value(
            scanId,
            'scanId',
            'belongs to a different item',
          );
        }
      }
      final now = _clock().toUtc();
      final row = await _db
          .into(_db.inspections)
          .insertReturning(
            InspectionsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              itemId: draft.itemId,
              scanId: Value(scanId),
              inspectedAt: draft.inspectedAt.toUtc(),
              inspector: inspector,
              observations: draft.observations.trim(),
              verifiedFinding: draft.verifiedFinding,
              followUpStatus: draft.followUpStatus,
            ),
          );
      return row.toModel();
    });
  }

  /// Most recent inspection first.
  @override
  Stream<List<Inspection>> watchForItem(String itemId) {
    final query = _db.select(_db.inspections)
      ..where((i) => i.itemId.equals(itemId))
      ..orderBy([
        (i) => OrderingTerm.desc(i.inspectedAt),
        (i) => OrderingTerm.desc(i.createdAt),
        (i) => OrderingTerm.desc(i.id),
      ]);
    return query.watch().map(_toModels);
  }

  /// Follow-ups still open or in progress, oldest inspection first.
  @override
  Stream<List<Inspection>> watchOpen() {
    final query = _db.select(_db.inspections)
      ..where(
        (i) => i.followUpStatus.isInValues(const [
          FollowUpStatus.open,
          FollowUpStatus.inProgress,
        ]),
      )
      ..orderBy([
        (i) => OrderingTerm.asc(i.inspectedAt),
        (i) => OrderingTerm.asc(i.createdAt),
        (i) => OrderingTerm.asc(i.id),
      ]);
    return query.watch().map(_toModels);
  }

  /// Only writes followUpStatus and updatedAt; the verified finding is
  /// untouched (and guarded by a database trigger).
  @override
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.inspections,
          )..where((i) => i.id.equals(id))).write(
            InspectionsCompanion(
              followUpStatus: Value(status),
              updatedAt: Value(_clock().toUtc()),
            ),
          );
      if (updated == 0) {
        throw ArgumentError.value(id, 'id', 'unknown inspection');
      }
      final row = await (_db.select(
        _db.inspections,
      )..where((i) => i.id.equals(id))).getSingle();
      return row.toModel();
    });
  }

  static List<Inspection> _toModels(List<InspectionRow> rows) => [
    for (final row in rows) row.toModel(),
  ];
}
