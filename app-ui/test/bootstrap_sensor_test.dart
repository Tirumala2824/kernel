import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/bootstrap.dart';
import 'package:kernel_app/features/sensors/sensor_providers.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

/// Like BLE, these broadcasts do not replay. Attaching the first status
/// watcher connects the paired node and can immediately deliver observations.
class _ConnectingSensorLink extends ScriptedSensorLink {
  _ConnectingSensorLink(this.initialHealth, {this.initialEvent});

  final List<SensorHealthChange> initialHealth;
  final SensorEvent? initialEvent;
  final watchedNodes = <String>[];
  final statusSubscriptions = <String, int>{};
  var eventSubscriptions = 0;
  var healthSubscriptions = 0;

  @override
  Stream<SensorEvent> events() => Stream.multi((sink) {
    eventSubscriptions++;
    final sub = super.events().listen(sink.add, onError: sink.addError);
    sink.onCancel = () {
      unawaited(sub.cancel());
    };
  });

  @override
  Stream<SensorHealthChange> healthChanges() => Stream.multi((sink) {
    healthSubscriptions++;
    final sub = super.healthChanges().listen(sink.add, onError: sink.addError);
    sink.onCancel = () {
      unawaited(sub.cancel());
    };
  });

  @override
  Stream<SensorStatus> watchStatus(String nodeId) => Stream.multi((sink) {
    statusSubscriptions.update(nodeId, (count) => count + 1, ifAbsent: () => 1);
    if (!watchedNodes.contains(nodeId)) {
      watchedNodes.add(nodeId);
      for (final change in initialHealth.where((c) => c.nodeId == nodeId)) {
        emitHealth(change);
      }
      final event = initialEvent;
      if (event != null && event.nodeId == nodeId) emitEvent(event);
    }
    final sub = super.watchStatus(nodeId).listen(sink.add);
    sink.onCancel = () {
      unawaited(sub.cancel());
    };
  });
}

class _RecordingEventRepository extends InMemorySensorEventRepository {
  _RecordingEventRepository(super.nodes);

  var eventWrites = 0;

  @override
  Future<int> record(List<SensorEvent> events) {
    eventWrites++;
    return super.record(events);
  }
}

class _BootstrapEnv extends TestEnv {
  _BootstrapEnv(this._sensorLink) : super(role: Role.farmer);

  final _ConnectingSensorLink _sensorLink;
  @override
  _ConnectingSensorLink get sensorLink => _sensorLink;
  final attention = StreamController<Set<String>>.broadcast();
  late final List<Override> sensorBindings;

  void bootstrap() {
    sensorBindings = bootstrapSensorOverrides(
      link: sensorLink,
      nodes: sensorNodes,
      events: sensorEvents,
      attention: attention,
    );
  }

  @override
  List<Override> get overrides => [
    for (final override in super.overrides)
      if (override.origin != sensorLinkProvider &&
          override.origin != sensorNodeRepositoryProvider &&
          override.origin != sensorEventRepositoryProvider)
        override,
    ...sensorBindings,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'opening UI recorder consumers does not duplicate bootstrap recording',
    () async {
      final nodes = InMemorySensorNodeRepository();
      final events = _RecordingEventRepository(nodes);
      final link = _ConnectingSensorLink([]);
      final attention = StreamController<Set<String>>.broadcast();
      addTearDown(attention.close);
      final container = ProviderContainer(
        overrides: bootstrapSensorOverrides(
          link: link,
          nodes: nodes,
          events: events,
          attention: attention,
        ),
      );
      addTearDown(container.dispose);
      expect(link.eventSubscriptions, 1);
      expect(link.healthSubscriptions, 1);

      final listener = container.listen(sensorEventRecorderProvider, (_, _) {});
      expect(container.read(sensorEventRecorderProvider), isTrue);
      listener.close();
      container.invalidate(sensorEventRecorderProvider);
      expect(container.read(sensorEventRecorderProvider), isTrue);

      expect(link.eventSubscriptions, 1);
      expect(link.healthSubscriptions, 1);
      final health = SensorHealthChange(
        nodeId: 'n1',
        at: DateTime(2026, 10, 1, 9),
        health: const {SensorHealth.clipped},
      );
      final event = testEvent('n1', 1, at: health.at);
      link.emitHealth(health);
      link.emitEvent(event);
      await Future<void>.delayed(Duration.zero);
      expect(events.healthLog, [health]);
      expect(events.all, [event]);
      expect(events.eventWrites, 1);
    },
  );

