import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'scope.dart';

/// F08 inspection queue, following the ranking rule in docs/contracts.md.
///
/// The stream recomputes when items, scans or locations change. `maxAge`
/// and `QueueEntry.ageDays` are measured from the injected clock at that
/// moment; the stream does not tick on its own.
class DriftRankingService implements RankingService {
  DriftRankingService(this._db, [Clock? clock]) : _clock = clock ?? systemClock;

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Stream<InspectionQueue> watchQueue({
    Role? role,
    String? locationId,
    String? lotId,
    Classification? result,
    Duration? maxAge,
  }) {
    return watchTables(
      _db,
      {_db.items, _db.scans, _db.locations},
      () => _compute(
        role: role,
        locationId: locationId,
        lotId: lotId,
        result: result,
        maxAge: maxAge,
      ),
    );
  }

  Future<InspectionQueue> _compute({
    Role? role,
    String? locationId,
    String? lotId,
    Classification? result,
    Duration? maxAge,
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
    final latestValid = await latestValidScans(_db, [
      for (final item in items) item.id,
    ]);
    return rankQueue(
      [for (final item in items) item.toModel()],
      latestValid,
      now: _clock(),
      result: result,
      maxAge: maxAge,
    );
  }
}

/// Latest valid scan (quality PASS, result not notEvaluated) per item id.
/// Items without one are absent.
Future<Map<String, ScanRecord>> latestValidScans(
  KernelDatabase db,
  List<String> itemIds,
) async {
  if (itemIds.isEmpty) return {};
  final candidates =
      await (db.select(db.scans)
            ..where(
              (s) =>
                  s.itemId.isIn(itemIds) &
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
  return latestValid;
}

/// Pure ranking rule.
///
/// 1. Each item's latest valid scan (quality PASS, result not notEvaluated)
///    is its candidate. With [maxAge], a candidate captured more than
///    [maxAge] before [now] is too old to compare: its item goes to
///    needsScan and the remaining steps only see fresh candidates.
/// 2. The queue's model version is the one shared by the most candidates.
///    A tie goes to the version with the most recent scan, then to the
///    lexicographically greatest version string, so the output is
///    deterministic.
/// 3. Items whose candidate uses that version are ranked infested >
///    uncertain > clean, then oldest scan first.
/// 4. Every other item (no valid scan, a different model version, or a
///    candidate older than [maxAge]) goes to needsScan, keeping the input
///    order.
/// 5. [result] then keeps only the ranked entries whose candidate has that
///    class. It never changes the model version or needsScan.
///
/// `QueueEntry.ageDays` is the whole number of days from the candidate's
/// capture to [now] (never negative), or null without [now]. [maxAge]
/// requires [now].
InspectionQueue rankQueue(
  List<GrainItem> items,
  Map<String, ScanRecord> latestValidByItem, {
  DateTime? now,
  Classification? result,
  Duration? maxAge,
}) {
  if (maxAge != null && now == null) {
    throw ArgumentError.value(maxAge, 'maxAge', 'needs now');
  }
  ScanRecord? candidateOf(GrainItem item) {
    final scan = latestValidByItem[item.id];
    if (scan == null || !scan.isValid) return null;
    if (maxAge != null && now!.difference(scan.capturedAt) > maxAge) {
      return null;
    }
    return scan;
  }

  final counts = <String, int>{};
  final newest = <String, DateTime>{};
  for (final item in items) {
    final scan = candidateOf(item);
    if (scan == null) continue;
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
    final scan = candidateOf(item);
    if (scan != null && scan.modelVersion == version) {
      ranked.add(
        QueueEntry(
          item: item,
          latestValidScan: scan,
          ageDays: now == null ? null : wholeDaysBetween(scan.capturedAt, now),
        ),
      );
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
  final kept = result == null
      ? ranked
      : [
          for (final entry in ranked)
            if (entry.latestValidScan.result == result) entry,
        ];

  return InspectionQueue(
    ranked: List.unmodifiable(kept),
    needsScan: List.unmodifiable(needsScan),
    modelVersion: kept.isEmpty ? null : version,
  );
}

/// Whole days from [from] to [to], never negative.
int wholeDaysBetween(DateTime from, DateTime to) {
  final days = to.difference(from).inDays;
  return days < 0 ? 0 : days;
}

int _severity(Classification result) => switch (result) {
  Classification.infested => 0,
  Classification.uncertain => 1,
  Classification.clean => 2,
  // Never ranked; isValid excludes it.
  Classification.notEvaluated => 3,
};
