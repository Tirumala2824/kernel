import 'package:data_operations/src/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late DateTime now;

  setUp(() async {
    h = await Harness.create();
    now = h.clock.now;
  });
  tearDown(() => h.dispose());

  Future<List<NextAction>> actions(Role role) =>
      h.ops.analytics.watchNextActions(role).first;

  List<NextActionKind> kinds(List<NextAction> list) => [
    for (final a in list) a.kind,
  ];

  NextAction only(List<NextAction> list, NextActionKind kind) =>
      list.singleWhere((a) => a.kind == kind);

  DateTime ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  group('registerFirst', () {
    test(
      'every role with nothing registered gets only registerFirst (p0)',
      () async {
        for (final role in Role.values) {
          final list = await actions(role);
          expect(kinds(list), [NextActionKind.registerFirst], reason: '$role');
          expect(list.single.priority, 0);
          expect(list.single.count, 1);
        }
      },
    );

    test('it is per role, ignores archived items, and the buyer needs a '
        'lot', () async {
      final item = await h.addItem(role: Role.farmer);
      await h.recordScan(item.id);
      expect(
        kinds(await actions(Role.farmer)),
        isNot(contains(NextActionKind.registerFirst)),
      );
      expect(kinds(await actions(Role.household)), [
        NextActionKind.registerFirst,
      ]);

      await h.ops.items.archive(item.id);
      expect(kinds(await actions(Role.farmer)), [NextActionKind.registerFirst]);

      // Buyer sacks alone do not count; a lot does.
      await h.addItem(role: Role.buyer);
      expect(
        kinds(await actions(Role.buyer)),
        contains(NextActionKind.registerFirst),
      );
      final lot = await h.addLot();
      expect(
        kinds(await actions(Role.buyer)),
        isNot(contains(NextActionKind.registerFirst)),
      );
      await h.ops.lots.archive(lot.id);
      expect(
        kinds(await actions(Role.buyer)),
        contains(NextActionKind.registerFirst),
      );
    });
  });

  group('inspectFlagged (p10)', () {
    test('flags items whose latest valid scan is infested or uncertain until '
        'an inspection addresses it', () async {
      final a = await h.addItem(label: 'A');
      await h.recordScanAt(
        a.id,
        ago(hours: 2),
        classification: Classification.infested,
      );
      // A later RETRY does not clear the flag.
      await h.recordScanAt(
        a.id,
        ago(hours: 1),
        quality: ScanQuality.retry,
        reasons: const [QualityReason.highNoise],
      );

      var flagged = only(
        await actions(Role.farmer),
        NextActionKind.inspectFlagged,
      );
      expect(flagged.priority, 10);
      expect(flagged.count, 1);
      expect(flagged.itemId, a.id);
      expect(flagged.label, 'A');

      final b = await h.addItem(label: 'B');
      // An inspection from before the scan does not address it.
      await h.addInspection(
        b.id,
        VerifiedFinding.noneFound,
        inspectedAt: ago(days: 2),
      );
      final bScan = await h.recordScanAt(
        b.id,
        ago(hours: 3),
        classification: Classification.uncertain,
      );
      flagged = only(await actions(Role.farmer), NextActionKind.inspectFlagged);
      expect(flagged.count, 2);
      expect(flagged.itemId, isNull);
      expect(flagged.label, isNull);

      // Inspected at or after the scan: addressed.
      await h.addInspection(a.id, VerifiedFinding.pestsFound);
      flagged = only(await actions(Role.farmer), NextActionKind.inspectFlagged);
      expect((flagged.count, flagged.itemId), (1, b.id));

      // Linked to the scan: addressed even if dated earlier.
      await h.addInspection(
        b.id,
        VerifiedFinding.inconclusive,
        scanId: bScan.id,
        inspectedAt: ago(days: 1),
      );
      expect(
        kinds(await actions(Role.farmer)),
        isNot(contains(NextActionKind.inspectFlagged)),
      );

      // A newer clean scan replaces the flagged one.
      final c = await h.addItem(label: 'C');
      await h.recordScanAt(
        c.id,
        ago(hours: 5),
        classification: Classification.infested,
      );
      await h.recordScanAt(
        c.id,
        ago(hours: 4),
        classification: Classification.clean,
      );
      expect(
        kinds(await actions(Role.farmer)),
        isNot(contains(NextActionKind.inspectFlagged)),
      );
    });

    test('applies to household and storage roles too', () async {
      for (final role in [Role.household, Role.storageFpo]) {
        final item = await h.addItem(role: role, label: 'Bin ${role.name}');
        await h.recordModelScan(item.id, Classification.infested);
        final flagged = only(
          await actions(role),
          NextActionKind.inspectFlagged,
        );
        expect(flagged.itemId, item.id, reason: '$role');
      }
    });
  });

  group('household', () {
    test('reminderDue (p5) for fired or past-due reminders that are not done '
        'or cancelled', () async {
      final a = await h.addItem(role: Role.household, label: 'Rice tin');
      final b = await h.addItem(role: Role.household, label: 'Dal tin');
      await h.recordScan(a.id);
      await h.recordScan(b.id);
      final ra = await h.ops.reminders.schedule(
        a.id,
        now.add(const Duration(hours: 1)),
      );
      final rb = await h.ops.reminders.schedule(
        b.id,
        now.add(const Duration(hours: 3)),
      );
      expect(
        kinds(await actions(Role.household)),
        isNot(contains(NextActionKind.reminderDue)),
      );

      h.clock.advance(const Duration(hours: 2)); // a is past due
      var due = only(await actions(Role.household), NextActionKind.reminderDue);
      expect(due.priority, 5);
      expect((due.count, due.itemId, due.label), (1, a.id, 'Rice tin'));

      h.clock.advance(const Duration(hours: 2));
      await h.ops.restoreReminders(); // both become fired
      due = only(await actions(Role.household), NextActionKind.reminderDue);
      expect((due.count, due.itemId), (2, null));

      await h.ops.reminders.markDone(ra.id);
      await h.ops.reminders.cancel(rb.id);
      expect(
        kinds(await actions(Role.household)),
        isNot(contains(NextActionKind.reminderDue)),
      );
    });

    test('reviewDue (p15) when never scanned, RETRY-only, or the latest PASS '
        'scan is 30 or more days old', () async {
      final never = await h.addItem(role: Role.household, label: 'Never');
      final retryOnly = await h.addItem(role: Role.household, label: 'Retry');
      final old = await h.addItem(role: Role.household, label: 'Old');
      final recent = await h.addItem(role: Role.household, label: 'Recent');
      await h.recordScanAt(
        retryOnly.id,
        ago(hours: 1),
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence],
      );
      await h.recordScanAt(old.id, ago(days: 30));
      await h.recordScanAt(recent.id, ago(days: 29, hours: 23));

      final list = await actions(Role.household);
      expect(kinds(list), [NextActionKind.reviewDue]);
      expect(list.single.priority, 15);
      expect(list.single.count, 3);

      h.clock.advance(const Duration(hours: 1));
      expect((await actions(Role.household)).single.count, 4);
      expect(never.id, isNotEmpty);
    });
  });

  group('farmer and storage', () {
    for (final role in [Role.farmer, Role.storageFpo]) {
      test('${role.name}: scanNeeded (p20) when never scanned, RETRY-only or '
          'the latest PASS scan is over 14 days old', () async {
        await h.addItem(role: role, label: 'Never');
        final retryOnly = await h.addItem(role: role, label: 'Retry');
        final stale = await h.addItem(role: role, label: 'Stale');
        final edge = await h.addItem(role: role, label: 'Edge');
        final fresh = await h.addItem(role: role, label: 'Fresh');
        await h.recordScanAt(
          retryOnly.id,
          ago(),
          quality: ScanQuality.retry,
          reasons: const [QualityReason.clipping],
        );
        await h.recordScanAt(stale.id, ago(days: 14, minutes: 1));
        await h.recordScanAt(edge.id, ago(days: 14));
        // A newer RETRY does not refresh an old PASS scan, but a fresh
        // PASS scan without a model result counts.
        await h.recordScanAt(
          stale.id,
          ago(),
          quality: ScanQuality.retry,
          reasons: const [QualityReason.silence],
        );
        await h.recordScanAt(fresh.id, ago(days: 1));

        final needed = only(await actions(role), NextActionKind.scanNeeded);
        expect(needed.priority, 20);
        expect(needed.count, 3);
        expect(needed.itemId, isNull);
      });
    }

    test('storage: finishBatch (p15) per location with sacks done today and '
        'sacks still to do', () async {
      final stack1 = await h.addLocation('Stack 1', type: LocationType.stack);
      final stack2 = await h.addLocation('Stack 2', type: LocationType.stack);
      final stack3 = await h.addLocation('Stack 3', type: LocationType.stack);
      Future<GrainItem> sack(String label, Location at) =>
          h.addItem(role: Role.storageFpo, label: label, locationId: at.id);
      final s1 = await sack('S1', stack1);
      final s2 = await sack('S2', stack1);
      final s3 = await sack('S3', stack1);
      final t1 = await sack('T1', stack2);
      final u1 = await sack('U1', stack3);
      final midnight = localMidnight(now);
      await h.recordScanAt(s1.id, now);
      await h.recordScanAt(
        s2.id,
        now,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.highNoise],
      );
      await h.recordScanAt(
        s3.id,
        midnight.subtract(const Duration(minutes: 1)),
      );
      await h.recordScanAt(
        t1.id,
        midnight.subtract(const Duration(minutes: 1)),
      );
      await h.recordScanAt(u1.id, midnight);

      final list = await actions(Role.storageFpo);
      final batch = only(list, NextActionKind.finishBatch);
      expect(batch.priority, 15);
      expect(batch.locationId, stack1.id);
      expect(batch.label, 'Stack 1');
      expect(batch.count, 2);
      // Farmers never get it.
      final farmerSack = await h.addItem(locationId: stack2.id);
      await h.recordScanAt(farmerSack.id, now);
      expect(
        kinds(await actions(Role.farmer)),
        isNot(contains(NextActionKind.finishBatch)),
      );
    });

    test(
      'farmer: exportPreSale (p40) per harvest whose sacks all have a '
      'recent PASS scan, no unresolved flag and no open inspection',
      () async {
        final ready = await h.addHarvest(name: 'Ready');
        final stale = await h.addHarvest(name: 'Stale');
        final open = await h.addHarvest(name: 'Open');
        final flagged = await h.addHarvest(name: 'Flagged');
        await h.addHarvest(name: 'Empty');
        final archived = await h.addHarvest(name: 'Archived');

        Future<GrainItem> sack(Harvest of) =>
            h.addItem(label: 'Sack ${of.name}', harvestId: of.id);
        final r1 = await sack(ready);
        final r2 = await sack(ready);
        await h.recordScanAt(r1.id, ago(days: 2));
        await h.recordScanAt(
          r2.id,
          ago(days: 13),
          classification: Classification.clean,
        );
        final st = await sack(stale);
        await h.recordScanAt(st.id, ago(days: 20));
        final op = await sack(open);
        await h.recordScanAt(op.id, ago(days: 1));
        final openCheck = await h.addInspection(
          op.id,
          VerifiedFinding.noneFound,
        );
        final fl = await sack(flagged);
        await h.recordScanAt(
          fl.id,
          ago(hours: 1),
          classification: Classification.infested,
        );
        final ar = await sack(archived);
        await h.recordScanAt(ar.id, ago(days: 1));
        await h.ops.harvests.archive(archived.id);

        List<NextAction> exports(List<NextAction> list) => [
          for (final a in list)
            if (a.kind == NextActionKind.exportPreSale) a,
        ];
        var list = exports(await actions(Role.farmer));
        expect(list.map((a) => a.harvestId), [ready.id]);
        expect(list.single.priority, 40);
        expect(list.single.count, 2);
        expect(list.single.label, 'Ready');

        await h.ops.inspections.updateFollowUp(
          openCheck.id,
          FollowUpStatus.done,
        );
        await h.addInspection(
          fl.id,
          VerifiedFinding.pestsFound,
          followUpStatus: FollowUpStatus.done,
        );
        list = exports(await actions(Role.farmer));
        expect(list.map((a) => a.label), ['Flagged', 'Open', 'Ready']);
      },
    );
  });

  group('buyer', () {
    test('per lot: physicalCheckPending (p10), scanNeeded (p20) and '
        'exportLotSummary (p40)', () async {
      final l1 = await h.addLot(code: 'LOT-1');
      final l2 = await h.addLot(code: 'LOT-2');
      final l3 = await h.addLot(code: 'LOT-3');
      Future<GrainItem> sack(String label, Lot lot) =>
          h.addItem(role: Role.buyer, label: label, lotId: lot.id);

      final x1 = await sack('X1', l1);
      await sack('X2', l1); // never scanned, not inspected
      final x3 = await sack('X3', l1);
      final x4 = await sack('X4', l1);
      await h.recordModelScan(x1.id, Classification.infested);
      await h.addInspection(x3.id, VerifiedFinding.noneFound);
      await h.recordScan(
        x4.id,
        quality: ScanQuality.retry,
        reasons: const [QualityReason.silence],
      );

      final y1 = await sack('Y1', l2);
      final y2 = await sack('Y2', l2);
      await h.recordModelScan(y1.id, Classification.clean);
      await h.addInspection(y2.id, VerifiedFinding.noneFound);

      // Only PASS scans without a model result: neither a scan prompt nor a
      // summary prompt.
      final z1 = await sack('Z1', l3);
      await h.recordScan(z1.id);

      // A flagged buyer sack outside any lot.
      final loose = await h.addItem(role: Role.buyer, label: 'Loose');
      await h.recordModelScan(loose.id, Classification.uncertain);

      final list = await actions(Role.buyer);
      expect(
        [for (final a in list) (a.kind, a.priority, a.lotId, a.count)],
        [
          (NextActionKind.inspectFlagged, 10, null, 1),
          (NextActionKind.physicalCheckPending, 10, l1.id, 1),
          (NextActionKind.scanNeeded, 20, l1.id, 2),
          (NextActionKind.exportLotSummary, 40, l2.id, 2),
        ],
      );
      expect(list[0].itemId, loose.id);
      expect(list[1].label, 'LOT-1');
      expect(list[3].label, 'LOT-2');

      await h.ops.lots.updateScreeningStatus(l2.id, ScreeningStatus.reviewed);
      expect(
        kinds(await actions(Role.buyer)),
        isNot(contains(NextActionKind.exportLotSummary)),
      );

      // Once the flagged sack is checked and the rest are covered, LOT-1 is
      // ready for a summary.
      await h.addInspection(x1.id, VerifiedFinding.pestsFound);
      final others = await h.ops.items.watchByLot(l1.id).first;
      for (final s in others.where((s) => s.label == 'X2' || s.label == 'X4')) {
        await h.addInspection(s.id, VerifiedFinding.inconclusive);
      }
      final after = await actions(Role.buyer);
      expect(
        [for (final a in after) (a.kind, a.lotId)],
        [
          (NextActionKind.inspectFlagged, null),
          (NextActionKind.exportLotSummary, l1.id),
        ],
      );
    });
  });

  test('ordering: priority, then kind, then label, then target id', () async {
    final beta = await h.addHarvest(name: 'Beta');
    final alpha = await h.addHarvest(name: 'Alpha');
    final b1 = await h.addItem(label: 'B1', harvestId: beta.id);
    final a1 = await h.addItem(label: 'A1', harvestId: alpha.id);
    await h.recordScanAt(b1.id, ago(days: 1));
    await h.recordScanAt(a1.id, ago(days: 1));
    final flagged = await h.addItem(label: 'Flag');
    await h.recordModelScan(flagged.id, Classification.infested);
    await h.addItem(label: 'Unscanned');

    final list = await actions(Role.farmer);
    expect(
      [for (final a in list) (a.kind, a.label)],
      [
        (NextActionKind.inspectFlagged, 'Flag'),
        (NextActionKind.scanNeeded, 'Unscanned'),
        (NextActionKind.exportPreSale, 'Alpha'),
        (NextActionKind.exportPreSale, 'Beta'),
      ],
    );
    final priorities = [for (final a in list) a.priority];
    expect(priorities, [...priorities]..sort());
    // Deterministic across calls.
    final again = await actions(Role.farmer);
    expect([for (final a in again) a.label], [for (final a in list) a.label]);

    // Equal priority across kinds: enum order decides.
    const x = NextAction(
      kind: NextActionKind.physicalCheckPending,
      priority: 10,
    );
    const y = NextAction(kind: NextActionKind.inspectFlagged, priority: 10);
    expect(compareNextActions(x, y), greaterThan(0));
    const p = NextAction(
      kind: NextActionKind.finishBatch,
      priority: 15,
      label: 'S',
      locationId: 'b',
    );
    const q = NextAction(
      kind: NextActionKind.finishBatch,
      priority: 15,
      label: 'S',
      locationId: 'a',
    );
    expect(compareNextActions(p, q), greaterThan(0));
  });

  test('the stream emits again when records change', () async {
    final item = await h.addItem(label: 'A');
    await h.recordScan(item.id);
    final flagged = firstWhere(
      h.ops.analytics.watchNextActions(Role.farmer),
      (list) => list.any((a) => a.kind == NextActionKind.inspectFlagged),
    );
    await h.recordModelScan(item.id, Classification.infested);
    expect((await flagged).first.itemId, item.id);
  });
}
