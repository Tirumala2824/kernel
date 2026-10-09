import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

Future<(TestEnv, Location)> _room() async {
  final env = TestEnv(role: Role.storageFpo);
  final warehouse = await env.locations.create(
    const LocationDraft(type: LocationType.warehouse, name: 'North'),
  );
  final room = await env.locations.create(
    LocationDraft(type: LocationType.room, name: 'Room 1', parentId: warehouse.id),
  );
  await env.addItem(role: Role.storageFpo, label: 'S-2', locationId: room.id);
  await env.addItem(role: Role.storageFpo, label: 'S-1', locationId: room.id);
  // Elsewhere: never part of this session.
  await env.addItem(role: Role.storageFpo, label: 'Other');
  return (env, room);
}

void main() {
  group('FPO batch session (F08)', () {
    testWidgets('walks sacks one by one, auto-advances, then summarises', (
      tester,
    ) async {
      final (env, room) = await _room();
      await pumpKernelApp(
        tester,
        env,
        location: Routes.batchRun(locationId: room.id),
      );

      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text(en.batchWalkLine(1, 'S-1', 'Wheat')), findsOneWidget);
      expect(find.text(en.batchWalkLine(2, 'S-2', 'Wheat')), findsOneWidget);
      expect(find.textContaining('Other'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('batch-start')));
      expect(find.text(en.batchProgress(1, 2)), findsOneWidget);
      expect(find.text('S-1'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('start-capture')));
      // The usable result counts down and moves on by itself.
      expect(env.engine.calls.map((c) => c.itemId), hasLength(1));
      expect(find.text(en.batchProgress(2, 2)), findsOneWidget);
      expect(find.text('S-2'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(env.engine.calls, hasLength(2));
      expect(find.byKey(const Key('batch-summary')), findsOneWidget);
      expect(find.text(en.batchSummaryTitle), findsOneWidget);
      // One recording per sack, in walk order.
      final ids = env.engine.calls.map((c) => c.itemId).toList();
      final labels = [
        for (final id in ids)
          env.items.items.singleWhere((i) => i.id == id).label,
      ];
      expect(labels, ['S-1', 'S-2']);
      expect(env.scans.scans, hasLength(2));
      // No model: nothing ranked, both sacks still need a scan.
      expect(find.text(en.queueNothingRanked), findsOneWidget);
      expect(find.text(en.needsScanTitle(2)), findsOneWidget);
    });

    testWidgets('retry waits; skip and stop end early', (tester) async {
      final (env, room) = await _room();
      env.engine.next = retryOutcome;
      await pumpKernelApp(
        tester,
        env,
        location: Routes.batchRun(locationId: room.id),
      );
      await tapVisible(tester, find.byKey(const Key('batch-start')));

      await tapVisible(tester, find.byKey(const Key('start-capture')));
      // RETRY does not auto-advance.
      expect(find.byKey(const Key('batch-result')), findsOneWidget);
      expect(find.text(en.headlineRetry), findsOneWidget);
      expect(find.text(en.batchProgress(1, 2)), findsOneWidget);
      expect(find.byKey(const Key('batch-countdown')), findsNothing);

      // Record the same sack again.
      env.engine.next = notEvaluatedOutcome;
      await tapVisible(tester, find.byKey(const Key('batch-retry')));
      expect(env.engine.calls, hasLength(2));
      expect(env.engine.calls[0].itemId, env.engine.calls[1].itemId);
      expect(find.text(en.batchProgress(2, 2)), findsOneWidget);

      // Skip the second sack: straight to the summary, nothing recorded.
      await tapVisible(tester, find.byKey(const Key('batch-skip')));
      expect(env.engine.calls, hasLength(2));
      expect(find.byKey(const Key('batch-summary')), findsOneWidget);
    });

    testWidgets('stop shows the summary at once', (tester) async {
      final (env, room) = await _room();
      await pumpKernelApp(
        tester,
        env,
        location: Routes.batchRun(locationId: room.id),
      );
      await tapVisible(tester, find.byKey(const Key('batch-start')));
      await tapVisible(tester, find.byKey(const Key('batch-stop')));
      expect(find.byKey(const Key('batch-summary')), findsOneWidget);
      expect(env.engine.calls, isEmpty);
    });

    testWidgets('setup lists rooms and stacks with counts', (tester) async {
      final (env, room) = await _room();
      await pumpKernelApp(tester, env, location: Routes.batchSetup);
      expect(find.byKey(Key('batch-place-${room.id}')), findsOneWidget);
      expect(
        find.text(en.batchPlaceSubtitle(en.locationTypeRoom, 2, 2)),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(Key('batch-place-${room.id}')));
      expect(find.byKey(const Key('batch-start')), findsOneWidget);
    });
  });
}
