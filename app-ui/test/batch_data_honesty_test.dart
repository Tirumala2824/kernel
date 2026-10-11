import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/copy.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_engine.dart';

class _BatchEnv extends TestEnv {
  _BatchEnv() : super(role: Role.storageFpo);
  final today = StreamController<List<ScanRecord>>.broadcast();
  final queues = StreamController<InspectionQueue>.broadcast();
  bool holdQueue = false;
  static const QueueScope scope = (
    role: Role.storageFpo,
    locationId: null,
    lotId: null,
  );
  late InspectionQueue initialQueue;
  final todayKey = (since: startOfToday(), role: null);

  @override
  List<Override> get overrides => [
    ...super.overrides,
    scansSinceProvider(todayKey).overrideWith((ref) => today.stream),
    inspectionQueueProvider(scope).overrideWith(
      (ref) => holdQueue ? queues.stream : Stream.value(initialQueue),
    ),
  ];
}

void main() {
  testWidgets(
    'batch eligibility never substitutes unavailable history with zero',
    (tester) async {
      final env = _BatchEnv();
      addTearDown(env.today.close);
      addTearDown(env.queues.close);
      final item = await env.addItem(
        role: Role.storageFpo,
        label: 'Already recorded',
      );
      final scan = await env.scans.record(retryOutcome(item.id));
      env.initialQueue = await env.ranking
          .watchQueue(role: Role.storageFpo)
          .first;
      expect(env.initialQueue.needsScan.map((i) => i.id), contains(item.id));
      await pumpKernelApp(tester, env, location: Routes.batchRun());
      final startKey = find.byKey(const Key('batch-start'));
      VoidCallback? startAction() => startKey.evaluate().isEmpty
          ? null
          : tester.widget<FilledButton>(startKey).onPressed;
      void expectUnknownCount() {
        expect(startAction(), isNull);
        expect(find.text(en.batchIntroSubtitle(1)), findsNothing);
        expect(find.text(en.batchStart(1)), findsNothing);
        expect(find.text(en.batchNothingToWalk), findsNothing);
        expect(
          find.text(en.batchWalkLine(1, item.label, item.grainType)),
          findsNothing,
        );
      }

      expectUnknownCount();
      env.today.addError(StateError('today unavailable'));
      await tester.pumpAndSettle();
      expectUnknownCount();
      expect(find.text(en.errorCouldNotLoad), findsWidgets);
      env.today.add([scan]);
      await tester.pumpAndSettle();
      expect(startAction(), isNull);
      expect(find.text(en.batchNothingToWalk), findsOneWidget);
      env.today.add([]);
      await tester.pumpAndSettle();
      expect(startAction(), isNotNull);
      expect(find.text(en.batchStart(1)), findsOneWidget);

      final staleStart = startAction()!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KernelApp)),
      );
      final todayProvider = scansSinceProvider(env.todayKey);
      container.invalidate(todayProvider);
      // A callback captured before the rebuild must not freeze a stale walk.
      staleStart();
      await tester.pump();
      expect(container.read(todayProvider).isLoading, isTrue);
      expect(container.read(todayProvider).hasValue, isTrue);
      expect(find.byKey(const Key('batch-progress')), findsNothing);
      expectUnknownCount();
      env.today.addError(StateError('today refresh failed'));
      await tester.pumpAndSettle();
      expectUnknownCount();

      // Without this optional filter, today's history is not required.
      await tester.tap(find.byKey(const Key('batch-skip-today')));
      await tester.pumpAndSettle();
      expect(startAction(), isNotNull);
      expect(find.text(en.batchStart(1)), findsOneWidget);
      final queueStart = startAction()!;
      env.holdQueue = true;
      final queueProvider = inspectionQueueProvider(_BatchEnv.scope);
      container.invalidate(queueProvider);
      queueStart();
      await tester.pump();
      expect(container.read(queueProvider).isLoading, isTrue);
      expect(container.read(queueProvider).hasValue, isTrue);
      expect(find.byKey(const Key('batch-progress')), findsNothing);
      expectUnknownCount();
      env.queues.addError(StateError('queue refresh failed'));
      await tester.pumpAndSettle();
      expectUnknownCount();
      env.queues.add(env.initialQueue);
      await tester.pumpAndSettle();
      expect(startAction(), isNotNull);
      await tester.tap(startKey);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('batch-current-${item.id}')), findsOneWidget);
      expect(
        env.engine.calls,
        isEmpty,
        reason: 'capture still requires a user action',
      );
    },
  );
}
