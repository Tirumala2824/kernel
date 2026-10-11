import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:kernel_app/widgets/common.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/sensors/sensor_providers.dart';
import 'package:kernel_app/features/sensors/sensor_widgets.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

class _CommandLink extends ScriptedSensorLink {
  Completer<void>? sessionGate;
  Completer<int>? syncGate;

  @override
  Future<void> startSession(String nodeId) async {
    sessionsStarted.add(nodeId);
    await sessionGate?.future;
  }

  @override
  Future<void> stopSession(String nodeId) async {
    sessionsStopped.add(nodeId);
    await sessionGate?.future;
  }

  @override
  Future<int> syncEvents(String nodeId) async {
    syncCalls.add(nodeId);
    return await syncGate?.future ?? 0;
  }
}

class _StatusEnv extends TestEnv {
  _StatusEnv() : super(role: Role.storageFpo);

  final statuses = StreamController<SensorStatus>.broadcast();
  final _link = _CommandLink();

  @override
  _CommandLink get sensorLink => _link;

  @override
  List<Override> get overrides => [
    ...super.overrides,
    sensorStatusProvider('n1').overrideWith((ref) => statuses.stream),
  ];
}

class _LiveLink extends _CommandLink {
  final frames = StreamController<BandFrame>.broadcast();

  @override
  Stream<BandFrame> liveBands(String nodeId) => frames.stream;
}

class _LiveEnv extends _StatusEnv {
  final liveLink = _LiveLink();

  @override
  _LiveLink get sensorLink => liveLink;
}

BandFrame _bandFrame(int seq) => BandFrame(
  nodeId: 'n1',
  seq: seq,
  at: DateTime(2026, 10, 11, 9, 0, seq),
  frameMs: 250,
  noiseFloorDbfs: -80,
  bandEdgesHz: const [20000, 30000],
  bandsDbAboveFloor: const [12],
  peakHz: 25000,
  peakDbfs: -52,
);

class _EvidenceEnv extends TestEnv {
  _EvidenceEnv() : super(role: Role.farmer);

  late String itemId;
  final nodes = StreamController<List<SensorNode>>.broadcast();
  final events = StreamController<List<SensorEvent>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    sensorNodesProvider.overrideWith((ref) => nodes.stream),
    sensorEventsForItemProvider(itemId).overrideWith((ref) => events.stream),
  ];
}

class _HistoryEnv extends TestEnv {
  _HistoryEnv() : super(role: Role.farmer);

  late String itemId;
  final history = StreamController<List<SensorNotEvaluatedPeriod>>.broadcast();
  final events = StreamController<List<SensorEvent>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    sensorNotEvaluatedForItemProvider(itemId)
        .overrideWith((ref) => history.stream),
    sensorNotEvaluatedForNodeProvider('n1')
        .overrideWith((ref) => history.stream),
    sensorEventsForNodeProvider('n1').overrideWith((ref) => events.stream),
  ];
}

class _PlacementEnv extends TestEnv {
  _PlacementEnv() : super(role: Role.storageFpo);

  var place = Completer<Location?>();
  var item = Completer<GrainItem?>();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    locationProvider('place').overrideWith((ref) => place.future),
    itemProvider('item').overrideWith((ref) => item.future),
  ];
}

SensorStatus observed({
  bool active = false,
  SensorLinkState link = SensorLinkState.authenticated,
  Set<SensorHealth> health = const {SensorHealth.ok},
}) => SensorStatus(
  nodeId: 'n1',
  linkState: link,
  health: health,
  sessionActive: active,
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(KernelApp)));

