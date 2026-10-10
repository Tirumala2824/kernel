import 'enums.dart';

// Value types for on-device analytics. Computed locally from stored records
// only; nothing here is sent anywhere. The service interface lives in
// repositories.dart.

/// Optional narrowing for analytics streams. Filters combine as AND.
class AnalyticsFilter {
  const AnalyticsFilter({this.role, this.locationId, this.lotId, this.window});

  final Role? role;

  /// Includes nested locations, like ranking and reports.
  final String? locationId;
  final String? lotId;

  /// Only scans captured, and inspections inspected, within this duration
  /// before now. Item freshness ignores it. Null = all time.
  final Duration? window;
}

/// Result counts over the scans in scope (each scan counted once).
class ResultRates {
  const ResultRates({
    required this.clean,
    required this.uncertain,
    required this.infested,
    required this.notEvaluated,
    required this.retry,
  });

  final int clean;
  final int uncertain;
  final int infested;

  /// PASS recordings with no model result.
  final int notEvaluated;

  /// Recordings rejected by the quality gate.
  final int retry;

  /// PASS recordings with a real model result.
  int get valid => clean + uncertain + infested;
  int get total => valid + notEvaluated + retry;

  /// Over valid scans only; null when there are none.
  double? get infestedRate => valid == 0 ? null : infested / valid;
  double? get uncertainRate => valid == 0 ? null : uncertain / valid;
}

/// How often each quality reason caused a RETRY.
class QualityFailures {
  const QualityFailures(this.counts);

  final Map<QualityReason, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

class ItemFreshness {
  const ItemFreshness({
    required this.itemId,
    required this.label,
    required this.lastScanAt,
    required this.daysSinceLastScan,
    required this.lastResult,
  });

  final String itemId;

  /// User-entered item label (data, not UI copy).
  final String label;
  final DateTime? lastScanAt;

  /// Null when the item has never been scanned.
  final int? daysSinceLastScan;

  /// Result of the latest scan of any quality; null when never scanned.
  final Classification? lastResult;
}

class InspectionStats {
  const InspectionStats({
    required this.open,
    required this.inProgress,
    required this.done,
  });

  final int open;
  final int inProgress;
  final int done;

  int get total => open + inProgress + done;

  /// Share of inspections whose follow-up is done; null when there are none.
  double? get closureRate => total == 0 ? null : done / total;
}

class ScanActivity {
  const ScanActivity({required this.today, required this.last7Days});

  /// Scans since local midnight.
  final int today;

  /// Scans in the rolling last 7 days, including today.
  final int last7Days;
}

/// What the user should do next. The UI turns [kind] into localized copy.
enum NextActionKind {
  registerFirst,
  scanNeeded,
  inspectFlagged,
  reviewDue,
  reminderDue,
  physicalCheckPending,
  finishBatch,
  exportPreSale,
  exportLotSummary,
}

class NextAction {
  const NextAction({
    required this.kind,
    required this.priority,
    this.count = 1,
    this.itemId,
    this.lotId,
    this.harvestId,
    this.locationId,
    this.label,
  });

  final NextActionKind kind;

  /// Lower is more urgent. Lists are sorted ascending.
  final int priority;

  /// How many records the action covers (e.g. sacks needing a scan).
  final int count;
  final String? itemId;
  final String? lotId;
  final String? harvestId;
  final String? locationId;

  /// User-entered label of the target record, if a single one.
  final String? label;
}

/// Aggregate figures for a report scope. Input to report narratives.
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.role,
    required this.kind,
    required this.items,
    required this.itemsNeedingScan,
    required this.rates,
    required this.quality,
    required this.inspections,
    required this.firstScanAt,
    required this.lastScanAt,
  });

  final Role role;
  final ReportKind kind;
  final int items;
  final int itemsNeedingScan;
  final ResultRates rates;
  final QualityFailures quality;
  final InspectionStats inspections;
  final DateTime? firstScanAt;
  final DateTime? lastScanAt;
}
