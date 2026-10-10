import 'package:data_operations/src/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/csv.dart';
import 'support/harness.dart';

void main() {
  late Harness h;
  late DateTime now;

  setUp(() async {
    h = await Harness.create();
    now = h.clock.now;
  });
  tearDown(() => h.dispose());

  AnalyticsService analytics() => h.ops.analytics;

  Future<ResultRates> rates([AnalyticsFilter f = const AnalyticsFilter()]) =>
      analytics().watchResultRates(f).first;
  Future<QualityFailures> quality([
    AnalyticsFilter f = const AnalyticsFilter(),
  ]) => analytics().watchQualityFailures(f).first;
  Future<List<ItemFreshness>> freshness([
    AnalyticsFilter f = const AnalyticsFilter(),
  ]) => analytics().watchItemFreshness(f).first;
  Future<InspectionStats> inspections([
    AnalyticsFilter f = const AnalyticsFilter(),
  ]) => analytics().watchInspectionStats(f).first;
  Future<ScanActivity> activity([
    AnalyticsFilter f = const AnalyticsFilter(),
  ]) => analytics().watchScanActivity(f).first;

  test('an empty database gives zero metrics and no rates', () async {
    final r = await rates();
    expect(r.total, 0);
    expect(r.infestedRate, isNull);
    expect(r.uncertainRate, isNull);
    final q = await quality();
    expect(q.total, 0);
    expect(q.counts.keys, QualityReason.values);
    expect(await freshness(), isEmpty);
    final i = await inspections();
    expect(i.total, 0);
    expect(i.closureRate, isNull);
    final a = await activity();
    expect((a.today, a.last7Days), (0, 0));
    final s = await analytics().summarize(const ReportScope(role: Role.farmer));
    expect(s.items, 0);
    expect(s.rates.total, 0);
    expect(s.firstScanAt, isNull);
    expect(s.lastScanAt, isNull);
  });

  test('result rates count every scan once: RETRY, PASS not evaluated, and '
      'PASS by class', () async {
    final item = await h.addItem();
    await h.recordScan(
      item.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.clipping],
    );
    await h.recordScan(item.id); // PASS, notEvaluated, no model
    await h.recordModelScan(item.id, Classification.clean);
    await h.recordModelScan(item.id, Classification.uncertain);
    await h.recordModelScan(item.id, Classification.infested);
    await h.recordModelScan(item.id, Classification.infested);

    final r = await rates();
    expect(
      (r.clean, r.uncertain, r.infested, r.notEvaluated, r.retry),
      (1, 1, 2, 1, 1),
    );
    expect(r.valid, 4);
    expect(r.total, 6);
    expect(r.infestedRate, 0.5);
    expect(r.uncertainRate, 0.25);
  });

  test('quality failures count each reason across RETRY scans only', () async {
    final item = await h.addItem();
    await h.recordScan(
      item.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence, QualityReason.highNoise],
    );
    await h.recordScan(
      item.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
    );
    await h.recordScan(item.id);
    await h.recordModelScan(item.id, Classification.clean);

    final q = await quality();
    expect(q.counts.keys, QualityReason.values);
    expect(q.counts[QualityReason.silence], 1);
    expect(q.counts[QualityReason.highNoise], 2);
    expect(q.counts[QualityReason.clipping], 0);
    expect(q.total, 3);
  });

  test('filters combine as AND: role, nested location and lot', () async {
    final warehouse = await h.addLocation('Warehouse');
    final room = await h.addLocation(
      'Room 1',
      type: LocationType.room,
      parentId: warehouse.id,
    );
    final elsewhere = await h.addLocation('Shed');
    final lot = await h.addLot();
    final inRoomLot = await h.addItem(
      label: 'F1',
      locationId: room.id,
      lotId: lot.id,
    );
    final inShed = await h.addItem(label: 'F2', locationId: elsewhere.id);
    final fpoInRoom = await h.addItem(
      label: 'S1',
      role: Role.storageFpo,
      locationId: room.id,
      lotId: lot.id,
    );
    final inWarehouse = await h.addItem(
      label: 'F3',
      locationId: warehouse.id,
    );
    for (final item in [inRoomLot, inShed, fpoInRoom, inWarehouse]) {
      await h.recordModelScan(item.id, Classification.clean);
    }

    Future<int> count(AnalyticsFilter f) async => (await rates(f)).total;
    expect(await count(const AnalyticsFilter()), 4);
    expect(await count(const AnalyticsFilter(role: Role.farmer)), 3);
    expect(await count(AnalyticsFilter(locationId: warehouse.id)), 3);
    expect(await count(AnalyticsFilter(locationId: room.id)), 2);
    expect(
      await count(
        AnalyticsFilter(role: Role.farmer, locationId: warehouse.id),
      ),
      2,
    );
    expect(
      await count(
        AnalyticsFilter(
          role: Role.farmer,
          locationId: warehouse.id,
          lotId: lot.id,
        ),
      ),
      1,
    );
    expect(await count(AnalyticsFilter(lotId: lot.id)), 2);
    final fresh = await freshness(
      AnalyticsFilter(role: Role.farmer, locationId: warehouse.id),
    );
    expect(fresh.map((f) => f.label).toSet(), {'F1', 'F3'});
  });

  test('the window keeps scans captured, and inspections inspected, within '
      'it, measured from the injected clock', () async {
    final item = await h.addItem();
    await h.recordScanAt(item.id, now.subtract(const Duration(hours: 1)));
    await h.recordScanAt(item.id, now.subtract(const Duration(days: 2)));
    await h.recordScanAt(
      item.id,
      now.subtract(const Duration(days: 10)),
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );
    await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      inspectedAt: now.subtract(const Duration(days: 1)),
    );
    await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      inspectedAt: now.subtract(const Duration(days: 8)),
    );

    const threeDays = AnalyticsFilter(window: Duration(days: 3));
    expect((await rates()).total, 3);
    expect((await rates(threeDays)).total, 2);
    expect((await quality(threeDays)).total, 0);
    expect((await quality()).total, 1);
    expect((await inspections()).total, 2);
    expect((await inspections(threeDays)).total, 1);
    // Freshness is about the item, so the window does not hide its scans.
    expect((await freshness(threeDays)).single.daysSinceLastScan, 0);

    h.clock.advance(const Duration(days: 2, hours: 1));
    expect((await rates(threeDays)).total, 1);
    expect((await inspections(threeDays)).total, 0);
  });

  test('archived items, their scans and their inspections are excluded '
      'from every metric', () async {
    final kept = await h.addItem(label: 'Kept');
    final gone = await h.addItem(label: 'Gone');
    await h.recordModelScan(kept.id, Classification.clean);
    await h.recordModelScan(gone.id, Classification.infested);
    await h.recordScan(
      gone.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.clipping],
    );
    await h.addInspection(gone.id, VerifiedFinding.pestsFound);
    await h.ops.items.archive(gone.id);

    final r = await rates();
    expect((r.clean, r.infested, r.retry), (1, 0, 0));
    expect((await quality()).total, 0);
    expect((await freshness()).map((f) => f.itemId), [kept.id]);
    expect((await inspections()).total, 0);
    expect((await activity()).today, 1);
    final s = await analytics().summarize(const ReportScope(role: Role.farmer));
    expect(s.items, 1);
    expect(s.rates.total, 1);

    await h.ops.items.unarchive(gone.id);
    expect((await rates()).total, 3);
  });

  test('item freshness lists never-scanned items first, then the most '
      'stale, using the latest scan of any quality', () async {
    final a = await h.addItem(label: 'A');
    final b = await h.addItem(label: 'B');
    final c = await h.addItem(label: 'C');
    final d = await h.addItem(label: 'D');
    await h.recordScanAt(
      a.id,
      now.subtract(const Duration(days: 10)),
      classification: Classification.clean,
    );
    await h.recordScanAt(
      a.id,
      now.subtract(const Duration(days: 1, hours: 2)),
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
    );
    await h.recordScanAt(
      c.id,
      now.subtract(const Duration(days: 20)),
      classification: Classification.infested,
    );

    final list = await freshness();
    expect(list.map((f) => f.itemId), [b.id, d.id, c.id, a.id]);
    expect(list[0].lastScanAt, isNull);
    expect(list[0].daysSinceLastScan, isNull);
    expect(list[0].lastResult, isNull);
    expect(list[0].label, 'B');
    expect(list[2].daysSinceLastScan, 20);
    expect(list[2].lastResult, Classification.infested);
    expect(list[3].daysSinceLastScan, 1);
    expect(list[3].lastResult, Classification.notEvaluated);
    expect(
      list[3].lastScanAt,
      now.subtract(const Duration(days: 1, hours: 2)),
    );
  });

  test('inspection stats count by follow-up status', () async {
    final item = await h.addItem();
    await h.addInspection(item.id, VerifiedFinding.noneFound);
    final progressing = await h.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
    );
    await h.ops.inspections.updateFollowUp(
      progressing.id,
      FollowUpStatus.inProgress,
    );
    await h.addInspection(
      item.id,
      VerifiedFinding.pestsFound,
      followUpStatus: FollowUpStatus.done,
    );
    await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      followUpStatus: FollowUpStatus.done,
    );

    final stats = await inspections();
    expect((stats.open, stats.inProgress, stats.done), (1, 1, 2));
    expect(stats.closureRate, 0.5);
    final farmer = await inspections(const AnalyticsFilter(role: Role.buyer));
    expect(farmer.total, 0);
  });

  test('scan activity: today is since local midnight, last7Days is the '
      'rolling 7 x 24 h', () async {
    final item = await h.addItem();
    final midnight = localMidnight(now);
    await h.recordScanAt(item.id, now);
    await h.recordScanAt(item.id, midnight);
    await h.recordScanAt(
      item.id,
      midnight.subtract(const Duration(minutes: 1)),
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );
    await h.recordScanAt(
      item.id,
      now.subtract(const Duration(days: 7)).add(const Duration(minutes: 1)),
    );
    await h.recordScanAt(
      item.id,
      now.subtract(const Duration(days: 7, minutes: 1)),
    );

    final a = await activity();
    expect(a.today, 2);
    expect(a.last7Days, 4);
    final windowed = await activity(
      const AnalyticsFilter(window: Duration(days: 3)),
    );
    expect(windowed.last7Days, 3);
    expect(midnight.hour, 0);
    expect(midnight.isUtc, isFalse);
  });

  test('streams emit again when records change', () async {
    final item = await h.addItem();
    final updated = firstWhere(
      analytics().watchResultRates(),
      (r) => r.infested == 1,
    );
    final stats = firstWhere(
      analytics().watchInspectionStats(),
      (s) => s.open == 1,
    );
    await h.recordModelScan(item.id, Classification.infested);
    await h.addInspection(item.id, VerifiedFinding.pestsFound);
    expect((await updated).total, 1);
    expect((await stats).total, 1);
  });

  test('summarize uses the report scope rules, so its counts match the '
      'report', () async {
    final harvest = await h.addHarvest(name: 'Rabi');
    final other = await h.addHarvest(name: 'Kharif');
    final a = await h.addItem(label: 'A', harvestId: harvest.id);
    final b = await h.addItem(label: 'B', harvestId: harvest.id);
    final archived = await h.addItem(label: 'C', harvestId: harvest.id);
    final elsewhere = await h.addItem(label: 'D', harvestId: other.id);
    final first = await h.recordScanAt(
      a.id,
      now.subtract(const Duration(days: 3)),
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );
    await h.recordScanAt(
      a.id,
      now.subtract(const Duration(hours: 1)),
      classification: Classification.clean,
    );
    final last = await h.recordScan(b.id); // PASS, not evaluated, at now
    await h.recordModelScan(archived.id, Classification.infested);
    await h.recordModelScan(elsewhere.id, Classification.infested);
    await h.addInspection(a.id, VerifiedFinding.noneFound);
    await h.addInspection(
      a.id,
      VerifiedFinding.noneFound,
      followUpStatus: FollowUpStatus.done,
    );
    await h.ops.items.archive(archived.id);

    final scope = ReportScope(
      role: Role.farmer,
      kind: ReportKind.preSale,
      harvestId: harvest.id,
    );
    final s = await analytics().summarize(scope);
    expect(s.role, Role.farmer);
    expect(s.kind, ReportKind.preSale);
    expect(s.items, 2);
    expect(s.itemsNeedingScan, 1); // b has no valid scan
    expect(
      (s.rates.clean, s.rates.notEvaluated, s.rates.retry, s.rates.infested),
      (1, 1, 1, 0),
    );
    expect(s.quality.counts[QualityReason.silence], 1);
    expect((s.inspections.open, s.inspections.done), (1, 1));
    expect(s.firstScanAt, first.capturedAt);
    expect(s.lastScanAt, last.capturedAt);

    final preSale = await readCsv(
      await h.ops.reports.export(scope, ReportFormat.csv),
    );
    expect(preSale.preambleValue('Sacks'), '${s.items}');
    expect(
      preSale.preambleValue('Sacks with a valid AI screening'),
      '${s.items - s.itemsNeedingScan}',
    );

    final history = ReportScope(role: Role.farmer, harvestId: harvest.id);
    final hs = await analytics().summarize(history);
    final csv = await readCsv(
      await h.ops.reports.export(history, ReportFormat.csv),
    );
    expect(csv.preambleValue('Items'), '${hs.items}');
    expect(csv.preambleValue('Scans'), '${hs.rates.total}');
    expect(csv.preambleValue('Inspections'), '${hs.inspections.total}');

    final byIds = await analytics().summarize(
      ReportScope(role: Role.farmer, itemIds: [b.id, elsewhere.id]),
    );
    expect(byIds.items, 2);
    expect(byIds.rates.infested, 1);
  });
}
