import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';

/// Append-only scan history. There is deliberately no update and no single
/// delete; the only removal path is PrivacyService.deleteAllHistory.
class DriftScanRepository implements ScanRepository {
  DriftScanRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  @override
  Future<ScanRecord> record(ScanOutcome outcome) async {
    final violations = outcome.invariantViolations();
    if (violations.isNotEmpty) {
      throw ArgumentError.value(
        outcome.scanId,
        'outcome',
        'refusing to persist an invalid scan: ${violations.join('; ')}',
      );
    }
    if (outcome.scanId.trim().isEmpty) {
      throw ArgumentError.value(outcome.scanId, 'outcome.scanId', 'is blank');
    }
    return _db.transaction(() async {
      final item = await (_db.select(
        _db.items,
      )..where((i) => i.id.equals(outcome.itemId))).getSingleOrNull();
      if (item == null) {
        throw ArgumentError.value(
          outcome.itemId,
          'outcome.itemId',
          'unknown item',
        );
      }
      final existing = await (_db.select(
        _db.scans,
      )..where((s) => s.id.equals(outcome.scanId))).getSingleOrNull();
      if (existing != null) {
        throw StateError(
          'Scan ${outcome.scanId} is already recorded; '
          'scan history is append-only',
        );
      }
      final now = _clock().toUtc();
      final row = await _db
          .into(_db.scans)
          .insertReturning(
            ScansCompanion.insert(
              id: outcome.scanId,
              createdAt: now,
              updatedAt: now,
              itemId: outcome.itemId,
              capturedAt: outcome.capturedAt.toUtc(),
              durationMs: outcome.durationMs,
              sampleRate: outcome.sampleRate,
              quality: outcome.quality,
              qualityReasons: List.of(outcome.qualityReasons),
              modelVersion: outcome.modelVersion,
              result: outcome.classification,
              confidence: Value(outcome.confidence),
              experimental: outcome.experimental,
              latencyMs: outcome.latencyMs,
              deviceModel: outcome.deviceModel,
              osVersion: outcome.osVersion,
            ),
          );
      return row.toModel();
    });
  }

  /// Newest first.
  @override
  Stream<List<ScanRecord>> watchForItem(String itemId) {
    final query = _db.select(_db.scans)
      ..where((s) => s.itemId.equals(itemId))
      ..orderBy(_newestFirst);
    return query.watch().map(_toModels);
  }

  /// Newest first, across all items.
  @override
  Stream<List<ScanRecord>> watchRecent({int limit = 50}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }
    final query = _db.select(_db.scans)
      ..orderBy(_newestFirst)
      ..limit(limit);
    return query.watch().map(_toModels);
  }

  @override
  Future<ScanRecord?> latestValidForItem(String itemId) async {
    // Same predicate as ScanRecord.isValid, applied in Dart so the contract
    // stays the single definition.
    final rows =
        await (_db.select(_db.scans)
              ..where(
                (s) =>
                    s.itemId.equals(itemId) &
                    s.quality.equalsValue(ScanQuality.pass),
              )
              ..orderBy(_newestFirst))
            .get();
    for (final row in rows) {
      final record = row.toModel();
      if (record.isValid) return record;
    }
    return null;
  }

  static final _newestFirst = <OrderClauseGenerator<$ScansTable>>[
    (s) => OrderingTerm.desc(s.capturedAt),
    (s) => OrderingTerm.desc(s.createdAt),
    (s) => OrderingTerm.desc(s.id),
  ];

  static List<ScanRecord> _toModels(List<ScanRow> rows) => [
    for (final row in rows) row.toModel(),
  ];
}
