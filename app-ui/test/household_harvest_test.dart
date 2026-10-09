import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/app/rules.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

ScanRecord _scanAt(DateTime at, {ScanQuality quality = ScanQuality.pass}) =>
    ScanRecord(
      id: 's',
      itemId: 'i',
      capturedAt: at,
      durationMs: 2000,
      sampleRate: 16000,
      quality: quality,
      qualityReasons: quality == ScanQuality.retry
          ? const [QualityReason.silence]
          : const [],
      modelVersion: noModelVersion,
      result: Classification.notEvaluated,
      confidence: null,
      experimental: true,
      latencyMs: 1,
      deviceModel: 'd',
      osVersion: 'o',
      createdAt: at,
      updatedAt: at,
      syncState: SyncState.localOnly,
    );

void main() {
  group('Household', () {
    test('review is due from the last usable scan date', () {
      final now = DateTime(2026, 10, 20, 12);
      expect(reviewStatus(const [], now: now).state, ReviewState.neverScanned);
      // A retry is not a check.
      expect(
        reviewStatus([
          _scanAt(DateTime(2026, 10, 19), quality: ScanQuality.retry),
        ], now: now).state,
        ReviewState.neverScanned,
      );
      final recent = reviewStatus([_scanAt(DateTime(2026, 10, 15))], now: now);
      expect(recent.state, ReviewState.upToDate);
      expect(recent.daysUntilDue, 9);
      final old = reviewStatus([_scanAt(DateTime(2026, 10, 1))], now: now);
      expect(old.state, ReviewState.due);
      expect(old.daysSinceScan, 19);
    });

    testWidgets('container card shows review status and a recheck shortcut', (
      tester,
    ) async {
      final env = TestEnv(role: Role.household);
      final bin = await env.addItem(role: Role.household, label: 'Steel bin');
      await pumpKernelApp(tester, env);

      expect(find.text(en.reviewNeverScanned), findsOneWidget);
      await tapVisible(tester, find.byKey(Key('recheck-${bin.id}')));
      expect(find.text(en.guidedScanTitle), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('start-capture')));
      routerOf(tester).go(Routes.home);
      await tester.pumpAndSettle();
      expect(find.text(en.reviewNextIn(14)), findsOneWidget);
    });

    testWidgets('reminder sheet schedules date and time on the phone', (
      tester,
    ) async {
      final env = TestEnv(role: Role.household);
      final bin = await env.addItem(role: Role.household, label: 'Steel bin');
      await pumpKernelApp(tester, env);

      await tapVisible(tester, find.byKey(Key('remind-${bin.id}')));
      expect(find.byKey(const Key('reminder-sheet')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('reminder-preset-14')));
      await tapVisible(tester, find.byKey(const Key('reminder-save')));

      expect(env.permissions.notificationRequests, 1);
      final reminder = env.reminders.reminders.single;
      expect(reminder.itemId, bin.id);
      final expected = DateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 14));
      expect(DateUtils.dateOnly(reminder.dueAt), expected);
      expect(reminder.dueAt.hour, 9);
      expect(find.text(en.reminderSet), findsOneWidget);
      expect(find.text(en.remindersScheduled(1)), findsOneWidget);
    });

    testWidgets('a reminder notification opens its item on launch', (
      tester,
    ) async {
      final env = TestEnv(role: Role.household);
      final bin = await env.addItem(role: Role.household, label: 'Clay pot');
      env.reminders.launchItemId = bin.id;
      await pumpKernelApp(tester, env);

      expect(env.reminders.launchTakes, 1);
      expect(find.text(en.scanHistoryTitle), findsOneWidget);
      expect(find.text('Clay pot'), findsWidgets);
    });
  });

  group('Farmer harvests', () {
    testWidgets('create a harvest, register a sack into it, pre-sale report', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.inventory);

      await tapVisible(tester, find.byKey(const Key('action-new-harvest')));
      await tester.enterText(
        find.byKey(const Key('field-harvest-name')),
        'Rabi wheat',
      );
      await tester.enterText(find.byKey(const Key('field-grain')), 'Wheat');
      await tapVisible(tester, find.byKey(const Key('save')));
      final harvest = env.harvests.harvests.single;
      expect(harvest.name, 'Rabi wheat');
      expect(find.byKey(const Key('empty-harvest-sacks')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('harvest-add-sack')));
      // Grain type is prefilled from the harvest.
      await tester.enterText(find.byKey(const Key('field-label')), 'R-1');
      await tester.enterText(find.byKey(const Key('field-quantity')), '40');
      await tapVisible(tester, find.byKey(const Key('save')));
      final sack = env.items.items.single;
      expect(sack.harvestId, harvest.id);
      expect(sack.grainType, 'Wheat');

      routerOf(tester).go(Routes.harvest(harvest.id));
      await tester.pumpAndSettle();
      expect(find.text('R-1'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('export-preSale-pdf')));
      final (scope, format) = env.reports.calls.single;
      expect(scope.kind, ReportKind.preSale);
      expect(scope.harvestId, harvest.id);
      expect(scope.role, Role.farmer);
      expect(format, ReportFormat.pdf);
      expect(env.sharer.shared, hasLength(1));
    });

    testWidgets('home subtitle names the latest harvest', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.harvests.create(
        HarvestDraft(
          name: 'Kharif paddy',
          grainType: 'Paddy',
          harvestedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpKernelApp(tester, env);
      expect(find.text(en.farmerHomeHarvestSubtitle('Kharif paddy')), findsOneWidget);
      expect(find.text(en.harvestsCount(1)), findsOneWidget);
    });
  });

  group('Buyer lot flow', () {
    testWidgets('sample scans, physical checks and lot summary', (
      tester,
    ) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'L-9',
          grainType: 'Maize',
          declaredQuantity: 4,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 2),
        ),
      );
      final sack = await env.addItem(role: Role.buyer, label: 'B-1', lotId: lot.id);
      await pumpKernelApp(tester, env, location: Routes.lot(lot.id));

      expect(find.text(en.sampleScansTitle), findsOneWidget);
      expect(find.text(en.physicalChecksTitle), findsOneWidget);
      expect(find.text(en.noPhysicalCheckYet), findsOneWidget);
      // No accept/reject buttons anywhere.
      expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Reject'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('export-lotSummary-csv')));
      final (scope, _) = env.reports.calls.single;
      expect(scope.kind, ReportKind.lotSummary);
      expect(scope.lotId, lot.id);

      await tapVisible(tester, find.byKey(const Key('start-sample-scans')));
      await tapVisible(tester, find.byKey(const Key('batch-start')));
      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(env.engine.calls.single.itemId, sack.id);
      expect(find.byKey(const Key('batch-summary')), findsOneWidget);
      // Screening status never changes from a scan.
      expect(env.lots.lots.single.screeningStatus, ScreeningStatus.pending);
    });
  });
}
