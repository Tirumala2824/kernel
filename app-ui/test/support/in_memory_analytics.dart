// Test-only AnalyticsService computed from the in-memory repositories.
// Next actions are scripted per role so tests can drive every kind.

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';
import 'in_memory_inventory.dart';
import 'in_memory_records.dart';

class InMemoryAnalyticsService implements AnalyticsService {
  InMemoryAnalyticsService(
    this.items,
    this.scans,
    this.inspections,
    this.locations,
  );

  final InMemoryItemRepository items;
  final InMemoryScanRepository scans;
  final InMemoryInspectionRepository inspections;
  final InMemoryLocationRepository locations;
  final _changes = Changes();
  final _next = <Role, List<NextAction>>{};

  /// Every filter a watch* stream was opened with.
  final filters = <AnalyticsFilter>[];
  final summarizeCalls = <ReportScope>[];

  /// Next actions for [role]; emitted to open streams immediately.
  void setNextActions(Role role, List<NextAction> actions) {
    _next[role] = actions;
    _changes.notify();
  }

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((sink) {
    void emit(void _) => sink.add(read());
    emit(null);
    final subs = [
      items.changes.listen(emit),
      scans.changes.listen(emit),
      inspections.changes.listen(emit),
      _changes.stream.listen(emit),
    ];
    sink.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };
  });

  bool _within(String? locationId, String scope) {
    var current = locationId;
    for (var depth = 0; current != null && depth < 10; depth++) {
      if (current == scope) return true;
      current = locations.locations
          .where((x) => x.id == current)
          .firstOrNull
          ?.parentId;
    }
    return false;
  }

  List<GrainItem> _itemsIn(AnalyticsFilter f) => items.items
      .where(
        (i) =>
            !i.isArchived &&
            (f.role == null || i.ownerRole == f.role) &&
            (f.locationId == null || _within(i.locationId, f.locationId!)) &&
            (f.lotId == null || i.lotId == f.lotId),
      )
      .toList();

  List<ScanRecord> _scansIn(AnalyticsFilter f) {
    final ids = {for (final i in _itemsIn(f)) i.id};
    final window = f.window;
    final since = window == null ? null : DateTime.now().subtract(window);
    return scans.scans
        .where(
          (s) =>
              ids.contains(s.itemId) &&
              (since == null || !s.capturedAt.isBefore(since)),
        )
        .toList();
  }

  ResultRates _rates(AnalyticsFilter f) {
    var clean = 0, uncertain = 0, infested = 0, notEvaluated = 0, retry = 0;
    for (final s in _scansIn(f)) {
      if (s.quality == ScanQuality.retry) {
        retry++;
        continue;
      }
      switch (s.result) {
        case Classification.clean:
          clean++;
        case Classification.uncertain:
          uncertain++;
        case Classification.infested:
          infested++;
        case Classification.notEvaluated:
          notEvaluated++;
      }
    }
    return ResultRates(
      clean: clean,
      uncertain: uncertain,
      infested: infested,
      notEvaluated: notEvaluated,
      retry: retry,
    );
  }

  QualityFailures _quality(AnalyticsFilter f) {
    final counts = <QualityReason, int>{};
    for (final s in _scansIn(f)) {
      if (s.quality != ScanQuality.retry) continue;
      for (final reason in s.qualityReasons) {
        counts[reason] = (counts[reason] ?? 0) + 1;
      }
    }
    return QualityFailures(counts);
  }

  List<ItemFreshness> _freshness(AnalyticsFilter f) {
    final now = DateTime.now();
    final list = [
      for (final item in _itemsIn(f))
        () {
          final latest =
              (scans.scans.where((s) => s.itemId == item.id).toList()
                    ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)))
                  .firstOrNull;
          return ItemFreshness(
            itemId: item.id,
            label: item.label,
            lastScanAt: latest?.capturedAt,
            daysSinceLastScan: latest == null
                ? null
                : now.difference(latest.capturedAt).inDays,
            lastResult: latest?.result,
          );
        }(),
    ];
    list.sort((a, b) {
      final da = a.daysSinceLastScan, db = b.daysSinceLastScan;
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return db.compareTo(da);
    });
    return list;
  }

  InspectionStats _inspections(AnalyticsFilter f) {
    final ids = {for (final i in _itemsIn(f)) i.id};
    var open = 0, inProgress = 0, done = 0;
    for (final i in inspections.inspections.where(
      (i) => ids.contains(i.itemId),
    )) {
      switch (i.followUpStatus) {
        case FollowUpStatus.open:
          open++;
        case FollowUpStatus.inProgress:
          inProgress++;
        case FollowUpStatus.done:
          done++;
      }
    }
    return InspectionStats(open: open, inProgress: inProgress, done: done);
  }

  ScanActivity _activity(AnalyticsFilter f) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final weekStart = midnight.subtract(const Duration(days: 6));
    final all = _scansIn(AnalyticsFilter(
      role: f.role,
      locationId: f.locationId,
      lotId: f.lotId,
    ));
    return ScanActivity(
      today: all.where((s) => !s.capturedAt.isBefore(midnight)).length,
      last7Days: all.where((s) => !s.capturedAt.isBefore(weekStart)).length,
    );
  }

  @override
  Stream<ResultRates> watchResultRates([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) {
    filters.add(filter);
    return _watch(() => _rates(filter));
  }

  @override
  Stream<QualityFailures> watchQualityFailures([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) {
    filters.add(filter);
    return _watch(() => _quality(filter));
  }

  @override
  Stream<List<ItemFreshness>> watchItemFreshness([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) {
    filters.add(filter);
    return _watch(() => _freshness(filter));
  }

  @override
  Stream<InspectionStats> watchInspectionStats([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) {
    filters.add(filter);
    return _watch(() => _inspections(filter));
  }

  @override
  Stream<ScanActivity> watchScanActivity([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) {
    filters.add(filter);
    return _watch(() => _activity(filter));
  }

  @override
  Stream<List<NextAction>> watchNextActions(Role role) =>
      _watch(() => List.of(_next[role] ?? const <NextAction>[]));

  @override
  Future<AnalyticsSummary> summarize(ReportScope scope) async {
    summarizeCalls.add(scope);
    final f = AnalyticsFilter(
      role: scope.role,
      locationId: scope.locationId,
      lotId: scope.lotId,
    );
    final scoped = _itemsIn(f)
        .where((i) => scope.harvestId == null || i.harvestId == scope.harvestId)
        .toList();
    final inScope = _scansIn(f)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final needScan = scoped
        .where((i) => !scans.scans.any((s) => s.itemId == i.id && s.isValid))
        .length;
    return AnalyticsSummary(
      role: scope.role,
      kind: scope.kind,
      items: scoped.length,
      itemsNeedingScan: needScan,
      rates: _rates(f),
      quality: _quality(f),
      inspections: _inspections(f),
      firstScanAt: inScope.firstOrNull?.capturedAt,
      lastScanAt: inScope.lastOrNull?.capturedAt,
    );
  }
}
