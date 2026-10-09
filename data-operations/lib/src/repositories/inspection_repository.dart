import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

/// Human inspections. The verified finding is entered by a person and is
/// never derived from, or copied into, a scan result. Once stored it cannot
/// be changed (nor can the evidence photo list); only the follow-up status
/// and the assignee move.
class DriftInspectionRepository implements InspectionRepository {
  DriftInspectionRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Throws [ArgumentError] for a blank inspector, an unknown item, a scan
  /// of another item, or a photo path that is blank or not absolute.
  @override
  Future<Inspection> create(InspectionDraft draft) async {
    final inspector = requireText(draft.inspector, 'inspector');
    final photoPaths = [
      for (final path in draft.photoPaths) _requirePhotoPath(path),
    ];
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
              assignedTo: Value(blankToNull(draft.assignedTo)),
              photoPaths: Value(photoPaths),
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

  /// Follow-ups still open or in progress on items that are not archived,
  /// oldest inspection first.
  @override
  Stream<List<Inspection>> watchOpen() {
    final inspections = _db.inspections;
    final items = _db.items;
    final query =
        _db.select(inspections).join([
            innerJoin(items, items.id.equalsExp(inspections.itemId)),
          ])
          ..where(
            inspections.followUpStatus.isInValues(const [
                  FollowUpStatus.open,
                  FollowUpStatus.inProgress,
                ]) &
                items.archivedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(inspections.inspectedAt),
            OrderingTerm.asc(inspections.createdAt),
            OrderingTerm.asc(inspections.id),
          ]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(inspections).toModel()],
    );
  }

  /// Only writes followUpStatus and updatedAt; the verified finding is
  /// untouched (and guarded by a database trigger).
  @override
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status) => _write(
    id,
    InspectionsCompanion(
      followUpStatus: Value(status),
      updatedAt: Value(_clock().toUtc()),
    ),
  );

  /// Sets the assignee, or clears it when [assignee] is null or blank. Only
  /// writes assignedTo and updatedAt.
  @override
  Future<Inspection> assign(String id, String? assignee) => _write(
    id,
    InspectionsCompanion(
      assignedTo: Value(blankToNull(assignee)),
      updatedAt: Value(_clock().toUtc()),
    ),
  );

  Future<Inspection> _write(String id, InspectionsCompanion changes) {
    return _db.transaction(() async {
      final updated = await (_db.update(
        _db.inspections,
      )..where((i) => i.id.equals(id))).write(changes);
      if (updated == 0) {
        throw ArgumentError.value(id, 'id', 'unknown inspection');
      }
      final row = await (_db.select(
        _db.inspections,
      )..where((i) => i.id.equals(id))).getSingle();
      return row.toModel();
    });
  }

  static String _requirePhotoPath(String path) {
    final trimmed = requireText(path, 'photoPaths');
    if (!p.isAbsolute(trimmed)) {
      throw ArgumentError.value(path, 'photoPaths', 'must be absolute');
    }
    return trimmed;
  }

  static List<Inspection> _toModels(List<InspectionRow> rows) => [
    for (final row in rows) row.toModel(),
  ];
}