void main() {
  for (final gap in ['disconnect', 'error', 'refresh']) {
    testWidgets('live bands require a fresh frame after status $gap', (
      tester,
    ) async {
      final env = _LiveEnv();
      addTearDown(env.statuses.close);
      addTearDown(env.sensorLink.frames.close);
      await env.sensorNodes.upsert(testNode(id: 'n1'));
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      env.sensorLink.frames.add(_bandFrame(1));
      await tester.pumpAndSettle();
      expect(find.byType(SensorBandBars), findsOneWidget);
      switch (gap) {
        case 'disconnect':
          env.statuses.add(observed(link: SensorLinkState.disconnected));
        case 'error':
          env.statuses.addError(StateError('link lost'));
        case 'refresh':
          containerOf(tester).invalidate(sensorStatusProvider('n1'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(SensorBandBars), findsNothing);
      expect(find.byKey(const Key('sensor-live-waiting')), findsOneWidget);
      env.sensorLink.frames.add(_bandFrame(2));
      await tester.pumpAndSettle();
      expect(find.byType(SensorBandBars), findsNothing);
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(
        find.byType(SensorBandBars),
        findsNothing,
        reason: 'reconnection alone is not a new band frame',
      );
      env.sensorLink.frames.add(_bandFrame(3));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SensorBandBars>(find.byType(SensorBandBars)).frame.seq,
        3,
      );
      // Ordinary status updates on the same connection keep the real frame.
      env.statuses.add(observed(active: true));
      await tester.pumpAndSettle();
      expect(find.byType(SensorBandBars), findsOneWidget);
    });
  }

  testWidgets('bands without an observed connection are not live', (
    tester,
  ) async {
    final env = _LiveEnv();
    addTearDown(env.statuses.close);
    addTearDown(env.sensorLink.frames.close);
    await env.sensorNodes.upsert(testNode(id: 'n1'));
    await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
    env.sensorLink.frames.add(_bandFrame(1));
    await tester.pumpAndSettle();
    expect(find.byType(SensorBandBars), findsNothing);
    env.statuses.add(observed());
    await tester.pumpAndSettle();
    expect(find.byType(SensorBandBars), findsNothing);
    env.sensorLink.frames.add(_bandFrame(2));
    await tester.pumpAndSettle();
    expect(find.byType(SensorBandBars), findsOneWidget);
  });

  testWidgets(
    'assigned placement IDs do not become Not set while lookup is unavailable',
    (tester) async {
      final env = _PlacementEnv();
      await env.sensorNodes.upsert(
        testNode(id: 'n1', locationId: 'place', itemId: 'item'),
      );
      final place = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Observed room'),
      );
      final item = await env.addItem(label: 'Observed sack');
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      String field(String label) => tester
          .widgetList<FieldRow>(find.byType(FieldRow))
          .singleWhere((row) => row.label == label)
          .value;
      expect(field(en.sensorFieldPlace), en.loading);
      expect(field(en.sensorFieldItem), en.loading);
      expect(find.text(en.sensorPlaceNone), findsNothing);
      env.place.completeError(StateError('place unavailable'));
      env.item.completeError(StateError('item unavailable'));
      await tester.pumpAndSettle();
      expect(field(en.sensorFieldPlace), en.errorCouldNotLoad);
      expect(field(en.sensorFieldItem), en.errorCouldNotLoad);
      env.place = Completer<Location?>()..complete(place);
      env.item = Completer<GrainItem?>()..complete(item);
      final container = containerOf(tester);
      container.invalidate(locationProvider('place'));
      container.invalidate(itemProvider('item'));
      await tester.pumpAndSettle();
      expect(
        field(en.sensorFieldPlace),
        en.nameWithType(place.name, en.locationTypeRoom),
      );
      expect(field(en.sensorFieldItem), item.label);
      env.place = Completer<Location?>();
      env.item = Completer<GrainItem?>();
      container.invalidate(locationProvider('place'));
      container.invalidate(itemProvider('item'));
      await tester.pump();
      expect(container.read(locationProvider('place')).isLoading, isTrue);
      expect(container.read(locationProvider('place')).hasValue, isTrue);
      expect(container.read(itemProvider('item')).isLoading, isTrue);
      expect(container.read(itemProvider('item')).hasValue, isTrue);
      expect(field(en.sensorFieldPlace), en.loading);
      expect(field(en.sensorFieldItem), en.loading);
      env.place.complete(null);
      env.item.complete(null);
      await tester.pumpAndSettle();
      expect(field(en.sensorFieldPlace), en.errorCouldNotLoad);
      expect(field(en.sensorFieldItem), en.errorCouldNotLoad);
      expect(find.byKey(const Key('sensor-change-placement')), findsOneWidget);
    },
  );

  testWidgets('unassigned placement is genuinely Not set', (tester) async {
    final env = TestEnv(role: Role.storageFpo);
    await env.sensorNodes.upsert(testNode(id: 'n1'));
    await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
    expect(find.text(en.sensorPlaceNone), findsNWidgets(2));
  });

  testWidgets(
    'session commands are busy only while pending and failures stay failures',
    (tester) async {
      final env = _StatusEnv();
      addTearDown(env.statuses.close);
      await env.sensorNodes.upsert(testNode(id: 'n1'));
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      final start = find.byKey(const Key('sensor-session-start'));
      final running = find.byKey(const Key('sensor-session-running'));
      env.sensorLink.sessionGate = Completer<void>();
      await tapVisible(tester, start);
      expect(tester.widget<FilledButton>(start).onPressed, isNull);
      expect(running, findsNothing);
      await tester.pump(const Duration(hours: 8));
      expect(running, findsNothing);
      env.sensorLink.sessionGate!.completeError(StateError('session failed'));
      await tester.pumpAndSettle();
      expect(
        find.text(en.sensorSessionFailed('Bad state: session failed')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
      expect(running, findsNothing);

      env.sensorLink.sessionGate = null;
      await tapVisible(tester, start);
      expect(env.sensorLink.sessionsStarted, ['n1', 'n1']);
      expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
      expect(running, findsNothing);
      env.statuses.add(observed(active: true));
      await tester.pumpAndSettle();
      final stop = find.byKey(const Key('sensor-session-stop'));
      env.sensorLink.sessionGate = Completer<void>();
      await tapVisible(tester, stop);
      expect(tester.widget<FilledButton>(stop).onPressed, isNull);
      expect(running, findsOneWidget);
      env.sensorLink.sessionGate!.completeError(StateError('stop failed'));
      await tester.pumpAndSettle();
      expect(
        find.text(en.sensorSessionFailed('Bad state: stop failed')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(stop).onPressed, isNotNull);
      expect(running, findsOneWidget);
    },
  );

  testWidgets('sync failure is not a successful zero and can be retried', (
    tester,
  ) async {
    final env = _StatusEnv();
    addTearDown(env.statuses.close);
    await env.sensorNodes.upsert(testNode(id: 'n1'));
    await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
    final sync = find.byKey(const Key('sensor-sync'));
    env.sensorLink.syncGate = Completer<int>();
    await tapVisible(tester, sync);
    expect(tester.widget<OutlinedButton>(sync).onPressed, isNull);
    expect(find.byKey(const Key('sensor-sync-message')), findsNothing);
    env.sensorLink.syncGate!.completeError(StateError('sync failed'));
    await tester.pumpAndSettle();
    expect(
      find.text(en.sensorSyncFailed('Bad state: sync failed')),
      findsOneWidget,
    );
    expect(find.text(en.sensorSynced(0)), findsNothing);
    expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
    env.sensorLink.syncGate = Completer<int>();
    await tapVisible(tester, sync);
    expect(
      find.text(en.sensorSyncFailed('Bad state: sync failed')),
      findsNothing,
    );
    env.sensorLink.syncGate!.complete(0);
    await tester.pumpAndSettle();
    expect(find.text(en.sensorSynced(0)), findsOneWidget);
    expect(env.sensorLink.syncCalls, ['n1', 'n1']);
    expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
  });

  testWidgets('item history pending and errors never reuse a valid summary', (
    tester,
  ) async {
    final env = _HistoryEnv();
    addTearDown(env.history.close);
    addTearDown(env.events.close);
    final item = await env.addItem();
    env.itemId = item.id;
    await env.sensorNodes.upsert(testNode(id: 'n1', itemId: item.id));
    env.sensorLink.setStatus(observed());
    await pumpKernelApp(tester, env, location: Routes.item(item.id));
    final empty = find.byKey(const Key('sensor-evidence-empty'));
    final summary = find.byKey(const Key('sensor-summary-mouse_usv'));
    expect(empty, findsNothing);
    expect(find.byKey(const Key('sensor-evidence-loading')), findsOneWidget);
    env.history.addError(StateError('history unavailable'));
    await tester.pumpAndSettle();
    expect(empty, findsNothing);
    expect(find.byKey(const Key('sensor-evidence-error')), findsOneWidget);
    env.history.add([]);
    await tester.pumpAndSettle();
    expect(empty, findsOneWidget);
    await env.sensorEvents.record([testEvent('n1', 1, at: DateTime.now())]);
    await tester.pumpAndSettle();
    expect(summary, findsOneWidget);
    containerOf(tester).invalidate(sensorNotEvaluatedForItemProvider(item.id));
    await tester.pump();
    expect(summary, findsNothing);
    expect(find.byKey(const Key('sensor-evidence-loading')), findsOneWidget);
    env.history.add([]);
    await tester.pumpAndSettle();
    expect(summary, findsOneWidget);
    env.history.addError(StateError('history failed after data'));
    await tester.pumpAndSettle();
    expect(summary, findsNothing);
    expect(find.byKey(const Key('sensor-evidence-error')), findsOneWidget);
    env.history.add([
      SensorNotEvaluatedPeriod(
        nodeId: 'n1',
        from: DateTime.now(),
        health: {SensorHealth.jammed},
      ),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sensor-evidence-not-evaluated')),
      findsOneWidget,
    );
    expect(summary, findsNothing);
  });

  testWidgets(
    'node timeline gates pending and failed events and history but keeps sync',
    (tester) async {
      final env = _HistoryEnv();
      addTearDown(env.history.close);
      addTearDown(env.events.close);
      env.itemId = (await env.addItem()).id;
      await env.sensorNodes.upsert(testNode(id: 'n1'));
      env.sensorLink.setStatus(observed());
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      final empty = find.byKey(const Key('sensor-timeline-empty'));
      final summary = find.byKey(const Key('sensor-timeline-summary'));
      final sync = find.byKey(const Key('sensor-sync'));
      expect(empty, findsNothing);
      expect(find.byKey(const Key('sensor-timeline-loading')), findsOneWidget);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
      env.history.add([]);
      await tester.pumpAndSettle();
      expect(empty, findsNothing);
      env.events.addError(StateError('events unavailable'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sensor-timeline-error')), findsOneWidget);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
      env.events.add([]);
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget);
      final event = testEvent('n1', 1, at: DateTime.now());
      env.events.add([event]);
      await tester.pumpAndSettle();
      expect(summary, findsOneWidget);
      containerOf(tester).invalidate(sensorEventsForNodeProvider('n1'));
      await tester.pump();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-timeline-loading')), findsOneWidget);
      env.events.add([event]);
      await tester.pumpAndSettle();
      env.events.addError(StateError('events failed after data'));
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-timeline-error')), findsOneWidget);
      env.events.add([event]);
      await tester.pumpAndSettle();
      containerOf(tester).invalidate(sensorNotEvaluatedForNodeProvider('n1'));
      await tester.pump();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-timeline-loading')), findsOneWidget);
      env.history.add([]);
      await tester.pumpAndSettle();
      expect(summary, findsOneWidget);
      env.history.addError(StateError('history failed after data'));
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-timeline-error')), findsOneWidget);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
    },
  );

  testWidgets(
    'node timeline suppresses evaluation while current status is unavailable',
    (tester) async {
      final env = _StatusEnv();
      addTearDown(env.statuses.close);
      await env.sensorNodes.upsert(testNode(id: 'n1'));
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      final empty = find.byKey(const Key('sensor-timeline-empty'));
      final summary = find.byKey(const Key('sensor-timeline-summary'));
      final sync = find.byKey(const Key('sensor-sync'));
      expect(empty, findsNothing);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget);
      env.statuses.add(observed(health: {SensorHealth.clipped}));
      await tester.pumpAndSettle();
      expect(empty, findsNothing);
      await env.sensorEvents.record([testEvent('n1', 1, at: DateTime.now())]);
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-event-n1-1')), findsOneWidget);
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(summary, findsOneWidget);
      containerOf(tester).invalidate(sensorStatusProvider('n1'));
      await tester.pump();
      expect(summary, findsNothing);
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      env.statuses.addError(StateError('telemetry lost'));
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
    },
  );

  testWidgets('node timeline keeps historical gaps visible after recovery', (
    tester,
  ) async {
    final env = TestEnv(role: Role.storageFpo);
    await env.sensorNodes.upsert(testNode(id: 'n1'));
    env.sensorLink.setStatus(observed());
    final now = DateTime.now();
    await env.sensorEvents.recordHealth([
      SensorHealthChange(
        nodeId: 'n1',
        at: now.subtract(const Duration(days: 9)),
        health: {SensorHealth.sensorFault},
      ),
      SensorHealthChange(
        nodeId: 'n1',
        at: now.subtract(const Duration(days: 8)),
        health: {SensorHealth.ok},
      ),
    ]);
    await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
    final history = find.byKey(const Key('sensor-timeline-not-evaluated'));
    expect(
      history,
      findsOneWidget,
      reason: 'node timeline covers all stored history',
    );
    expect(find.byKey(const Key('sensor-timeline-empty')), findsNothing);
    expect(find.text(en.sensorHealthOk), findsOneWidget);
    final sync = find.byKey(const Key('sensor-sync'));
    expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
    await env.sensorEvents.record([testEvent('n1', 1, at: now)]);
    await tester.pumpAndSettle();
    expect(history, findsOneWidget);
    expect(find.byKey(const Key('sensor-timeline-summary')), findsNothing);
    expect(
      find.byKey(const Key('sensor-event-n1-1')),
      findsOneWidget,
      reason: 'actual events remain available',
    );
    await tapVisible(tester, sync);
    expect(env.sensorLink.syncCalls, ['n1']);
  });

  testWidgets(
    'item evidence withholds summaries while current evaluation is unavailable',
    (tester) async {
      final env = _StatusEnv();
      addTearDown(env.statuses.close);
      final item = await env.addItem();
      await env.sensorNodes.upsert(testNode(id: 'n1', itemId: item.id));
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      final empty = find.byKey(const Key('sensor-evidence-empty'));
      final summary = find.byKey(const Key('sensor-summary-mouse_usv'));
      expect(empty, findsNothing, reason: 'status has not arrived');
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget);
      env.statuses.add(observed(health: {SensorHealth.jammed}));
      await tester.pumpAndSettle();
      expect(empty, findsNothing);
      await env.sensorEvents.record([testEvent('n1', 1, at: DateTime.now())]);
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(summary, findsOneWidget);
      containerOf(tester).invalidate(sensorStatusProvider('n1'));
      await tester.pump();
      expect(summary, findsNothing, reason: 'refresh with cached healthy data');
      env.statuses.add(observed());
      await tester.pumpAndSettle();
      env.statuses.addError(StateError('status failed'));
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-evidence-open-n1')), findsOneWidget);
      for (final status in [
        observed(health: {}),
        observed(link: SensorLinkState.error),
      ]) {
        env.statuses.add(status);
        await tester.pumpAndSettle();
        expect(summary, findsNothing);
        expect(
          find.byKey(const Key('sensor-not-evaluated-n1')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'item history marks recovered windows not evaluated even with zero events',
    (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      await env.sensorNodes.upsert(testNode(id: 'n1', itemId: item.id));
      await env.sensorNodes.upsert(testNode(id: 'other'));
      env.sensorLink.setStatus(observed());
      final now = DateTime.now();
      await env.sensorEvents.recordHealth([
        SensorHealthChange(
          nodeId: 'n1',
          at: now.subtract(const Duration(days: 9)),
          health: {SensorHealth.jammed},
        ),
        SensorHealthChange(
          nodeId: 'n1',
          at: now.subtract(const Duration(days: 8)),
          health: {SensorHealth.ok},
        ),
        SensorHealthChange(
          nodeId: 'other',
          at: now,
          health: {SensorHealth.sensorFault},
        ),
      ]);
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      final empty = find.byKey(const Key('sensor-evidence-empty'));
      final history = find.byKey(const Key('sensor-evidence-not-evaluated'));
      expect(
        empty,
        findsOneWidget,
        reason: 'only this item and last seven days count',
      );
      expect(history, findsNothing);

      await env.sensorEvents.recordHealth([
        SensorHealthChange(
          nodeId: 'n1',
          at: now.subtract(const Duration(hours: 2)),
          health: {SensorHealth.eventsOverwritten},
        ),
        SensorHealthChange(
          nodeId: 'n1',
          at: now.subtract(const Duration(hours: 1)),
          health: {SensorHealth.ok},
        ),
      ]);
      await tester.pumpAndSettle();
      expect(history, findsOneWidget);
      expect(
        empty,
        findsNothing,
        reason: 'zero events during an affected window is not an evaluation',
      );
      expect(
        find.text(en.sensorHealthOk),
        findsOneWidget,
        reason: 'currently recovered',
      );
      expect(find.text(en.sensorNotEvaluatedTitle), findsOneWidget);
      await env.sensorEvents.record([testEvent('n1', 1, at: now)]);
      await tester.pumpAndSettle();
      expect(history, findsOneWidget);
      expect(find.byKey(const Key('sensor-summary-mouse_usv')), findsNothing);
      expect(find.byKey(const Key('sensor-evidence-open-n1')), findsOneWidget);
    },
  );

  testWidgets(
    'item evidence requires loaded nodes and events, not cached data',
    (tester) async {
      final env = _EvidenceEnv();
      addTearDown(env.nodes.close);
      addTearDown(env.events.close);
      final item = await env.addItem();
      env.itemId = item.id;
      final node = testNode(id: 'n1', itemId: item.id);
      env.sensorLink.setStatus(observed());
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      final empty = find.byKey(const Key('sensor-evidence-empty'));
      final summary = find.byKey(const Key('sensor-summary-mouse_usv'));
      expect(find.byKey(const Key('sensor-evidence-loading')), findsOneWidget);
      expect(empty, findsNothing);
      env.nodes.add([node]);
      await tester.pumpAndSettle();
      expect(empty, findsNothing, reason: 'events still pending');
      env.events.addError(StateError('events unavailable'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sensor-evidence-error')), findsOneWidget);
      expect(empty, findsNothing);

      env.events.add([]);
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget, reason: 'real zero');
      env.events.add([testEvent('n1', 1, at: DateTime.now())]);
      await tester.pumpAndSettle();
      expect(summary, findsOneWidget);
      final container = containerOf(tester);
      container.invalidate(sensorEventsForItemProvider(item.id));
      await tester.pump();
      expect(
        container.read(sensorEventsForItemProvider(item.id)).hasValue,
        isTrue,
      );
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-evidence-loading')), findsOneWidget);
      env.events.addError(StateError('events unavailable after data'));
      await tester.pumpAndSettle();
      expect(summary, findsNothing);
      expect(find.byKey(const Key('sensor-evidence-error')), findsOneWidget);

      env.events.add([]);
      await tester.pumpAndSettle();
      env.nodes.addError(StateError('nodes unavailable after data'));
      await tester.pumpAndSettle();
      expect(empty, findsNothing);
      expect(find.byKey(const Key('sensor-evidence-error')), findsOneWidget);
      env.nodes.add([node]);
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget);
      container.invalidate(sensorNodesProvider);
      await tester.pump();
      expect(empty, findsNothing);
      expect(find.byKey(const Key('sensor-evidence-loading')), findsOneWidget);
    },
  );

  test(
    'recorder persists health history and cancels both subscriptions',
    () async {
      final link = ScriptedSensorLink();
      final repo = InMemorySensorEventRepository(
        InMemorySensorNodeRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          sensorLinkProvider.overrideWithValue(link),
          sensorEventRepositoryProvider.overrideWithValue(repo),
        ],
      );
      expect(container.read(sensorEventRecorderProvider), isTrue);
      final at = DateTime(2026, 10, 11);
      final change = SensorHealthChange(
        nodeId: 'n1',
        at: at,
        health: {SensorHealth.eventsOverwritten},
        seq: 3,
      );
      link.emitEvent(testEvent('n1', 1, at: at));
      link.emitHealth(change);
      await Future<void>.delayed(Duration.zero);
      expect(repo.all, hasLength(1));
      expect(repo.healthLog, [change]);
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      link.emitEvent(testEvent('n1', 2, at: at));
      link.emitHealth(change);
      await Future<void>.delayed(Duration.zero);
      expect(repo.all, hasLength(1));
      expect(repo.healthLog, [change]);
    },
  );

  testWidgets(
    'status chips use full evaluation state and reject stale health',
    (tester) async {
      final env = _StatusEnv();
      addTearDown(env.statuses.close);
      await env.sensorNodes.upsert(testNode(id: 'n1'));
      await pumpKernelApp(tester, env, location: Routes.sensors);
      final notice = find.byKey(const Key('sensor-not-evaluated-n1'));
      expect(find.text(en.loading), findsWidgets);
      expect(find.text(en.sensorHealthOk), findsNothing);

      env.statuses.add(observed());
      await tester.pumpAndSettle();
      expect(find.text(en.sensorHealthOk), findsOneWidget);
      expect(notice, findsNothing);
      containerOf(tester).invalidate(sensorStatusProvider('n1'));
      await tester.pump();
      expect(find.text(en.sensorHealthOk), findsNothing);
      expect(find.text(en.loading), findsWidgets);

      env.statuses.add(observed());
      await tester.pumpAndSettle();
      env.statuses.addError(StateError('status unavailable'));
      await tester.pumpAndSettle();
      expect(find.text(en.sensorHealthOk), findsNothing);
      expect(
        find.text(
          en.errorWithDetail(en.sensorTitle, 'Bad state: status unavailable'),
        ),
        findsOneWidget,
      );

      for (final status in [
        observed(health: {}),
        observed(link: SensorLinkState.error),
        for (final health in notEvaluatedHealth) observed(health: {health}),
      ]) {
        env.statuses.add(status);
        await tester.pumpAndSettle();
        expect(
          notice,
          findsOneWidget,
          reason: '${status.linkState} ${status.health}',
        );
        expect(find.text(en.sensorHealthOk), findsNothing);
      }
    },
  );

  testWidgets('session running requires current connected telemetry', (
    tester,
  ) async {
    final env = _StatusEnv();
    addTearDown(env.statuses.close);
    await env.sensorNodes.upsert(testNode(id: 'n1'));
    await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
    final running = find.byKey(const Key('sensor-session-running'));
    final start = find.byKey(const Key('sensor-session-start'));
    expect(running, findsNothing);
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);

    env.statuses.add(observed(active: true));
    await tester.pumpAndSettle();
    expect(
      running,
      findsOneWidget,
      reason: 'observed session survives app restart',
    );

    final container = containerOf(tester);
    container.invalidate(sensorStatusProvider('n1'));
    await tester.pump();
    final refreshing = container.read(sensorStatusProvider('n1'));
    expect(refreshing.isLoading, isTrue);
    expect(
      refreshing.hasValue,
      isTrue,
      reason: 'exercise cached active telemetry',
    );
    expect(
      running,
      findsNothing,
      reason: 'cached active is not current telemetry',
    );
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);

    env.statuses.add(observed(active: true));
    await tester.pumpAndSettle();
    expect(running, findsOneWidget);
    env.statuses.addError(StateError('telemetry lost'));
    await tester.pumpAndSettle();
    expect(container.read(sensorStatusProvider('n1')).hasValue, isTrue);
    expect(running, findsNothing);
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);

    for (final link in SensorLinkState.values.where(
      (s) => s != SensorLinkState.authenticated,
    )) {
      env.statuses.add(observed(active: true, link: link));
      await tester.pumpAndSettle();
      expect(running, findsNothing, reason: link.name);
      expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    }
    env.statuses.add(observed(active: false));
    await tester.pumpAndSettle();
    expect(running, findsNothing);
  });
}
