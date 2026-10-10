import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/batch/batch_session_screen.dart';
import 'package:kernel_app/features/home/next_actions.dart';
import 'package:kernel_app/features/inventory/item_detail_screen.dart';
import 'package:kernel_app/features/inventory/item_form_screen.dart';
import 'package:kernel_app/features/lots/lot_detail_screen.dart';
import 'package:kernel_app/features/queue/queue_screen.dart';
import 'package:kernel_app/features/scan/guided_scan_screen.dart';
import 'package:kernel_app/features/scan/scan_tab_screen.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

Finder _inHero(String text) => find.descendant(
  of: find.byKey(const Key('next-step-hero')),
  matching: find.text(text),
);

Finder _inRow(int i, String text) => find.descendant(
  of: find.byKey(Key('next-step-$i')),
  matching: find.text(text),
);

Future<void> _goHome(WidgetTester tester) async {
  routerOf(tester).go(Routes.home);
  await tester.pumpAndSettle();
}

void main() {
  group('describeNextAction maps every kind to copy and a route', () {
    NextStep d(Role role, NextAction a) => describeNextAction(en, role, a);

    test('registerFirst opens the register form (a lot form for buyers)', () {
      final farmer = d(
        Role.farmer,
        const NextAction(kind: NextActionKind.registerFirst, priority: 0),
      );
      expect(farmer.title, en.nextRegisterFirst('sack'));
      expect(farmer.location, Routes.newItem());
      final household = d(
        Role.household,
        const NextAction(kind: NextActionKind.registerFirst, priority: 0),
      );
      expect(household.title, 'Register your first container');
      final buyer = d(
        Role.buyer,
        const NextAction(kind: NextActionKind.registerFirst, priority: 0),
      );
      expect(buyer.title, en.nextRegisterFirstLot);
      expect(buyer.location, Routes.newLot);
    });

    test('scanNeeded: picker, one item, or a batch for a place or lot', () {
      final many = d(
        Role.farmer,
        const NextAction(kind: NextActionKind.scanNeeded, priority: 0, count: 3),
      );
      expect(many.title, '3 sacks need a scan');
      expect(many.location, Routes.scan);
      expect(many.tab, isTrue);
      expect(many.scan, isTrue);

      final one = d(
        Role.farmer,
        const NextAction(
          kind: NextActionKind.scanNeeded,
          priority: 0,
          itemId: 'i1',
          label: 'Sack R-004',
        ),
      );
      expect(one.title, 'Scan Sack R-004');
      expect(one.location, Routes.scanItem('i1'));

      final place = d(
        Role.storageFpo,
        const NextAction(
          kind: NextActionKind.scanNeeded,
          priority: 0,
          count: 4,
          locationId: 'room-2',
        ),
      );
      expect(place.location, Routes.batchRun(locationId: 'room-2'));
      expect(place.actionLabel, en.nextActionBatch);

      final containers = d(
        Role.household,
        const NextAction(kind: NextActionKind.scanNeeded, priority: 0, count: 2),
      );
      expect(containers.title, '2 containers need a scan');
    });

    test('inspectFlagged: the item, or the queue', () {
      final one = d(
        Role.farmer,
        const NextAction(
          kind: NextActionKind.inspectFlagged,
          priority: 0,
          itemId: 'i1',
          label: 'Sack R-004',
        ),
      );
      expect(one.title, 'Inspect Sack R-004');
      expect(one.subtitle, contains('not verified'));
      expect(one.location, Routes.item('i1'));
      expect(one.attention, isTrue);
      final many = d(
        Role.storageFpo,
        const NextAction(
          kind: NextActionKind.inspectFlagged,
          priority: 0,
          count: 2,
        ),
      );
      expect(many.title, '2 flagged sacks to inspect');
      expect(many.location, Routes.queue);
    });

    test('reviewDue and reminderDue open that item', () {
      final review = d(
        Role.household,
        const NextAction(
          kind: NextActionKind.reviewDue,
          priority: 0,
          itemId: 'c1',
          label: 'Rice / Kitchen',
        ),
      );
      expect(review.title, 'Rice / Kitchen: review due');
      expect(review.location, Routes.item('c1'));
      final reminder = d(
        Role.household,
        const NextAction(
          kind: NextActionKind.reminderDue,
          priority: 0,
          itemId: 'c1',
          label: 'Rice / Kitchen',
        ),
      );
      expect(reminder.title, 'Rice / Kitchen: reminder due');
      expect(reminder.location, Routes.item('c1'));
      final many = d(
        Role.household,
        const NextAction(kind: NextActionKind.reviewDue, priority: 0, count: 3),
      );
      expect(many.title, '3 containers due for review');
      expect(many.location, Routes.inventory);
      expect(many.tab, isTrue);
    });

    test('physicalCheckPending opens the lot and never decides', () {
      final s = d(
        Role.buyer,
        const NextAction(
          kind: NextActionKind.physicalCheckPending,
          priority: 0,
          lotId: 'lot-1',
          label: 'LOT-24',
        ),
      );
      expect(s.title, 'Lot LOT-24: physical check pending');
      expect(s.location, Routes.lot('lot-1'));
      expect(s.subtitle, contains('never accepts or rejects'));
    });

    test('finishBatch continues the batch run for its place', () {
      final s = d(
        Role.storageFpo,
        const NextAction(
          kind: NextActionKind.finishBatch,
          priority: 0,
          count: 5,
          locationId: 'room-2',
          label: 'Room 2',
        ),
      );
      expect(s.title, 'Finish the batch: Room 2');
      expect(s.subtitle, '5 sacks left to scan, one at a time');
      expect(s.location, '/batch/run?locationId=room-2');
    });

    test('exports open Reports with the scope preset', () {
      final preSale = d(
        Role.farmer,
        const NextAction(
          kind: NextActionKind.exportPreSale,
          priority: 0,
          harvestId: 'h1',
          label: 'Rabi 2026',
        ),
      );
      expect(preSale.title, 'Share the pre-sale report for Rabi 2026');
      expect(
        preSale.location,
        Routes.reportPreset(ReportKind.preSale, harvestId: 'h1'),
      );
      expect(preSale.tab, isTrue);
      final lot = d(
        Role.buyer,
        const NextAction(
          kind: NextActionKind.exportLotSummary,
          priority: 0,
          lotId: 'lot-1',
        ),
      );
      expect(lot.title, en.nextLotSummary);
      expect(
        lot.location,
        Routes.reportPreset(ReportKind.lotSummary, lotId: 'lot-1'),
      );
    });

    test('every kind has copy for every role', () {
      for (final role in Role.values) {
        for (final kind in NextActionKind.values) {
          final s = d(role, NextAction(kind: kind, priority: 0, count: 2));
          expect(s.title, isNotEmpty, reason: '$role $kind');
          expect(s.title, isNot(contains('{')), reason: '$role $kind');
          expect(s.location, startsWith('/'), reason: '$role $kind');
        }
      }
    });
  });

  group('Next-step homes', () {
    testWidgets('farmer: top action leads, two more rows, scan shortcut', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final sack = await env.addItem(label: 'Sack R-004');
      final harvest = await env.harvests.create(
        HarvestDraft(
          name: 'Rabi 2026',
          grainType: 'Wheat',
          harvestedAt: DateTime(2026, 4, 1),
        ),
      );
      env.analytics.setNextActions(Role.farmer, [
        NextAction(
          kind: NextActionKind.inspectFlagged,
          priority: 0,
          itemId: sack.id,
          label: 'Sack R-004',
        ),
        const NextAction(
          kind: NextActionKind.scanNeeded,
          priority: 1,
          count: 3,
        ),
        NextAction(
          kind: NextActionKind.exportPreSale,
          priority: 2,
          harvestId: harvest.id,
          label: 'Rabi 2026',
        ),
        const NextAction(
          kind: NextActionKind.reminderDue,
          priority: 3,
          count: 2,
        ),
      ]);
      await pumpKernelApp(tester, env);

      expect(_inHero(en.nextStepEyebrow.toUpperCase()), findsOneWidget);
      expect(_inHero('Inspect Sack R-004'), findsOneWidget);
      expect(_inRow(1, '3 sacks need a scan'), findsOneWidget);
      expect(_inRow(2, 'Share the pre-sale report for Rabi 2026'), findsOneWidget);
      // At most two secondary rows.
      expect(find.byKey(const Key('next-step-3')), findsNothing);
      // The hero is not a scan, so scanning stays one tap away.
      expect(find.byKey(const Key('quick-scan')), findsOneWidget);
      expect(find.byKey(const Key('hero-scan')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      expect(find.byType(ItemDetailScreen), findsOneWidget);

      await _goHome(tester);
      await tapVisible(tester, find.byKey(const Key('next-step-1')));
      expect(find.byType(ScanTabScreen), findsOneWidget);

      await _goHome(tester);
      await tapVisible(tester, find.byKey(const Key('next-step-2')));
      expect(find.byKey(const Key('report-preset')), findsOneWidget);
      expect(find.text(en.preSaleCardHarvest('Rabi 2026')), findsOneWidget);

      await _goHome(tester);
      await tapVisible(tester, find.byKey(const Key('quick-scan')));
      expect(find.byType(ScanTabScreen), findsOneWidget);
    });

    testWidgets('a scan hero needs no extra scan shortcut', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final sack = await env.addItem(label: 'Sack R-7');
      env.analytics.setNextActions(Role.farmer, [
        NextAction(
          kind: NextActionKind.scanNeeded,
          priority: 0,
          itemId: sack.id,
          label: 'Sack R-7',
        ),
      ]);
      await pumpKernelApp(tester, env);
      expect(_inHero('Scan Sack R-7'), findsOneWidget);
      expect(find.byKey(const Key('quick-scan')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      expect(find.byType(GuidedScanScreen), findsOneWidget);
    });

    testWidgets('household: review due opens the container', (tester) async {
      final env = TestEnv(role: Role.household);
      final tin = await env.addItem(
        role: Role.household,
        label: 'Rice / Kitchen',
        grain: 'Rice',
      );
      env.analytics.setNextActions(Role.household, [
        NextAction(
          kind: NextActionKind.reviewDue,
          priority: 0,
          itemId: tin.id,
          label: 'Rice / Kitchen',
        ),
      ]);
      await pumpKernelApp(tester, env);
      expect(_inHero('Rice / Kitchen: review due'), findsOneWidget);
      expect(find.byKey(const Key('household-activity')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      expect(find.byType(ItemDetailScreen), findsOneWidget);
    });

    testWidgets('FPO: finish batch opens the batch run for the place', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      final room = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Room 2'),
      );
      await env.addItem(
        role: Role.storageFpo,
        label: 'S-1',
        locationId: room.id,
      );
      env.analytics.setNextActions(Role.storageFpo, [
        NextAction(
          kind: NextActionKind.finishBatch,
          priority: 0,
          count: 1,
          locationId: room.id,
          label: 'Room 2',
        ),
        const NextAction(
          kind: NextActionKind.inspectFlagged,
          priority: 1,
          count: 2,
        ),
      ]);
      await pumpKernelApp(tester, env);
      expect(_inHero('Finish the batch: Room 2'), findsOneWidget);
      expect(_inRow(1, '2 flagged sacks to inspect'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      final batch = tester.widget<BatchSessionScreen>(
        find.byType(BatchSessionScreen),
      );
      expect(batch.locationId, room.id);

      await _goHome(tester);
      await tapVisible(tester, find.byKey(const Key('next-step-1')));
      expect(find.byType(QueueScreen), findsOneWidget);
    });

    testWidgets('buyer: physical check opens the lot; export shortcut', (
      tester,
    ) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'LOT-24',
          grainType: 'Rice',
          declaredQuantity: 10,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 1),
        ),
      );
      env.analytics.setNextActions(Role.buyer, [
        NextAction(
          kind: NextActionKind.physicalCheckPending,
          priority: 0,
          lotId: lot.id,
          label: 'LOT-24',
        ),
        NextAction(
          kind: NextActionKind.exportLotSummary,
          priority: 1,
          lotId: lot.id,
          label: 'LOT-24',
        ),
      ]);
      await pumpKernelApp(tester, env);
      expect(_inHero('Lot LOT-24: physical check pending'), findsOneWidget);
      expect(find.byKey(const Key('quick-scan')), findsOneWidget);
      expect(find.byKey(const Key('quick-register-lot')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      expect(find.byType(LotDetailScreen), findsOneWidget);

      await _goHome(tester);
      await tapVisible(tester, find.byKey(const Key('next-step-1')));
      expect(find.byKey(const Key('report-preset')), findsOneWidget);
      expect(find.text(en.lotSummaryTitle('LOT-24')), findsWidgets);
    });

    testWidgets('registerFirst opens the register form', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.addItem(label: 'Sack A');
      env.analytics.setNextActions(Role.farmer, [
        const NextAction(kind: NextActionKind.registerFirst, priority: 0),
      ]);
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(const Key('next-step-hero')));
      expect(find.byType(ItemFormScreen), findsOneWidget);
    });

    testWidgets('nothing pending keeps the everyday hero', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      await env.addItem(role: Role.storageFpo, label: 'S-1');
      await pumpKernelApp(tester, env);
      expect(find.byKey(const Key('next-step-hero')), findsNothing);
      expect(find.byKey(const Key('hero-scan')), findsOneWidget);
      expect(find.byKey(const Key('next-none')), findsOneWidget);
      expect(find.text(en.nextNothingPending), findsOneWidget);
    });

    for (final role in Role.values) {
      testWidgets('${role.name}: zero data shows one empty-state action', (
        tester,
      ) async {
        final env = TestEnv(role: role);
        env.analytics.setNextActions(role, [
          const NextAction(kind: NextActionKind.registerFirst, priority: 0),
        ]);
        await pumpKernelApp(tester, env);
        final empty = find.byKey(
          Key(role == Role.buyer ? 'empty-lots' : 'empty-items'),
        );
        expect(empty, findsOneWidget);
        expect(
          find.descendant(of: empty, matching: find.byType(FilledButton)),
          findsOneWidget,
        );
        // The empty state is the single next action; no duplicate hero.
        expect(find.byKey(const Key('next-step-hero')), findsNothing);
      });
    }

    testWidgets('home counts come from AnalyticsService', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      final a = await env.addItem(role: Role.storageFpo, label: 'S-1');
      await env.scans.record(notEvaluatedOutcome(a.id));
      await env.scans.record(retryOutcome(a.id));
      await env.addInspection(a.id, VerifiedFinding.inconclusive);
      await pumpKernelApp(tester, env);
      // PASS scans only count as scanned; the RETRY does not.
      expect(find.text(en.scansTodayCount(1)), findsOneWidget);
      expect(find.text(en.inspectionsOpen(1)), findsOneWidget);
      expect(
        env.analytics.filters.any((f) => f.role == Role.storageFpo),
        isTrue,
      );
    });

    testWidgets('resume re-subscribes time-based analytics', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.addItem(label: 'Sack A');
      await pumpKernelApp(tester, env);
      final before = env.analytics.nextActionWatches[Role.farmer] ?? 0;
      expect(before, greaterThan(0));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(env.analytics.nextActionWatches[Role.farmer], greaterThan(before));
      expect(find.text(en.farmerHomeTitle), findsOneWidget);
    });
  });
}
