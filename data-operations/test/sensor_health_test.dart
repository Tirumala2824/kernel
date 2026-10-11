import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/harness.dart';

void main() {
  late Harness h;
  Directory? databaseDirectory;
  setUp(() async => h = await Harness.create());
  tearDown(() async {
    await h.dispose();
    await databaseDirectory?.delete(recursive: true);
    databaseDirectory = null;
  });

  SensorHealthChange change(
    int minute,
    Set<SensorHealth> health, {
    String nodeId = 'node-1',
    int? seq,
  }) => SensorHealthChange(
    nodeId: nodeId,
    at: h.clock.now.add(Duration(minutes: minute)),
    health: health,
    seq: seq,
  );

  test(
    'equal health merges idempotently but a late replay can split the run',
    () async {
      await h.addNode();
      final start = h.clock.now;
      final first = change(0, {SensorHealth.jammed, SensorHealth.lowBattery});
      await h.ops.sensorEvents.recordHealth([
        change(10, {SensorHealth.lowBattery, SensorHealth.jammed}),
        first,
        first,
        change(0, {SensorHealth.lowBattery, SensorHealth.jammed}, seq: 44),
      ]);
      await h.ops.sensorEvents.recordHealth([first]);
      var periods = await h.ops.sensorEvents.watchNotEvaluated().first;
      expect(periods, hasLength(1));
      expect(periods.single.from, start);
      expect(periods.single.until, isNull);
      expect(periods.single.health, {SensorHealth.jammed});

      await h.ops.sensorEvents.recordHealth([
        change(5, {SensorHealth.ok}),
      ]);
      periods = await h.ops.sensorEvents.watchNotEvaluated().first;
      expect(periods, hasLength(2));
      expect(periods.first.from, start.add(const Duration(minutes: 10)));
      expect(periods.first.until, isNull);
      expect(periods.last.from, start);
      expect(periods.last.until, start.add(const Duration(minutes: 5)));
    },
  );

  test('health filters use recorded placement and interval overlap', () async {
    final home = await h.addLocation('Home', type: LocationType.home);
    final kitchen = await h.addLocation(
      'Kitchen',
      type: LocationType.room,
      parentId: home.id,
    );
    final store = await h.addLocation('Store', type: LocationType.room);
    final tin = await h.addItem(locationId: store.id);
    await h.addNode(locationId: kitchen.id);
    await h.addNode(id: 'other', address: 'AA:02');
    final first = change(-120, {SensorHealth.jammed});
    await h.ops.sensorEvents.recordHealth([first]);
    await h.ops.sensorNodes.setPlacement(
      'node-1',
      SensorPlacement(itemId: tin.id),
    );
    await h.ops.sensorEvents.recordHealth([
      first, // Replays must not relocate an existing observation.
      change(-80, {SensorHealth.jammed}),
      change(-60, {SensorHealth.ok}),
      change(-20, {SensorHealth.sensorFault}, nodeId: 'other'),
    ]);
    final inKitchen = await h.ops.sensorEvents
        .watchNotEvaluated(
          locationId: home.id,
          window: const Duration(minutes: 100),
        )
        .first;
    expect(inKitchen, hasLength(1));
    expect(inKitchen.single.from, first.at);
    expect(inKitchen.single.until, change(-80, {}).at);
    final inStore = await h.ops.sensorEvents
        .watchNotEvaluated(
          locationId: store.id,
          itemId: tin.id,
          nodeId: 'node-1',
          window: const Duration(minutes: 70),
        )
        .first;
    expect(inStore, hasLength(1));
    expect(inStore.single.from, change(-80, {}).at);
    expect(inStore.single.until, change(-60, {}).at);
    expect(
      await h.ops.sensorEvents
          .watchNotEvaluated(
            nodeId: 'node-1',
            window: const Duration(minutes: 60),
          )
          .first,
      isEmpty,
      reason: 'a closed interval ending at the cutoff is outside',
    );
    expect(
      await h.ops.sensorEvents
          .watchNotEvaluated(nodeId: 'other', itemId: tin.id)
          .first,
      isEmpty,
      reason: 'supplied scope filters intersect',
    );
    expect(
      await h.ops.sensorEvents
          .watchNotEvaluated(
            nodeId: 'other',
            window: const Duration(minutes: 1),
          )
          .first,
      hasLength(1),
      reason: 'an old open interval overlaps the window',
    );
  });

  test(
    'forget deletes only that node health and a re-pair starts unknown',
    () async {
      await h.addNode();
      await h.addNode(id: 'other', address: 'AA:02');
      await h.ops.sensorEvents.recordHealth([
        change(-1, {SensorHealth.jammed}),
        change(-1, {SensorHealth.clipped}, nodeId: 'other'),
      ]);
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, hasLength(2));
      await h.ops.sensorNodes.delete('node-1');
      await h.ops.sensorNodes.delete('node-1');
      expect(
        await h.ops.sensorEvents.watchNotEvaluated(nodeId: 'node-1').first,
        isEmpty,
      );
      expect(
        await h.ops.sensorEvents.watchNotEvaluated(nodeId: 'other').first,
        hasLength(1),
      );
      await h.addNode();
      expect(
        await h.ops.sensorEvents.watchNotEvaluated(nodeId: 'node-1').first,
        isEmpty,
      );
    },
  );

  test(
    'wipe persists removal and rejects old health replay after reopen',
    () async {
      final directory = await Directory(
        Platform.environment['TMPDIR'] ?? Directory.systemTemp.path,
      ).createTemp('kernel_health_privacy_');
      databaseDirectory = directory;
      final file = File(p.join(directory.path, 'health.sqlite'));
      await h.dispose();
      h = await Harness.create(executor: NativeDatabase(file));
      await h.addNode();
      await h.addNode(id: 'never-observed', address: 'AA:02');
      final old = change(-10, {SensorHealth.jammed}, seq: 17);
      await h.ops.sensorEvents.recordHealth([old]);
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, hasLength(1));
      await h.ops.privacy.deleteAllHistory();
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
      await h.dispose();
      h = await Harness.create(executor: NativeDatabase(file));
      expect(await h.ops.sensorNodes.watchAll().first, hasLength(2));
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
      await h.ops.sensorEvents.recordHealth([
        old,
        change(-5, {SensorHealth.clipped}), // Previously unobserved old replay.
        change(-5, {SensorHealth.jammed}, nodeId: 'never-observed'),
        change(0, {SensorHealth.jammed}), // Wipe boundary is inclusive.
      ]);
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
      h.clock.advance(const Duration(minutes: 1));
      await h.ops.sensorEvents.recordHealth([
        change(0, {SensorHealth.clipped}),
      ]);
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, hasLength(1));
      await h.ops.privacy.deleteAllHistory();
      await h.ops.privacy.deleteAllHistory();
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
    },
  );

  test(
    'simultaneous conflicting reports retain every not-evaluated reason',
    () async {
      await h.addNode();
      await h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.jammed}),
        change(-10, {SensorHealth.clipped}),
        change(-10, {SensorHealth.ok}),
        change(-5, {SensorHealth.ok}),
      ]);
      final periods = await h.ops.sensorEvents.watchNotEvaluated().first;
      expect(periods, hasLength(1));
      expect(periods.single.from, change(-10, {}).at);
      expect(periods.single.until, change(-5, {}).at);
      expect(periods.single.health, {
        SensorHealth.jammed,
        SensorHealth.clipped,
      });
    },
  );

  test('invalid health batches fail atomically', () async {
    await h.addNode();
    await expectLater(
      h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.jammed}),
        change(-5, {SensorHealth.clipped}, seq: -1),
      ]),
      throwsArgumentError,
    );
    expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
    await expectLater(
      h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.jammed}),
        change(-5, {SensorHealth.clipped}, nodeId: 'missing'),
      ]),
      throwsArgumentError,
    );
    expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
    await h.ops.sensorEvents.recordHealth([]);
  });

  test(
    'an observed empty health set is unknown, not evidence of recovery',
    () async {
      await h.addNode();
      await h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.jammed}),
        change(-5, {}),
      ]);
      final periods = await h.ops.sensorEvents.watchNotEvaluated().first;
      expect(periods, hasLength(2));
      expect(periods.first.from, change(-5, {}).at);
      expect(periods.first.until, isNull);
      expect(
        periods.first.health,
        isEmpty,
        reason: 'no invented health reason',
      );
      expect(periods.last.until, change(-5, {}).at);
    },
  );

  test(
    'a subscribed health watch updates on observation, recovery and wipe',
    () async {
      await h.addNode();
      final stream = StreamIterator(
        h.ops.sensorEvents.watchNotEvaluated(
          nodeId: 'node-1',
          window: const Duration(hours: 1),
        ),
      );
      addTearDown(stream.cancel);
      Future<void> next() async => expect(
        await stream.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      await next();
      expect(stream.current, isEmpty);
      await h.ops.sensorEvents.recordHealth([
        change(-10, {
          SensorHealth.eventsOverwritten,
          SensorHealth.surveyNeeded,
          SensorHealth.sensorFault,
          SensorHealth.jammed,
          SensorHealth.clipped,
          SensorHealth.lowBattery,
        }),
      ]);
      await next();
      expect(stream.current.single.health, notEvaluatedHealth);
      expect(stream.current.single.until, isNull);
      await h.ops.sensorEvents.recordHealth([
        change(-5, {SensorHealth.lowBattery}),
      ]);
      await next();
      expect(stream.current.single.until, change(-5, {}).at);
      await h.ops.privacy.deleteAllHistory();
      await next();
      expect(stream.current, isEmpty);
    },
  );

  test(
    'simultaneous reports across placements do not invent a zero-length gap',
    () async {
      final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
      final store = await h.addLocation('Store', type: LocationType.room);
      await h.addNode(locationId: kitchen.id);
      await h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.jammed}),
      ]);
      await h.ops.sensorNodes.setPlacement(
        'node-1',
        SensorPlacement(locationId: store.id),
      );
      await h.ops.sensorEvents.recordHealth([
        change(-10, {SensorHealth.clipped}),
      ]);
      final periods = await h.ops.sensorEvents
          .watchNotEvaluated(window: const Duration(minutes: 1))
          .first;
      expect(periods, hasLength(2));
      expect(periods.every((p) => p.until == null), isTrue);
      await h.ops.sensorEvents.recordHealth([
        change(-5, {SensorHealth.ok}),
      ]);
      for (final location in [kitchen, store]) {
        final atLocation = await h.ops.sensorEvents
            .watchNotEvaluated(locationId: location.id)
            .first;
        expect(atLocation.single.until, change(-5, {}).at);
      }
    },
  );

  test(
    'recorded health survives reopen without inventing earlier coverage',
    () async {
      final directory = await Directory(
        Platform.environment['TMPDIR'] ?? Directory.systemTemp.path,
      ).createTemp('kernel_health_');
      databaseDirectory = directory;
      final file = File(p.join(directory.path, 'health.sqlite'));
      await h.dispose();
      h = await Harness.create(executor: NativeDatabase(file));
      await h.addNode();
      expect(await h.ops.sensorEvents.watchNotEvaluated().first, isEmpty);
      final start = h.clock.now.add(const Duration(microseconds: 123));
      final end = start.add(const Duration(minutes: 5));
      await h.ops.sensorEvents.recordHealth([
        SensorHealthChange(
          nodeId: 'node-1',
          at: start,
          health: {SensorHealth.jammed},
          seq: 7,
        ),
        SensorHealthChange(
          nodeId: 'node-1',
          at: end,
          health: {SensorHealth.ok},
          seq: 8,
        ),
      ]);
      await h.dispose();
      h = await Harness.create(executor: NativeDatabase(file));

      final periods = await h.ops.sensorEvents.watchNotEvaluated().first;
      expect(periods, hasLength(1));
      expect(periods.single.nodeId, 'node-1');
      expect(periods.single.from, start);
      expect(periods.single.until, end);
      expect(periods.single.health, {SensorHealth.jammed});
    },
  );
}
