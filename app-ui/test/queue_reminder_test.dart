import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/widgets/status_chip.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

String _chip(WidgetTester tester, String key) =>
    tester.widget<StatusChip>(find.byKey(Key(key))).label;

void main() {
  group('Inspection queue filters', () {
    late TestEnv env;
    late GrainItem s1, s2, s3, s4;
    late Location roomA, roomB;

    Future<void> seed() async {
      env = TestEnv(role: Role.storageFpo);
      roomA = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Room A'),
      );
      roomB = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Room B'),
      );
      s1 = await env.addItem(
        role: Role.storageFpo,
        label: 'S-1',
        locationId: roomA.id,
      );
      s2 = await env.addItem(
        role: Role.storageFpo,
        label: 'S-2',
        locationId: roomB.id,
      );
      s3 = await env.addItem(role: Role.storageFpo, label: 'S-3');
      s4 = await env.addItem(role: Role.storageFpo, label: 'S-4');
      final now = DateTime.now();
      await env.scans.record(modelOutcome(s1.id, Classification.infested));
      await env.scans.record(
        modelOutcome(
          s2.id,
          Classification.uncertain,
          at: now.subtract(const Duration(days: 3)),
        ),
      );
      await env.scans.record(
        modelOutcome(
          s3.id,
          Classification.clean,
          at: now.subtract(const Duration(days: 20)),
        ),
      );
    }

    testWidgets('every ranked entry has a reason chip and an age label', (
      tester,
    ) async {
      await seed();
      await pumpKernelApp(tester, env, location: Routes.queue);

      expect(_chip(tester, 'reason-${s1.id}'), en.rankReasonInfested);
      expect(_chip(tester, 'reason-${s2.id}'), en.rankReasonUncertain);
      expect(_chip(tester, 'reason-${s3.id}'), en.rankReasonClean);
      expect(_chip(tester, 'age-${s1.id}'), en.scannedDaysAgo(0));
      expect(_chip(tester, 'age-${s2.id}'), en.scannedDaysAgo(3));
      expect(_chip(tester, 'age-${s3.id}'), en.scannedDaysAgo(20));
      // Never-scanned items are never ranked.
      expect(find.byKey(Key('reason-${s4.id}')), findsNothing);
      expect(find.text(en.needsScanTitle(1)), findsOneWidget);
      // Rank order: infested, uncertain, clean.
      final y1 = tester.getTopLeft(find.byKey(Key('reason-${s1.id}'))).dy;
      final y2 = tester.getTopLeft(find.byKey(Key('reason-${s2.id}'))).dy;
      final y3 = tester.getTopLeft(find.byKey(Key('reason-${s3.id}'))).dy;
      expect(y1 < y2 && y2 < y3, isTrue);
    });

    testWidgets('result, place and age chips narrow the queue', (tester) async {
      await seed();
      await pumpKernelApp(tester, env, location: Routes.queue);

      await tapVisible(tester, find.byKey(const Key('filter-result-infested')));
      expect(env.ranking.calls.last.result, Classification.infested);
      expect(find.byKey(Key('reason-${s1.id}')), findsOneWidget);
      expect(find.byKey(Key('reason-${s2.id}')), findsNothing);
      expect(find.byKey(Key('reason-${s3.id}')), findsNothing);

      await tapVisible(tester, find.byKey(Key('filter-location-${roomB.id}')));
      expect(env.ranking.calls.last.locationId, roomB.id);
      expect(find.byKey(const Key('queue-ranked-empty')), findsOneWidget);
      expect(find.text(en.queueNoMatch), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('filter-result-all')));
      expect(find.byKey(Key('reason-${s2.id}')), findsOneWidget);
      expect(find.byKey(Key('reason-${s1.id}')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('filter-location-all')));
      await tapVisible(tester, find.byKey(const Key('filter-age-14')));
      expect(env.ranking.calls.last.maxAge, const Duration(days: 14));
      expect(find.text(en.queueFilterAgeNote(14)), findsOneWidget);
      // S-3's last usable scan is 20 days old: it now needs a scan.
      expect(find.byKey(Key('reason-${s3.id}')), findsNothing);
      expect(find.text(en.needsScanTitle(2)), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('filter-age-any')));
      expect(env.ranking.calls.last.maxAge, isNull);
      expect(find.byKey(Key('reason-${s3.id}')), findsOneWidget);
    });

    testWidgets('filters fit at 200% text', (tester) async {
      await seed();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpKernelApp(tester, env, location: Routes.queue);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('queue-filters')), findsOneWidget);
    });
  });

  group('Reminder suggestion', () {
    Future<(TestEnv, GrainItem, DateTime)> seed() async {
      final env = TestEnv(role: Role.household);
      final tin = await env.addItem(
        role: Role.household,
        label: 'Rice / Kitchen',
        grain: 'Rice',
      );
      final day = DateTime.now().add(const Duration(days: 12));
      final suggestion = DateTime(day.year, day.month, day.day, 9);
      env.reminders.suggestion = suggestion;
      return (env, tin, suggestion);
    }

    testWidgets('prefills the suggested date; the user confirms', (
      tester,
    ) async {
      final (env, tin, suggestion) = await seed();
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(Key('remind-${tin.id}')));

      expect(env.reminders.suggestCalls, [tin.id]);
      expect(find.byKey(const Key('reminder-suggested')), findsOneWidget);
      expect(find.text(en.reminderSuggestedLabel), findsOneWidget);
      // Nothing is scheduled until the user saves.
      expect(env.reminders.reminders, isEmpty);
      // No AI wording while the assistant is off.
      expect(find.byKey(const Key('reminder-wording')), findsNothing);
      expect(env.advice.reminderCalls, isEmpty);

      await tapVisible(tester, find.byKey(const Key('reminder-save')));
      expect(env.reminders.reminders.single.dueAt, suggestion);
    });

    testWidgets('changing the date keeps the suggestion visible', (
      tester,
    ) async {
      final (env, tin, _) = await seed();
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(Key('remind-${tin.id}')));
      await tapVisible(tester, find.byKey(const Key('reminder-preset-7')));
      expect(find.text(en.reminderSuggestedLabel), findsNothing);
      expect(find.textContaining('— you choose'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('reminder-save')));
      final today = DateUtils.dateOnly(DateTime.now());
      expect(
        DateUtils.dateOnly(env.reminders.reminders.single.dueAt),
        today.add(const Duration(days: 7)),
      );
    });

    testWidgets('with the assistant ready, shows optional wording', (
      tester,
    ) async {
      final (env, tin, suggestion) = await seed();
      await env.enableAdvice();
      env.advice.reminderScript = adviceEvents([
        'Check the rice tin',
        'next week.',
      ]);
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(Key('remind-${tin.id}')));

      final card = find.byKey(const Key('reminder-wording'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.text('Check the rice tin next week.'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(en.adviceProvenance(testAdviceModelVersion)),
        findsOneWidget,
      );
      final (input, tag) = env.advice.reminderCalls.single;
      expect(input.role, Role.household);
      expect(input.grainType, 'Rice');
      expect(input.suggestedDueAt, suggestion);
      expect(input.lastResult, isNull);
      expect(tag, 'en');
      // The wording is a suggestion only; the user still saves the time.
      expect(env.reminders.reminders, isEmpty);
    });
  });
}
