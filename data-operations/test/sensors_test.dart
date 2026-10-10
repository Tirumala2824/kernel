import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  DateTime ago(Duration d) => h.clock.now.subtract(d);

  SensorNode node({
    String id = 'node-1',
    String address = 'C0:FF:EE:00:00:01',
    String name = 'Kitchen node',
    String fingerprint = '0A1B2C3D',
    int? battery,
    DateTime? lastSeenAt,
    String? locationId,
    int protocolVersion = 1,
  }) => SensorNode(
    id: id,
    deviceAddress: address,
    name: name,
    type: SensorType.usAir,
    protocolVersion: protocolVersion,
    firmwareVersion: '0.1.0',
    keyFingerprint: fingerprint,
    batteryPercent: battery,
    lastSeenAt: lastSeenAt,
    locationId: locationId,
    createdAt: DateTime.utc(2000),
    updatedAt: DateTime.utc(2000),
    syncState: SyncState.synced,
  );

  group('SensorNodeRepository', () {
    test('upsert inserts a node owning its own timestamps, and an update '
        'keeps the placement and unreported values', () async {
      final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
      final created = await h.ops.sensorNodes.upsert(
        node(battery: 80, lastSeenAt: h.clock.now, locationId: kitchen.id),
      );
      expect(created.createdAt, h.clock.now);
      expect(created.syncState, SyncState.localOnly);
      expect(created.keyFingerprint, '0a1b2c3d');
      expect(created.locationId, kitchen.id);
      expect(created.batteryPercent, 80);

      h.clock.advance(const Duration(minutes: 5));
      final updated = await h.ops.sensorNodes.upsert(
        node(name: 'Kitchen node (shelf)', protocolVersion: 2),
      );
      expect(updated.name, 'Kitchen node (shelf)');
      expect(updated.protocolVersion, 2);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt, h.clock.now);
      expect(updated.locationId, kitchen.id, reason: 'placement kept');
      expect(updated.batteryPercent, 80, reason: 'null = not reported');
      expect(updated.lastSeenAt, created.lastSeenAt);
      expect(await h.ops.sensorNodes.watchAll().first, hasLength(1));
    });

    test('upsert validates the node', () async {
      Future<void> rejects(SensorNode n) =>
          expectLater(h.ops.sensorNodes.upsert(n), throwsArgumentError);
      await rejects(node(id: ' '));
      await rejects(node(name: ''));
      await rejects(node(address: ''));
      await rejects(node(fingerprint: '0a1b2c3'));
      await rejects(node(fingerprint: '0a1b2c3d4e5f60718293a4b5c6d7e8f9'));
      await rejects(node(fingerprint: 'zzzzzzzz'));
      await rejects(node(battery: 101));
      await rejects(node(protocolVersion: -1));
      await rejects(node(locationId: 'no-such-location'));
      await h.ops.sensorNodes.upsert(node());
      // The same radio under another id is refused.
      await rejects(node(id: 'node-2'));
      expect(await h.ops.sensorNodes.watchAll().first, hasLength(1));
    });

    test('setPlacement moves a node and validates the target', () async {
      await h.addNode();
      final tin = await h.addItem(role: Role.household, label: 'Rice tin');
      final placed = await h.ops.sensorNodes.setPlacement(
        'node-1',
        SensorPlacement(itemId: tin.id),
      );
      expect(placed.itemId, tin.id);
      expect(placed.locationId, isNull);
      final cleared = await h.ops.sensorNodes.setPlacement(
        'node-1',
        const SensorPlacement(),
      );
      expect(cleared.itemId, isNull);

      await expectLater(
        h.ops.sensorNodes.setPlacement('nope', const SensorPlacement()),
        throwsArgumentError,
      );
      await h.ops.items.archive(tin.id);
      await expectLater(
        h.ops.sensorNodes.setPlacement(
          'node-1',
          SensorPlacement(itemId: tin.id),
        ),
        throwsArgumentError,
      );
    });

    test(
      'watchAll is ordered by name; delete forgets a node and its events',
      () async {
        await h.addNode(id: 'b', address: 'AA:01', name: 'Zeta');
        await h.addNode(id: 'a', address: 'AA:02', name: 'Alpha');
        expect(
          [for (final n in await h.ops.sensorNodes.watchAll().first) n.id],
          ['a', 'b'],
        );
        await h.ops.sensorEvents.record([
          sensorEvent(nodeId: 'a', seq: 1, startedAt: h.clock.now),
          sensorEvent(nodeId: 'b', seq: 1, startedAt: h.clock.now),
        ]);
        await h.ops.sensorNodes.delete('a');
        await h.ops.sensorNodes.delete('unknown');
        expect(await h.ops.sensorNodes.get('a'), isNull);
        expect(await h.ops.sensorEvents.watchForNode('a').first, isEmpty);
        expect(await h.ops.sensorEvents.watchForNode('b').first, hasLength(1));
      },
    );
  });

  group('SensorEventRepository', () {
    test(
      'record is idempotent on (nodeId, seq) and returns the new count',
      () async {
        await h.addNode();
        final t = h.clock.now;
        expect(
          await h.ops.sensorEvents.record([
            sensorEvent(seq: 1, startedAt: t),
            sensorEvent(seq: 2, startedAt: t),
            sensorEvent(seq: 2, startedAt: t), // repeated within the batch
          ]),
          2,
        );
        expect(
          await h.ops.sensorEvents.record([
            sensorEvent(seq: 2, startedAt: t),
            sensorEvent(seq: 3, startedAt: t, signatureId: null),
          ]),
          1,
        );
        expect(await h.ops.sensorEvents.record(const []), 0);
        final stored = await h.ops.sensorEvents.watchForNode('node-1').first;
        expect([for (final e in stored) e.seq], [3, 2, 1]);
        expect(stored.first.match, isNull);
        final matched = stored.last.match!;
        expect(matched.signatureId, 'mouse_usv');
        expect(matched.packVersion, 'sig-pack-test-0.1');
        expect(matched.score, 0.8);
        expect(matched.experimental, isTrue);
        expect(stored.last.peakHz, 70000);
        expect(stored.last.eventClass, SensorEventClass.fmSweep);
      },
    );

    test('record rejects the whole batch for an unknown node or an invalid '
        'event', () async {
      await h.addNode();
      final t = h.clock.now;
      Future<void> rejects(List<SensorEvent> events) =>
          expectLater(h.ops.sensorEvents.record(events), throwsArgumentError);
      await rejects([
        sensorEvent(seq: 1, startedAt: t),
        sensorEvent(nodeId: 'ghost', seq: 1, startedAt: t),
      ]);
      await rejects([sensorEvent(seq: -1, startedAt: t)]);
      await rejects([sensorEvent(seq: 1, startedAt: t, durationMs: -5)]);
      await rejects([sensorEvent(seq: 1, startedAt: t, score: 1.5)]);
      await rejects([sensorEvent(seq: 1, startedAt: t, signatureId: ' ')]);
      expect(await h.ops.sensorEvents.watchForNode('node-1').first, isEmpty);
      expect(await h.ops.sensorEvents.lastSeq('node-1'), isNull);
    });

    test('events keep the placement they were recorded under', () async {
      final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
      final store = await h.addLocation('Store', type: LocationType.room);
      await h.addNode(locationId: kitchen.id);
      await h.ops.sensorEvents.record([
        sensorEvent(seq: 1, startedAt: ago(const Duration(hours: 2))),
      ]);
      await h.ops.sensorNodes.setPlacement(
        'node-1',
        SensorPlacement(locationId: store.id),
      );
      await h.ops.sensorEvents.record([
        sensorEvent(seq: 2, startedAt: ago(const Duration(minutes: 5))),
      ]);
      final inKitchen = await h.ops.sensorEvents
          .watchForLocation(kitchen.id)
          .first;
      final inStore = await h.ops.sensorEvents.watchForLocation(store.id).first;
      expect([for (final e in inKitchen) e.seq], [1]);
      expect([for (final e in inStore) e.seq], [2]);
    });

    test('watchForLocation covers nested locations and items stored there, '
        'and honours the window', () async {
      final house = await h.addLocation('House', type: LocationType.home);
      final pantry = await h.addLocation(
        'Pantry',
        type: LocationType.room,
        parentId: house.id,
      );
      final tin = await h.addItem(
        role: Role.household,
        label: 'Rice tin',
        locationId: pantry.id,
      );
      await h.addNode(id: 'room', address: 'AA:01', locationId: pantry.id);
      await h.addNode(id: 'sack', address: 'AA:02');
      await h.ops.sensorNodes.setPlacement(
        'sack',
        SensorPlacement(itemId: tin.id),
      );
      await h.ops.sensorEvents.record([
        sensorEvent(
          nodeId: 'room',
          seq: 1,
          startedAt: ago(const Duration(hours: 30)),
        ),
        sensorEvent(
          nodeId: 'room',
          seq: 2,
          startedAt: ago(const Duration(hours: 1)),
        ),
        sensorEvent(
          nodeId: 'sack',
          seq: 1,
          startedAt: ago(const Duration(minutes: 10)),
        ),
      ]);
      final all = await h.ops.sensorEvents.watchForLocation(house.id).first;
      expect(
        [for (final e in all) '${e.nodeId}:${e.seq}'],
        ['sack:1', 'room:2', 'room:1'],
      );
      final recent = await h.ops.sensorEvents
          .watchForLocation(house.id, window: const Duration(hours: 24))
          .first;
      expect(
        [for (final e in recent) '${e.nodeId}:${e.seq}'],
        ['sack:1', 'room:2'],
      );
      final onTin = await h.ops.sensorEvents
          .watchForItem(tin.id, window: const Duration(minutes: 5))
          .first;
      expect(onTin, isEmpty);
      final onTinAll = await h.ops.sensorEvents.watchForItem(tin.id).first;
      expect([for (final e in onTinAll) e.nodeId], ['sack']);
    });

    test(
      'watchForNode is newest first with a limit, and streams new events',
      () async {
        await h.addNode();
        await h.ops.sensorEvents.record([
          for (var i = 1; i <= 4; i++)
            sensorEvent(
              seq: i,
              startedAt: ago(Duration(minutes: 10 - i)),
            ),
        ]);
        final stream = h.ops.sensorEvents.watchForNode('node-1', limit: 3);
        expect([for (final e in await stream.first) e.seq], [4, 3, 2]);
        await h.ops.sensorEvents.record([
          sensorEvent(seq: 5, startedAt: h.clock.now),
        ]);
        final next = await firstWhere(stream, (list) => list.first.seq == 5);
        expect([for (final e in next) e.seq], [5, 4, 3]);
        expect(
          () => h.ops.sensorEvents.watchForNode('node-1', limit: 0),
          throwsArgumentError,
        );
      },
    );

    test('lastSeq is the highest stored seq per node', () async {
      await h.addNode();
      await h.addNode(id: 'other', address: 'AA:09');
      expect(await h.ops.sensorEvents.lastSeq('node-1'), isNull);
      expect(await h.ops.sensorEvents.lastSeq('unknown'), isNull);
      await h.ops.sensorEvents.record([
        sensorEvent(seq: 7, startedAt: h.clock.now),
        sensorEvent(seq: 3, startedAt: h.clock.now),
        sensorEvent(nodeId: 'other', seq: 40, startedAt: h.clock.now),
      ]);
      expect(await h.ops.sensorEvents.lastSeq('node-1'), 7);
      expect(await h.ops.sensorEvents.lastSeq('other'), 40);
    });

    test('the database refuses edits to a recorded event', () async {
      await h.addNode();
      await h.ops.sensorEvents.record([
        sensorEvent(seq: 1, startedAt: h.clock.now),
      ]);
      await expectLater(
        h.rawStatement("UPDATE sensor_events SET signature_id = 'rat_22k'"),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