  test(
    'attention watches are unique and never synthesize health history',
    () async {
      final nodes = InMemorySensorNodeRepository();
      final events = InMemorySensorEventRepository(nodes);
      final node = testNode(id: 'n1');
      await nodes.upsert(node);
      final link = _ConnectingSensorLink([])
        ..setStatus(
          const SensorStatus(
            nodeId: 'n1',
            linkState: SensorLinkState.authenticated,
            health: {SensorHealth.jammed},
          ),
        );
      final attention = StreamController<Set<String>>.broadcast();
      final needsAttention = <Set<String>>[];
      final sub = attention.stream.listen(needsAttention.add);
      addTearDown(() async {
        await sub.cancel();
        await attention.close();
      });
      bootstrapSensorOverrides(
        link: link,
        nodes: nodes,
        events: events,
        attention: attention,
      );
      await Future<void>.delayed(Duration.zero);
      expect(needsAttention.last, {'n1'});
      expect(
        events.healthLog,
        isEmpty,
        reason: 'Current status is not a timestamped historical observation',
      );
      await nodes.upsert(node);
      await nodes.upsert(testNode(id: 'n2'));
      await Future<void>.delayed(Duration.zero);
      expect(link.statusSubscriptions, {'n1': 1, 'n2': 1});
      expect(link.eventSubscriptions, 1);
      expect(link.healthSubscriptions, 1);

      link.setStatus(
        const SensorStatus(
          nodeId: 'n1',
          linkState: SensorLinkState.authenticated,
          health: {SensorHealth.ok},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(needsAttention.last, isEmpty);
      expect(events.healthLog, isEmpty);
    },
  );

  testWidgets(
    'cold chat launch retains health gaps when item and Sensors open later',
    (tester) async {
      final now = DateTime.now();
      final jam = SensorHealthChange(
        nodeId: 'n1',
        at: now.subtract(const Duration(hours: 2)),
        health: const {SensorHealth.jammed},
      );
      final recovery = SensorHealthChange(
        nodeId: 'n1',
        at: now.subtract(const Duration(hours: 1)),
        health: const {SensorHealth.ok},
      );
      final link = _ConnectingSensorLink([jam, recovery])
        ..setStatus(
          const SensorStatus(
            nodeId: 'n1',
            linkState: SensorLinkState.authenticated,
            health: {SensorHealth.ok},
          ),
        );
      final env = _BootstrapEnv(link);
      addTearDown(env.attention.close);
      final item = await env.addItem();
      await env.sensorNodes.upsert(testNode(id: 'n1', itemId: item.id));
      env.bootstrap();
      await tester.pump();
      expect(env.sensorEvents.healthLog, [jam, recovery]);

      await pumpKernelApp(tester, env, location: Routes.chat);
      expect(routerOf(tester).state.uri.path, Routes.chat);
      expect(link.eventSubscriptions, 1);
      expect(link.healthSubscriptions, 1);
      routerOf(tester).go(Routes.item(item.id));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('sensor-evidence-not-evaluated')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sensor-evidence-empty')), findsNothing);
      expect(env.sensorEvents.all, isEmpty);

      routerOf(tester).go(Routes.sensor('n1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sensor-health-ok-n1')), findsOneWidget);
      expect(
        find.byKey(const Key('sensor-timeline-not-evaluated')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sensor-timeline-empty')), findsNothing);
      expect(find.byKey(const Key('sensor-timeline-summary')), findsNothing);
      expect(env.sensorEvents.healthLog, [jam, recovery]);
      expect(link.eventSubscriptions, 1);
      expect(link.healthSubscriptions, 1);

      // Continued observations still have one app-session recorder after leaving
      // Sensors; neither the event nor health streams depend on mounted screens.
      routerOf(tester).go(Routes.chat);
      await tester.pumpAndSettle();
      final later = SensorHealthChange(
        nodeId: 'n1',
        at: now,
        health: const {SensorHealth.clipped},
      );
      link.emitHealth(later);
      await tester.pump();
      expect(env.sensorEvents.healthLog, [jam, recovery, later]);
    },
  );

  test(
    'bootstrap persists jam and recovery before any sensor UI opens',
    () async {
      final nodes = InMemorySensorNodeRepository();
      final events = InMemorySensorEventRepository(nodes);
      await nodes.upsert(testNode(id: 'n1', itemId: 'sack-a'));
      final jam = SensorHealthChange(
        nodeId: 'n1',
        at: DateTime(2026, 10, 1, 9),
        health: const {SensorHealth.jammed},
      );
      final recovery = SensorHealthChange(
        nodeId: 'n1',
        at: DateTime(2026, 10, 1, 10),
        health: const {SensorHealth.ok},
      );
      final event = testEvent('n1', 7, at: recovery.at);
      final link = _ConnectingSensorLink([jam, recovery], initialEvent: event);
      final attention = StreamController<Set<String>>.broadcast();
      addTearDown(attention.close);

      // This is the same eager sensor wiring invoked by bootstrapOverrides,
      // not the screen's lazy recorder provider. No ProviderContainer/UI yet.
      bootstrapSensorOverrides(
        link: link,
        nodes: nodes,
        events: events,
        attention: attention,
      );
      await Future<void>.delayed(Duration.zero);

      expect(link.watchedNodes, ['n1']);
      expect(events.healthLog, [jam, recovery]);
      expect(events.all, [event]);
      final periods = await events.watchNotEvaluated(itemId: 'sack-a').first;
      expect(periods, hasLength(1));
      expect(periods.single.nodeId, 'n1');
      expect(periods.single.from, jam.at);
      expect(periods.single.until, recovery.at);
      expect(periods.single.health, {SensorHealth.jammed});
      expect(
        await events.lastSeq('n1'),
        isNull,
        reason: 'Live observations never advance the completed-sync watermark',
      );
    },
  );
}
