import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  Future<InspectionQueue> queue({
    Role? role,
    String? locationId,
    String? lotId,
  }) => h.ops.ranking
      .watchQueue(role: role, locationId: locationId, lotId: lotId)
      .first;

  test('an empty database gives an empty queue', () async {
    final q = await queue();
    expect(q.ranked, isEmpty);
    expect(q.needsScan, isEmpty);
    expect(q.modelVersion, isNull);
  });

  test('with no model bundled every item needs a scan', () async {
    final a = await h.addItem(label: 'A');
    final b = await h.addItem(label: 'B');
    final c = await h.addItem(label: 'C');
    await h.recordScan(a.id, minutesAgo: 5); // PASS, notEvaluated, "none"
    await h.recordScan(
      b.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.clipping],
    );
    // c has never been scanned.

    final q = await queue();
    expect(q.ranked, isEmpty);
    expect(q.needsScan.map((i) => i.id), [a.id, b.id, c.id]);
    expect(q.modelVersion, isNull);
  });

  test('ranks infested > uncertain > clean, then oldest scan first', () async {
    final clean = await h.addItem(label: 'clean');
    final uncertainNew = await h.addItem(label: 'uncertain-new');
    final infested = await h.addItem(label: 'infested');
    final uncertainOld = await h.addItem(label: 'uncertain-old');
    final unscanned = await h.addItem(label: 'unscanned');
    final retryOnly = await h.addItem(label: 'retry-only');

    await h.recordModelScan(clean.id, Classification.clean, minutesAgo: 90);
    await h.recordModelScan(
      uncertainNew.id,
      Classification.uncertain,
      minutesAgo: 10,
    );
    await h.recordModelScan(
      infested.id,
      Classification.infested,
      minutesAgo: 5,
    );
    await h.recordModelScan(
      uncertainOld.id,
      Classification.uncertain,
      minutesAgo: 60,
    );
    await h.recordScan(
      retryOnly.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );

    final q = await queue();
    expect(q.ranked.map((e) => e.item.id), [
      infested.id,
      uncertainOld.id,
      uncertainNew.id,
      clean.id,
    ]);
    expect(q.ranked.first.latestValidScan.result, Classification.infested);
    expect(
      q.needsScan.map((i) => i.id),
      unorderedEquals([unscanned.id, retryOnly.id]),
    );
    expect(q.modelVersion, 'test-model-1');
  });

  test('uses each item\'s latest valid scan', () async {
    final item = await h.addItem(label: 'rescanned');
    await h.recordModelScan(item.id, Classification.infested, minutesAgo: 60);
    final latest = await h.recordModelScan(
      item.id,
      Classification.clean,
      minutesAgo: 30,
    );
    // A newer RETRY does not replace the latest valid scan.
    await h.recordScan(
      item.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
    );

    final q = await queue();
    expect(q.ranked.single.latestValidScan.id, latest.id);
    expect(q.ranked.single.latestValidScan.result, Classification.clean);
  });

  test('only items sharing the common model version are ranked', () async {
    final a = await h.addItem(label: 'a');
    final b = await h.addItem(label: 'b');
    final c = await h.addItem(label: 'c');
    final d = await h.addItem(label: 'd');
    await h.recordModelScan(a.id, Classification.clean, modelVersion: 'v2');
    await h.recordModelScan(b.id, Classification.infested, modelVersion: 'v2');
    await h.recordModelScan(c.id, Classification.infested, modelVersion: 'v1');
    // d's latest valid scan is on v1 even though an older one used v2.
    await h.recordModelScan(
      d.id,
      Classification.uncertain,
      modelVersion: 'v2',
      minutesAgo: 50,
    );
    await h.recordModelScan(
      d.id,
      Classification.uncertain,
      modelVersion: 'v1',
      minutesAgo: 40,
    );

    final q = await queue();
    expect(q.modelVersion, 'v2');
    expect(q.ranked.map((e) => e.item.id), [b.id, a.id]);
    expect(
      q.ranked.every((e) => e.latestValidScan.modelVersion == 'v2'),
      isTrue,
    );
    expect(q.needsScan.map((i) => i.id), [c.id, d.id]);
  });

  test('a version tie goes to the most recently used model', () async {
    final a = await h.addItem(label: 'a');
    final b = await h.addItem(label: 'b');
    await h.recordModelScan(
      a.id,
      Classification.clean,
      modelVersion: 'old',
      minutesAgo: 30,
    );
    await h.recordModelScan(
      b.id,
      Classification.clean,
      modelVersion: 'new',
      minutesAgo: 5,
    );

    final q = await queue();
    expect(q.modelVersion, 'new');
    expect(q.ranked.single.item.id, b.id);
    expect(q.needsScan.single.id, a.id);
  });

  test(
    'filters by role, lot and location (including nested locations)',
    () async {
      final warehouse = await h.ops.locations.create(
        const LocationDraft(type: LocationType.warehouse, name: 'Godown'),
      );
      final stack = await h.ops.locations.create(
        LocationDraft(
          type: LocationType.stack,
          name: 'Stack 1',
          parentId: warehouse.id,
        ),
      );
      final elsewhere = await h.ops.locations.create(
        const LocationDraft(type: LocationType.warehouse, name: 'Other'),
      );
      final lot = await h.ops.lots.create(
        LotDraft(
          code: 'L-9',
          grainType: 'Wheat',
          declaredQuantity: 100,
          quantityUnit: 'kg',
          receivedAt: DateTime.utc(2026, 9, 30),
        ),
      );
      final inStack = await h.addItem(
        role: Role.storageFpo,
        label: 's1',
        locationId: stack.id,
      );
      final inOther = await h.addItem(
        role: Role.storageFpo,
        label: 's2',
        locationId: elsewhere.id,
      );
      final inLot = await h.addItem(
        role: Role.buyer,
        label: 'b1',
        lotId: lot.id,
      );
      final farmer = await h.addItem(role: Role.farmer, label: 'f1');
      for (final item in [inStack, inOther, inLot, farmer]) {
        await h.recordModelScan(item.id, Classification.uncertain);
      }

      List<String> ids(InspectionQueue q) => [
        ...q.ranked.map((e) => e.item.id),
        ...q.needsScan.map((i) => i.id),
      ];
      expect(
        ids(await queue(role: Role.storageFpo)),
        unorderedEquals([inStack.id, inOther.id]),
      );
      expect(ids(await queue(locationId: warehouse.id)), [inStack.id]);
      expect(ids(await queue(locationId: stack.id)), [inStack.id]);
      expect(ids(await queue(lotId: lot.id)), [inLot.id]);
      expect(ids(await queue(role: Role.farmer, lotId: lot.id)), isEmpty);
      expect(ids(await queue()), hasLength(4));
    },
  );

  test('the queue stream updates when a new scan is recorded', () async {
    final item = await h.addItem(label: 'live');
    final stream = h.ops.ranking.watchQueue();
    final initial = await stream.first;
    expect(initial.needsScan.single.id, item.id);

    final later = firstWhere(stream, (q) => q.ranked.isNotEmpty);
    await h.recordModelScan(item.id, Classification.infested);
    final updated = await later;
    expect(updated.ranked.single.item.id, item.id);
    expect(updated.needsScan, isEmpty);
  });
}
