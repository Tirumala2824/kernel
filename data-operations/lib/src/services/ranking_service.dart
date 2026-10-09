import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'scope.dart';

/// F08 inspection queue, following the ranking rule in docs/contracts.md.
class DriftRankingService implements RankingService {
  DriftRankingService(this._db);

  final KernelDatabase _db;

  @override
  Stream<InspectionQueue> watchQueue({
    Role? role,
    String? locationId,
    String? lotId,
  }) {
    return watchTables(_db, {
      _db.items,
      _db.scans,
      _db.locations,
    }, () => _compute(role: role, locationId: locationId, lotId: lotId));
  }

  Future<InspectionQueue> _compute({
    Role? role,
    String? locationId,
    String? lotId,
  }) async {
    final items = await itemsInScope(
      _db,
      role: role,
      locationId: locationId,
      lotId: lotId,
    );
    if (items.isEmpty) {
      return const InspectionQueue(
        ranked: [],
        needsScan: [],
        modelVersion: null,
      );
    }
    final ids = [for (final item in items) item.id];
    final candidates =
        await (_db.select(_db.scans)
              ..where(
                (s) =>
                    s.itemId.isIn(ids) &
                    s.quality.equalsValue(ScanQuality.pass) &
                    s.result.equalsValue(Classification.notEvaluated).not(),
              )
              ..orderBy([
                (s) => OrderingTerm.desc(s.capturedAt),
                (s) => OrderingTerm.desc(s.createdAt),
                (s) => OrderingTerm.desc(s.id),
              ]))
            .get();
    final latestValid = <String, ScanRecord>{};
    for (final row in candidates) {
      final record = row.toModel();
      if (record.isValid) latestValid.putIfAbsent(record.itemId, () => record);
    }
    return rankQueue([for (final item in items) item.toModel()], latestValid);
  }
}

/// Pure ranking rule.
///
/// 1. Each item's latest valid scan (quality PASS, result not notEvaluated)
///    is its candidate.
/// 2. The queue's model version is the one shared by the most candidates.
///    A tie goes to the version with the most recent scan, then to the
///    lexicographically greatest version string, so the output is
///    deterministic.
/// 3. Items whose candidate uses that version are ranked infested >
///    uncertain > clean, then oldest scan first.
/// 4. Every other item (no valid scan, or a different model version) goes to
///    needsScan, keeping the input order.
InspectionQueue rankQueue(
  List<GrainItem> items,
  Map<String, ScanRecord> latestValidByItem,
) {
  final counts = <String, int>{};
  final newest = <String, DateTime>{};
  for (final item in items) {
    final scan = latestValidByItem[item.id];
    if (scan == null || !scan.isValid) continue;
    counts[scan.modelVersion] = (counts[scan.modelVersion] ?? 0) + 1;
    final seen = newest[scan.modelVersion];
    if (seen == null || scan.capturedAt.isAfter(seen)) {
      newest[scan.modelVersion] = scan.capturedAt;
    }
  }

  String? version;
  for (final candidate in counts.keys) {
    if (version == null) {
      version = candidate;
      continue;
    }
    final byCount = counts[candidate]!.compareTo(counts[version]!);
    final byRecency = newest[candidate]!.compareTo(newest[version]!);
    if (byCount > 0 ||
        (byCount == 0 && byRecency > 0) ||
        (byCount == 0 && byRecency == 0 && candidate.compareTo(version) > 0)) {
      version = candidate;
    }
  }

  final ranked = <QueueEntry>[];
  final needsScan = <GrainItem>[];
  for (final item in items) {
    final scan = latestValidByItem[item.id];
    if (scan != null && scan.isValid && scan.modelVersion == version) {
      ranked.add(QueueEntry(item: item, latestValidScan: scan));
    } else {
      needsScan.add(item);
    }
  }
  ranked.sort((a, b) {
    final bySeverity = _severity(a.latestValidScan.result)
        .compareTo(_severity(b.latestValidScan.result));
    if (bySeverity != 0) return bySeverity;
    final byAge = a.latestValidScan.capturedAt.compareTo(
      b.latestValidScan.capturedAt,
    );
    if (byAge != 0) return byAge;
    return a.item.id.compareTo(b.item.id);
  });

  return InspectionQueue(
    ranked: List.unmodifiable(ranked),
    needsScan: List.unmodifiable(needsScan),
    modelVersion: ranked.isEmpty ? null : version,
  );
}

int _severity(Classification result) => switch (result) {
  Classification.infested => 0,
  Classification.uncertain => 1,
  Classification.clean => 2,
  // Never ranked; isValid excludes it.
  Classification.notEvaluated => 3,
};
