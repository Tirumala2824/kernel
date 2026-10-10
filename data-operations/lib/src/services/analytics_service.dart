import 'dart:async';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../repositories/sighting_repository.dart' show activeSightings;
import '../support.dart';
import 'ranking_service.dart' show wholeDaysBetween;
import 'scope.dart';

/// On-device analytics, computed only from the stored records. Nothing is
/// cached, stored or sent anywhere.
///
/// Scope rules shared by every `watch*` metric (filters combine as AND):
/// - only non-archived items count, and only their scans and inspections;
/// - `role` keeps items owned by that role, `locationId` keeps items in that
///   location or one nested below it, `lotId` keeps items in that lot;
/// - `window` keeps scans captured, and inspections inspected, at or after
///   `now - window`, with now from the injected clock. Item freshness is a
///   property of the items, so it ignores the window.
///
/// Streams recompute whenever a table they read changes. Time-based values
/// (window, today, staleness) use the clock at that moment; the streams do
/// not tick on their own.
///
/// Next-action rules: see `watchNextActions` and the README.
class DriftAnalyticsService implements AnalyticsService {
  /// [sensorAttention] emits the ids of nodes that are jammed, clipped, low
  /// on battery or need a survey (node status is live link state and is not
  /// stored). It is listened to once, from construction until [dispose];
  /// until it emits, no node needs attention, and its errors are ignored.
  DriftAnalyticsService(
    this._db, [
    Clock? clock,
    Stream<Set<String>>? sensorAttention,
  ]) : _clock = clock ?? systemClock {
    if (sensorAttention != null) {
      _attentionSub = sensorAttention.listen((ids) {
        _attention = Set.unmodifiable(ids);
        if (!_attentionTicks.isClosed) _attentionTicks.add(null);
      }, onError: (Object _) {});
    }
  }

  final KernelDatabase _db;
  final Clock _clock;
  StreamSubscription<Set<String>>? _attentionSub;
  Set<String> _attention = const {};
  final _attentionTicks = StreamController<void>.broadcast();

  /// Stops listening to the sensor attention stream.
  Future<void> dispose() async {
    await _attentionSub?.cancel();
    _attentionSub = null;
    await _attentionTicks.close();
  }

  @override
  Stream<ResultRates> watchResultRates([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) => _watch({
    _db.items,
    _db.locations,
    _db.scans,
  }, () async => resultRatesOf((await _slice(filter)).windowScans));

  @override
  Stream<QualityFailures> watchQualityFailures([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) => _watch({
    _db.items,
    _db.locations,
    _db.scans,
  }, () async => qualityFailuresOf((await _slice(filter)).windowScans));

  /// Never-scanned items first (in label order), then the most stale. The
  /// latest scan of any quality counts as the last scan.
  @override
  Stream<List<ItemFreshness>> watchItemFreshness([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) => _watch({_db.items, _db.locations, _db.scans}, () async {
    final s = await _slice(filter);
    return itemFreshnessOf(s.items, s.scansByItem, s.now);
  });

  @override
  Stream<InspectionStats> watchInspectionStats([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) => _watch({
    _db.items,
    _db.locations,
    _db.inspections,
  }, () async => inspectionStatsOf((await _slice(filter)).windowInspections));

  /// `today` counts scans captured since local midnight, `last7Days` those
  /// in the rolling 7 × 24 h before now. Both also honour the filter window.
  @override
  Stream<ScanActivity> watchScanActivity([
    AnalyticsFilter filter = const AnalyticsFilter(),
  ]) => _watch({_db.items, _db.locations, _db.scans}, () async {
    final s = await _slice(filter);
    return scanActivityOf(s.windowScans, s.now);
  });

  /// Deterministic, rule-based next steps for [role]'s non-archived records;
  /// the rules are listed on [nextActionsFor] and in the README.
  ///
  /// Recomputes on a change to any table it reads and whenever the sensor
  /// attention stream emits.
  @override
  Stream<List<NextAction>> watchNextActions(Role role) {
    final tables = <ResultSetImplementation<dynamic, dynamic>>{
      _db.items,
      _db.locations,
      _db.lots,
      _db.harvests,
      _db.scans,
      _db.inspections,
      _db.reminders,
      _db.sightings,
      _db.sensorNodes,
      _db.sensorEvents,
    };
    StreamSubscription<void>? tableSub;
    StreamSubscription<void>? attentionSub;
    late final StreamController<void> ticks;
    ticks = StreamController<void>(
      onListen: () {
        tableSub = _db
            .customSelect('SELECT 1', readsFrom: tables)
            .watch()
            .listen((_) => ticks.add(null), onError: ticks.addError);
        attentionSub = _attentionTicks.stream.listen((_) => ticks.add(null));
      },
      onPause: () {
        tableSub?.pause();
        attentionSub?.pause();
      },
      onResume: () {
        tableSub?.resume();
        attentionSub?.resume();
      },
      onCancel: () async {
        await attentionSub?.cancel();
        await tableSub?.cancel();
      },
    );
    return ticks.stream.asyncMap((_) => _nextActions(role));
  }

  /// Aggregates over the same items as `ReportService.export(scope, ...)`
  /// (role, nested location, lot, harvest and item ids, non-archived), and
  /// over all of their scans and inspections, so the counts match the
  /// report. `itemsNeedingScan` counts items with no valid scan.
  @override
  Future<AnalyticsSummary> summarize(ReportScope scope) {
    return _db.transaction(() async {
      final rows = await itemsInScope(
        _db,
        role: scope.role,
        locationId: scope.locationId,
        lotId: scope.lotId,
        harvestId: scope.harvestId,
        itemIds: scope.itemIds,
      );
      final ids = [for (final row in rows) row.id];
      final scans = await _scansOf(ids);
      final inspections = await _inspectionsOf(ids);
      final validItems = {
        for (final scan in scans)
          if (scan.isValid) scan.itemId,
      };
      DateTime? first;
      DateTime? last;
      for (final scan in scans) {
        if (first == null || scan.capturedAt.isBefore(first)) {
          first = scan.capturedAt;
        }
        if (last == null || scan.capturedAt.isAfter(last)) {
          last = scan.capturedAt;
        }
      }
      return AnalyticsSummary(
        role: scope.role,
        kind: scope.kind,
        items: rows.length,
        itemsNeedingScan: rows.where((r) => !validItems.contains(r.id)).length,
        rates: resultRatesOf(scans),
        quality: qualityFailuresOf(scans),
        inspections: inspectionStatsOf(inspections),
        firstScanAt: first,
        lastScanAt: last,
      );
    });
  }

  Stream<T> _watch<T>(
    Set<ResultSetImplementation<dynamic, dynamic>> tables,
    Future<T> Function() compute,
  ) => watchTables(_db, tables, compute);

  Future<_Slice> _slice(AnalyticsFilter filter) {
    return _db.transaction(() async {
      final now = _clock();
      final rows = await itemsInScope(
        _db,
        role: filter.role,
        locationId: filter.locationId,
        lotId: filter.lotId,
      );
      final ids = [for (final row in rows) row.id];
      final window = filter.window;
      return _Slice(
        now: now,
        since: window == null ? null : now.subtract(window),
        items: [for (final row in rows) row.toModel()],
        scans: await _scansOf(ids),
        inspections: await _inspectionsOf(ids),
      );
    });
  }

  Future<List<NextAction>> _nextActions(Role role) {
    return _db.transaction(() async {
      final rows = await itemsInScope(_db, role: role);
      final ids = [for (final row in rows) row.id];
      final reminders = ids.isEmpty
          ? const <ReminderRow>[]
          : await (_db.select(
              _db.reminders,
            )..where((r) => r.itemId.isIn(ids))).get();
      final locations = await (_db.select(
        _db.locations,
      )..where((l) => l.archivedAt.isNull())).get();
      final lots = await (_db.select(
        _db.lots,
      )..where((l) => l.archivedAt.isNull())).get();
      final harvests = await (_db.select(
        _db.harvests,
      )..where((h) => h.archivedAt.isNull())).get();
      final now = _clock();
      final nodes = await _db.select(_db.sensorNodes).get();
      final eventsSince = now.toUtc().subtract(sensorActivityWindow);
      final events = await (_db.select(_db.sensorEvents)..where(
            (e) =>
                e.signatureId.isNotNull() &
                e.startedAt.isBiggerOrEqualValue(eventsSince),
          ))
          .get();
      // Every unverified sighting can raise a safety alert, so all of the
      // role's active sightings are read, not just the last 7 days.
      final sightings = await activeSightings(_db, role: role);
      return nextActionsFor(
        role,
        now: now,
        items: [for (final row in rows) row.toModel()],
        scans: await _scansOf(ids),
        inspections: await _inspectionsOf(ids),
        reminders: [for (final row in reminders) row.toModel()],
        locations: [for (final row in locations) row.toModel()],
        lots: [for (final row in lots) row.toModel()],
        harvests: [for (final row in harvests) row.toModel()],
        sightings: sightings,
        sensorNodes: [for (final row in nodes) row.toModel()],
        sensorEvents: [
          for (final row in events)
            PlacedSensorEvent(
              row.toModel(),
              locationId: row.locationId,
              itemId: row.itemId,
            ),
        ],
        nodesNeedingAttention: _attention,
      );
    });
  }

  /// Newest first.
  Future<List<ScanRecord>> _scansOf(List<String> itemIds) async {
    if (itemIds.isEmpty) return const [];
    final rows =
        await (_db.select(_db.scans)
              ..where((s) => s.itemId.isIn(itemIds))
              ..orderBy([
                (s) => OrderingTerm.desc(s.capturedAt),
                (s) => OrderingTerm.desc(s.createdAt),
                (s) => OrderingTerm.desc(s.id),
              ]))
            .get();
    return [for (final row in rows) row.toModel()];
  }

  Future<List<Inspection>> _inspectionsOf(List<String> itemIds) async {
    if (itemIds.isEmpty) return const [];
    final rows = await (_db.select(
      _db.inspections,
    )..where((i) => i.itemId.isIn(itemIds))).get();
    return [for (final row in rows) row.toModel()];
  }
}

class _Slice {
  _Slice({
    required this.now,
    required this.since,
    required this.items,
    required this.scans,
    required this.inspections,
  });

  final DateTime now;

  /// Start of the filter window, or null for all time.
  final DateTime? since;
  final List<GrainItem> items;

  /// Every scan of [items], newest first.
  final List<ScanRecord> scans;
  final List<Inspection> inspections;

  bool _inWindow(DateTime at) => since == null || !at.isBefore(since!);

  Iterable<ScanRecord> get windowScans =>
      scans.where((s) => _inWindow(s.capturedAt));

  Iterable<Inspection> get windowInspections =>
      inspections.where((i) => _inWindow(i.inspectedAt));

  /// Newest first per item.
  Map<String, List<ScanRecord>> get scansByItem {
    final byItem = <String, List<ScanRecord>>{};
    for (final scan in scans) {
      byItem.putIfAbsent(scan.itemId, () => []).add(scan);
    }
    return byItem;
  }
}

/// Each scan counted once: RETRY as retry, PASS without a model result as
/// notEvaluated, every other PASS by its class.
ResultRates resultRatesOf(Iterable<ScanRecord> scans) {
  var clean = 0, uncertain = 0, infested = 0, notEvaluated = 0, retry = 0;
  for (final scan in scans) {
    if (scan.quality == ScanQuality.retry) {
      retry++;
      continue;
    }
    switch (scan.result) {
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

/// Every [QualityReason] (in enum order, zero when unseen) with the number
/// of RETRY scans that carried it. A scan with several reasons counts once
/// for each.
QualityFailures qualityFailuresOf(Iterable<ScanRecord> scans) {
  final counts = {for (final reason in QualityReason.values) reason: 0};
  for (final scan in scans) {
    if (scan.quality != ScanQuality.retry) continue;
    for (final reason in scan.qualityReasons.toSet()) {
      counts[reason] = counts[reason]! + 1;
    }
  }
  return QualityFailures(Map.unmodifiable(counts));
}

InspectionStats inspectionStatsOf(Iterable<Inspection> inspections) {
  var open = 0, inProgress = 0, done = 0;
  for (final inspection in inspections) {
    switch (inspection.followUpStatus) {
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

/// Local midnight of [now]'s calendar day.
DateTime localMidnight(DateTime now) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day);
}

ScanActivity scanActivityOf(Iterable<ScanRecord> scans, DateTime now) {
  final midnight = localMidnight(now);
  final weekStart = now.subtract(const Duration(days: 7));
  var today = 0, week = 0;
  for (final scan in scans) {
    if (!scan.capturedAt.isBefore(midnight)) today++;
    if (!scan.capturedAt.isBefore(weekStart)) week++;
  }
  return ScanActivity(today: today, last7Days: week);
}

/// [items] in their given order with their latest scan (of any quality);
/// never-scanned first, then oldest last scan first.
List<ItemFreshness> itemFreshnessOf(
  List<GrainItem> items,
  Map<String, List<ScanRecord>> scansByItemNewestFirst,
  DateTime now,
) {
  final never = <ItemFreshness>[];
  final scanned = <ItemFreshness>[];
  for (final item in items) {
    final latest = scansByItemNewestFirst[item.id]?.firstOrNull;
    final entry = ItemFreshness(
      itemId: item.id,
      label: item.label,
      lastScanAt: latest?.capturedAt,
      daysSinceLastScan: latest == null
          ? null
          : wholeDaysBetween(latest.capturedAt, now),
      lastResult: latest?.result,
    );
    (latest == null ? never : scanned).add(entry);
  }
  final order = {for (var i = 0; i < items.length; i++) items[i].id: i};
  scanned.sort((a, b) {
    final byAge = a.lastScanAt!.compareTo(b.lastScanAt!);
    if (byAge != 0) return byAge;
    return order[a.itemId]!.compareTo(order[b.itemId]!);
  });
  return List.unmodifiable([...never, ...scanned]);
}

/// Priorities of the next-action rules (lower is more urgent).
abstract final class NextActionPriority {
  static const registerFirst = 0;
  static const pestSafetyAlert = 1;
  static const reminderDue = 5;
  static const inspectFlagged = 10;
  static const physicalCheckPending = 10;
  static const pestSightingsRepeated = 12;
  static const sensorActivity = 12;
  static const reviewDue = 15;
  static const finishBatch = 15;
  static const scanNeeded = 20;
  static const sensorNeedsAttention = 25;
  static const exportPreSale = 40;
  static const exportLotSummary = 40;
}

/// Farmer/FPO: a sack needs a scan when its latest PASS scan is older.
const scanNeededAfter = Duration(days: 14);

/// Household: a container is due for review after this many days.
const reviewDueAfterDays = 30;

/// Pest ID: the same card this many times in one location ...
const repeatedSightingsMin = 3;

/// ... within this rolling window counts as repeated.
const repeatedSightingsWindow = Duration(days: 7);

/// Sensors: this many signature-matched events on one placed node ...
const sensorActivityMin = 5;

/// ... within this rolling window counts as activity.
const sensorActivityWindow = Duration(hours: 24);

/// Safety levels that raise a [NextActionKind.pestSafetyAlert].
const alertSafetyLevels = {
  SafetyLevel.medicalRisk,
  SafetyLevel.venomous,
  SafetyLevel.protectedWildlife,
};

/// A sensor event with the node placement it was recorded under.
class PlacedSensorEvent {
  const PlacedSensorEvent(this.event, {this.locationId, this.itemId});

  final SensorEvent event;
  final String? locationId;
  final String? itemId;
}

/// Pure next-action rules for [role]. [items] are [role]'s non-archived
/// items; [scans], [inspections] and [reminders] belong to them;
/// [locations], [lots] and [harvests] are the non-archived ones.
///
/// Terms:
/// - latest PASS scan: the newest scan with quality PASS (any result);
/// - latest valid scan: the newest PASS scan with a model result;
/// - flagged: the latest valid scan is infested or uncertain and no
///   inspection of the item addresses it (an inspection addresses it when
///   it links that scan or was inspected at or after its capture);
/// - open inspection: follow-up open or inProgress;
/// - today: since local midnight.
///
/// Rules (priority):
/// - every role: registerFirst (0) when [role] has no items; for the buyer,
///   when there are no lots.
/// - household: reminderDue (5) for items with a reminder that fired or is
///   past due and is not done or cancelled; reviewDue (15) for items with
///   no PASS scan or whose latest PASS scan is at least 30 whole days old.
/// - farmer, household, storageFpo: inspectFlagged (10) for flagged items.
///   The buyer gets it only for flagged sacks outside a listed lot.
/// - farmer, storageFpo: scanNeeded (20) for items with no PASS scan or
///   whose latest PASS scan is more than 14 days old.
/// - storageFpo: finishBatch (15) per location (locationId, label = name)
///   where at least one sack has a PASS scan today and at least one has
///   not; count = sacks still to do.
/// - farmer: exportPreSale (40) per harvest (harvestId, label = name, count
///   = sacks) whose sacks all have a PASS scan within the last 14 days,
///   none is flagged and none has an open inspection.
/// - buyer, per lot (lotId, label = code) over its buyer sacks:
///   physicalCheckPending (10) when sacks are flagged (count = flagged);
///   scanNeeded (20) for sacks with no PASS scan and no inspection;
///   exportLotSummary (40, count = sacks) when every sack has a valid scan
///   or an inspection, none is flagged and the screening status is not
///   reviewed.
///
/// Item-level actions (reminderDue, reviewDue, inspectFlagged, farmer/FPO
/// scanNeeded) are aggregated into one action whose count is the number of
/// items; itemId and label are set only when that count is 1.
///
/// Pest ID and sensor rules, for every role. [sightings] are [role]'s
/// sightings outside archived locations and items; [sensorNodes] are all
/// paired nodes; [sensorEvents] are the signature-matched events of the
/// last 24 h with the placement they were recorded under;
/// [nodesNeedingAttention] are node ids reported jammed, clipped, low on
/// battery or needing a survey. A node or event placed on an item counts
/// only for the role owning that (non-archived) item; one placed only in a
/// location counts for every role.
/// - pestSafetyAlert (1): sightings whose AI analysis safety is
///   medicalRisk, venomous or protectedWildlife and which have no verified
///   finding yet. One action; count = sightings; locationId / itemId and
///   label (item label, else location name) only when count is 1.
/// - pestSightingsRepeated (12), per location (locationId, label = name):
///   at least 3 user-validated sightings of the same card (the user's
///   corrected card if any, else the AI's) observed there in the last 7
///   days; count = sightings of the most repeated card.
/// - sensorActivity (12), per placement (itemId and/or locationId, label =
///   item label, else location name): the placement has nodes with at
///   least 5 signature-matched events each in the last 24 h; count = those
///   events. Unplaced nodes and archived placements never count.
/// - sensorNeedsAttention (25): known nodes in [nodesNeedingAttention].
///   One action; count = nodes; label = node name and the node's placement
///   only when count is 1.
///
/// Sorted by priority, then kind (enum order), then label, then target id.
List<NextAction> nextActionsFor(
  Role role, {
  required DateTime now,
  required List<GrainItem> items,
  required List<ScanRecord> scans,
  required List<Inspection> inspections,
  required List<Reminder> reminders,
  required List<Location> locations,
  required List<Lot> lots,
  required List<Harvest> harvests,
  List<Sighting> sightings = const [],
  List<SensorNode> sensorNodes = const [],
  List<PlacedSensorEvent> sensorEvents = const [],
  Set<String> nodesNeedingAttention = const {},
}) {
  final latestPass = <String, ScanRecord>{};
  final latestValid = <String, ScanRecord>{};
  for (final scan in _newestFirst(scans)) {
    if (scan.quality != ScanQuality.pass) continue;
    latestPass.putIfAbsent(scan.itemId, () => scan);
    if (scan.isValid) latestValid.putIfAbsent(scan.itemId, () => scan);
  }
  final inspectionsByItem = <String, List<Inspection>>{};
  for (final inspection in inspections) {
    inspectionsByItem.putIfAbsent(inspection.itemId, () => []).add(inspection);
  }

  bool flagged(GrainItem item) {
    final scan = latestValid[item.id];
    if (scan == null) return false;
    if (scan.result != Classification.infested &&
        scan.result != Classification.uncertain) {
      return false;
    }
    final checks = inspectionsByItem[item.id] ?? const <Inspection>[];
    return !checks.any(
      (i) => i.scanId == scan.id || !i.inspectedAt.isBefore(scan.capturedAt),
    );
  }

  bool hasOpenInspection(GrainItem item) =>
      (inspectionsByItem[item.id] ?? const <Inspection>[]).any(
        (i) => i.followUpStatus != FollowUpStatus.done,
      );

  bool passWithin(GrainItem item, Duration age) {
    final scan = latestPass[item.id];
    return scan != null && now.difference(scan.capturedAt) <= age;
  }

  final actions = <NextAction>[];

  void addAggregate(NextActionKind kind, int priority, List<GrainItem> hits) {
    if (hits.isEmpty) return;
    final single = hits.length == 1 ? hits.single : null;
    actions.add(
      NextAction(
        kind: kind,
        priority: priority,
        count: hits.length,
        itemId: single?.id,
        label: single?.label,
      ),
    );
  }

  final noRecords = role == Role.buyer ? lots.isEmpty : items.isEmpty;
  if (noRecords) {
    actions.add(
      const NextAction(
        kind: NextActionKind.registerFirst,
        priority: NextActionPriority.registerFirst,
      ),
    );
  }

  final lotIds = {for (final lot in lots) lot.id};
  addAggregate(
    NextActionKind.inspectFlagged,
    NextActionPriority.inspectFlagged,
    [
      for (final item in items)
        if (flagged(item) &&
            (role != Role.buyer || !lotIds.contains(item.lotId)))
          item,
    ],
  );

  switch (role) {
    case Role.household:
      final dueItems = {
        for (final reminder in reminders)
          if (reminder.status == ReminderStatus.fired ||
              (reminder.status == ReminderStatus.scheduled &&
                  !reminder.dueAt.isAfter(now)))
            reminder.itemId,
      };
      addAggregate(NextActionKind.reminderDue, NextActionPriority.reminderDue, [
        for (final item in items)
          if (dueItems.contains(item.id)) item,
      ]);
      addAggregate(NextActionKind.reviewDue, NextActionPriority.reviewDue, [
        for (final item in items)
          if (latestPass[item.id] == null ||
              wholeDaysBetween(latestPass[item.id]!.capturedAt, now) >=
                  reviewDueAfterDays)
            item,
      ]);

    case Role.farmer || Role.storageFpo:
      addAggregate(NextActionKind.scanNeeded, NextActionPriority.scanNeeded, [
        for (final item in items)
          if (!passWithin(item, scanNeededAfter)) item,
      ]);
      if (role == Role.storageFpo) {
        final midnight = localMidnight(now);
        bool doneToday(GrainItem item) {
          final scan = latestPass[item.id];
          return scan != null && !scan.capturedAt.isBefore(midnight);
        }

        for (final location in locations) {
          final sacks = [
            for (final item in items)
              if (item.locationId == location.id) item,
          ];
          final remaining = sacks.where((s) => !doneToday(s)).length;
          if (remaining > 0 && remaining < sacks.length) {
            actions.add(
              NextAction(
                kind: NextActionKind.finishBatch,
                priority: NextActionPriority.finishBatch,
                count: remaining,
                locationId: location.id,
                label: location.name,
              ),
            );
          }
        }
      } else {
        for (final harvest in harvests) {
          final sacks = [
            for (final item in items)
              if (item.harvestId == harvest.id) item,
          ];
          final ready =
              sacks.isNotEmpty &&
              sacks.every(
                (s) =>
                    passWithin(s, scanNeededAfter) &&
                    !flagged(s) &&
                    !hasOpenInspection(s),
              );
          if (ready) {
            actions.add(
              NextAction(
                kind: NextActionKind.exportPreSale,
                priority: NextActionPriority.exportPreSale,
                count: sacks.length,
                harvestId: harvest.id,
                label: harvest.name,
              ),
            );
          }
        }
      }

    case Role.buyer:
      for (final lot in lots) {
        final sacks = [
          for (final item in items)
            if (item.lotId == lot.id) item,
        ];
        if (sacks.isEmpty) continue;
        bool inspected(GrainItem s) =>
            (inspectionsByItem[s.id] ?? const <Inspection>[]).isNotEmpty;
        NextAction lotAction(NextActionKind kind, int priority, int count) =>
            NextAction(
              kind: kind,
              priority: priority,
              count: count,
              lotId: lot.id,
              label: lot.code,
            );
        final pending = sacks.where(flagged).length;
        if (pending > 0) {
          actions.add(
            lotAction(
              NextActionKind.physicalCheckPending,
              NextActionPriority.physicalCheckPending,
              pending,
            ),
          );
        }
        final unscanned = sacks
            .where((s) => latestPass[s.id] == null && !inspected(s))
            .length;
        if (unscanned > 0) {
          actions.add(
            lotAction(
              NextActionKind.scanNeeded,
              NextActionPriority.scanNeeded,
              unscanned,
            ),
          );
        }
        final ready =
            pending == 0 &&
            lot.screeningStatus != ScreeningStatus.reviewed &&
            sacks.every((s) => latestValid[s.id] != null || inspected(s));
        if (ready) {
          actions.add(
            lotAction(
              NextActionKind.exportLotSummary,
              NextActionPriority.exportLotSummary,
              sacks.length,
            ),
          );
        }
      }
  }

  actions.addAll(
    _pestAndSensorActions(
      now: now,
      items: items,
      locations: locations,
      sightings: sightings,
      sensorNodes: sensorNodes,
      sensorEvents: sensorEvents,
      nodesNeedingAttention: nodesNeedingAttention,
    ),
  );

  actions.sort(compareNextActions);
  return List.unmodifiable(actions);
}

List<NextAction> _pestAndSensorActions({
  required DateTime now,
  required List<GrainItem> items,
  required List<Location> locations,
  required List<Sighting> sightings,
  required List<SensorNode> sensorNodes,
  required List<PlacedSensorEvent> sensorEvents,
  required Set<String> nodesNeedingAttention,
}) {
  final itemsById = {for (final item in items) item.id: item};
  final locationsById = {for (final l in locations) l.id: l};
  final actions = <NextAction>[];

  String? labelOf(String? itemId, String? locationId) =>
      itemsById[itemId]?.label ?? locationsById[locationId]?.name;

  // Safety first: dangerous or protected animals not yet verified.
  final alerts = [
    for (final s in sightings)
      if (s.verifiedFinding == null &&
          alertSafetyLevels.contains(s.analysis?.safety))
        s,
  ];
  if (alerts.isNotEmpty) {
    final single = alerts.length == 1 ? alerts.single : null;
    actions.add(
      NextAction(
        kind: NextActionKind.pestSafetyAlert,
        priority: NextActionPriority.pestSafetyAlert,
        count: alerts.length,
        itemId: single?.itemId,
        locationId: single?.locationId,
        label: single == null
            ? null
            : labelOf(single.itemId, single.locationId),
      ),
    );
  }

  // The same pest seen repeatedly in one place.
  final since = now.subtract(repeatedSightingsWindow);
  final perLocation = <String, Map<String, int>>{};
  for (final s in sightings) {
    final locationId = s.locationId;
    final cardId = s.userCardId ?? s.analysis?.cardId;
    if (!s.userValidated || locationId == null || cardId == null) continue;
    if (s.observedAt.isBefore(since)) continue;
    final cards = perLocation.putIfAbsent(locationId, () => {});
    cards[cardId] = (cards[cardId] ?? 0) + 1;
  }
  for (final MapEntry(key: locationId, value: cards) in perLocation.entries) {
    final location = locationsById[locationId];
    if (location == null) continue;
    final most = cards.values.fold(0, (a, b) => a > b ? a : b);
    if (most < repeatedSightingsMin) continue;
    actions.add(
      NextAction(
        kind: NextActionKind.pestSightingsRepeated,
        priority: NextActionPriority.pestSightingsRepeated,
        count: most,
        locationId: locationId,
        label: location.name,
      ),
    );
  }

  // Signature-matched sensor events where a node is placed.
  bool visible(String? itemId, String? locationId) {
    if (itemId != null) return itemsById.containsKey(itemId);
    return locationId != null && locationsById.containsKey(locationId);
  }

  final eventsSince = now.subtract(sensorActivityWindow);
  final perNodeAndPlace = <(String, String?, String?), int>{};
  for (final placed in sensorEvents) {
    final event = placed.event;
    if (event.match == null || event.startedAt.isBefore(eventsSince)) {
      continue;
    }
    if (!visible(placed.itemId, placed.locationId)) continue;
    final key = (event.nodeId, placed.itemId, placed.locationId);
    perNodeAndPlace[key] = (perNodeAndPlace[key] ?? 0) + 1;
  }
  final perPlace = <(String?, String?), int>{};
  for (final MapEntry(key: (_, itemId, locationId), value: n)
      in perNodeAndPlace.entries) {
    if (n < sensorActivityMin) continue;
    final place = (itemId, locationId);
    perPlace[place] = (perPlace[place] ?? 0) + n;
  }
  for (final MapEntry(key: (itemId, locationId), value: n)
      in perPlace.entries) {
    actions.add(
      NextAction(
        kind: NextActionKind.sensorActivity,
        priority: NextActionPriority.sensorActivity,
        count: n,
        itemId: itemId,
        locationId: locationId,
        label: labelOf(itemId, locationId),
      ),
    );
  }

  // Nodes reported jammed, clipped, low on battery or needing a survey.
  final attention = [
    for (final node in sensorNodes)
      if (nodesNeedingAttention.contains(node.id) &&
          (node.itemId == null || itemsById.containsKey(node.itemId)))
        node,
  ];
  if (attention.isNotEmpty) {
    final single = attention.length == 1 ? attention.single : null;
    final singleLocation = single?.locationId;
    actions.add(
      NextAction(
        kind: NextActionKind.sensorNeedsAttention,
        priority: NextActionPriority.sensorNeedsAttention,
        count: attention.length,
        itemId: single?.itemId,
        locationId: locationsById.containsKey(singleLocation)
            ? singleLocation
            : null,
        label: single?.name,
      ),
    );
  }
  return actions;
}

/// Priority, then kind (enum order), then label, then target id.
int compareNextActions(NextAction a, NextAction b) {
  final byPriority = a.priority.compareTo(b.priority);
  if (byPriority != 0) return byPriority;
  final byKind = a.kind.index.compareTo(b.kind.index);
  if (byKind != 0) return byKind;
  final byLabel = (a.label ?? '').compareTo(b.label ?? '');
  if (byLabel != 0) return byLabel;
  return _targetOf(a).compareTo(_targetOf(b));
}

String _targetOf(NextAction a) =>
    a.itemId ?? a.lotId ?? a.harvestId ?? a.locationId ?? '';

List<ScanRecord> _newestFirst(List<ScanRecord> scans) =>
    [...scans]..sort((a, b) {
      final byCapture = b.capturedAt.compareTo(a.capturedAt);
      if (byCapture != 0) return byCapture;
      final byCreated = b.createdAt.compareTo(a.createdAt);
      if (byCreated != 0) return byCreated;
      return b.id.compareTo(a.id);
    });
