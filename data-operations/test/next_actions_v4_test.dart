import 'dart:async';

import 'package:data_operations/src/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late StreamController<Set<String>> attention;

  setUp(() async {
    attention = StreamController<Set<String>>();
    h = await Harness.create(sensorAttention: attention.stream);
  });
  tearDown(() async {
    await h.dispose();
    await attention.close();
  });

  Future<List<NextAction>> actions(Role role) =>
      h.ops.analytics.watchNextActions(role).first;

  List<NextAction> ofKind(List<NextAction> list, NextActionKind kind) => [
    for (final a in list)
      if (a.kind == kind) a,
  ];

  DateTime ago(Duration d) => h.clock.now.subtract(d);

  group('pestSafetyAlert', () {
    test('a dangerous or protected animal without a verified finding is '
        'flagged right after registerFirst, and verifying clears it', () async {
      final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
      final scorpion = await h.addSighting(
        locationId: kitchen.id,
        cardId: 'indian_red_scorpion',
        safety: SafetyLevel.venomous,
      );
      await h.addSighting(locationId: kitchen.id); // caution: no alert

      final list = await actions(Role.household);
      expect([for (final a in list) a.kind].take(2), [
        NextActionKind.registerFirst,
        NextActionKind.pestSafetyAlert,
      ]);
      final alert = ofKind(list, NextActionKind.pestSafetyAlert).single;
      expect(alert.priority, NextActionPriority.pestSafetyAlert);
      expect(alert.priority, 1);
      expect(alert.count, 1);
      expect(alert.locationId, kitchen.id);
      expect(alert.label, 'Kitchen');

      await h.ops.sightings.setVerifiedFinding(
        scorpion.id,
        VerifiedFinding.pestsFound,
      );
      expect(
        ofKind(await actions(Role.household), NextActionKind.pestSafetyAlert),
        isEmpty,
      );
    });

    test('several alerts aggregate; other roles and archived places do not '
        'count', () async {
      final shed = await h.addLocation('Shed', type: LocationType.room);
      final tin = await h.addItem(role: Role.household, label: 'Rice tin');
      await h.addSighting(itemId: tin.id, safety: SafetyLevel.medicalRisk);
      await h.addSighting(safety: SafetyLevel.protectedWildlife);
      await h.addSighting(locationId: shed.id, safety: SafetyLevel.venomous);
      await h.addSighting(role: Role.farmer, safety: SafetyLevel.venomous);

      final alert = ofKind(
        await actions(Role.household),
        NextActionKind.pestSafetyAlert,
      ).single;
      expect(alert.count, 3);
      expect(alert.locationId, isNull);
      expect(alert.itemId, isNull);
      expect(alert.label, isNull);

      await h.ops.locations.archive(shed.id);
      final after = ofKind(
        await actions(Role.household),
        NextActionKind.pestSafetyAlert,
      ).single;
      expect(after.count, 2);
      expect(
        ofKind(
          await actions(Role.farmer),
          NextActionKind.pestSafetyAlert,
        ).single.count,
        1,
      );
    });
  });

  group('pestSightingsRepeated', () {
    test('three validated sightings of one card in one location within 7 '
        'days', () async {
      final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
      final store = await h.addLocation('Store', type: LocationType.room);
      Future<void> seen({
        required String locationId,
        required Duration before,
        String cardId = 'german_cockroach',
        String? userCardId,
        bool validated = true,
      }) => h.addSighting(
        locationId: locationId,
        minutesAgo: before.inMinutes,
        cardId: cardId,
        userCardId: userCardId,
        userValidated: validated,
      );

      await seen(locationId: kitchen.id, before: const Duration(days: 1));
      await seen(locationId: kitchen.id, before: const Duration(days: 3));
      await seen(locationId: store.id, before: const Duration(hours: 2));
      await seen(locationId: kitchen.id, before: const Duration(days: 8));
      await seen(
        locationId: kitchen.id,
        before: const Duration(hours: 1),
        validated: false,
      );
      await seen(
        locationId: kitchen.id,
        before: const Duration(hours: 3),
        cardId: 'house_rat',
      );
      expect(
        ofKind(
          await actions(Role.household),
          NextActionKind.pestSightingsRepeated,
        ),
        isEmpty,
        reason: 'two in the window, one too old, one unvalidated, one other',
      );

      // The user's correction counts as that card.
      await seen(
        locationId: kitchen.id,
        before: const Duration(hours: 4),
        cardId: 'house_rat',
        userCardId: 'german_cockroach',
      );
      final repeated = ofKind(
        await actions(Role.household),
        NextActionKind.pestSightingsRepeated,
      ).single;
      expect(repeated.priority, NextActionPriority.pestSightingsRepeated);
      expect(repeated.count, 3);
      expect(repeated.locationId, kitchen.id);
      expect(repeated.label, 'Kitchen');
      expect(
        ofKind(
          await actions(Role.farmer),
          NextActionKind.pestSightingsRepeated,
        ),
        isEmpty,
      );
    });
  });

  group('sensorActivity', () {
    Future<void> events(int n, {String nodeId = 'node-1', Duration? before}) =>
        h.ops.sensorEvents.record([
          for (var i = 0; i < n; i++)
            sensorEvent(
              nodeId: nodeId,
              seq: i + 1,
              startedAt: ago(before ?? Duration(minutes: 10 + i)),
            ),
        ]);

    test('five matched events in 24 h on a node in a room', () async {
      final pantry = await h.addLocation('Pantry', type: LocationType.room);
      await h.addNode(locationId: pantry.id);
      await events(4);
      await h.ops.sensorEvents.record([
        sensorEvent(
          seq: 50,
          startedAt: ago(const Duration(minutes: 3)),
          signatureId: null,
        ),
        sensorEvent(seq: 51, startedAt: ago(const Duration(hours: 25))),
      ]);
      expect(
        ofKind(await actions(Role.storageFpo), NextActionKind.sensorActivity),
        isEmpty,
        reason: 'four recent matches; unmatched and old events do not count',
      );
      await h.ops.sensorEvents.record([
        sensorEvent(seq: 60, startedAt: ago(const Duration(minutes: 1))),
      ]);
      for (final role in Role.values) {
        final activity = ofKind(
          await actions(role),
          NextActionKind.sensorActivity,
        ).single;
        expect(activity.priority, NextActionPriority.sensorActivity);
        expect(activity.count, 5);
        expect(activity.locationId, pantry.id);
        expect(activity.label, 'Pantry');
      }
    });

    test('a node on a sack counts for the sack owner only; unplaced nodes '
        'never count', () async {
      final sack = await h.addItem(role: Role.storageFpo, label: 'Sack S-9');
      await h.addNode(id: 'loose', address: 'AA:01');
      await events(6, nodeId: 'loose');
      await h.addNode(id: 'on-sack', address: 'AA:02');
      await h.ops.sensorNodes.setPlacement(
        'on-sack',
        SensorPlacement(itemId: sack.id),
      );
      await events(5, nodeId: 'on-sack');

      final fpo = ofKind(
        await actions(Role.storageFpo),
        NextActionKind.sensorActivity,
      ).single;
      expect(fpo.itemId, sack.id);
      expect(fpo.label, 'Sack S-9');
      expect(fpo.count, 5);
      expect(
        ofKind(await actions(Role.household), NextActionKind.sensorActivity),
        isEmpty,
      );
      await h.ops.items.archive(sack.id);
      expect(
        ofKind(await actions(Role.storageFpo), NextActionKind.sensorActivity),
        isEmpty,
      );
    });
  });

  group('sensorNeedsAttention', () {
    test('follows the injected stream of node ids', () async {
      final pantry = await h.addLocation('Pantry', type: LocationType.room);
      await h.addNode(locationId: pantry.id, name: 'Pantry node');
      await h.addNode(id: 'node-2', address: 'AA:02', name: 'Attic node');
      final stream = h.ops.analytics.watchNextActions(Role.household);

      expect(
        ofKind(await stream.first, NextActionKind.sensorNeedsAttention),
        isEmpty,
      );
      attention.add({'node-1', 'ghost'});
      final one = await firstWhere(
        stream,
        (list) => ofKind(list, NextActionKind.sensorNeedsAttention).isNotEmpty,
      );
      final action = ofKind(one, NextActionKind.sensorNeedsAttention).single;
      expect(action.priority, NextActionPriority.sensorNeedsAttention);
      expect(action.count, 1, reason: 'unknown ids are ignored');
      expect(action.label, 'Pantry node');
      expect(action.locationId, pantry.id);

      attention.add({'node-1', 'node-2'});
      final two = await firstWhere(
        stream,
        (list) => ofKind(
          list,
          NextActionKind.sensorNeedsAttention,
        ).any((a) => a.count == 2),
      );
      final both = ofKind(two, NextActionKind.sensorNeedsAttention).single;
      expect(both.label, isNull);
      expect(both.locationId, isNull);

      attention.add(const {});
      await firstWhere(
        stream,
        (list) => ofKind(list, NextActionKind.sensorNeedsAttention).isEmpty,
      );
    });

    test('a node on another role\'s sack is not shown', () async {
      final sack = await h.addItem(role: Role.farmer, label: 'Sack F-1');
      await h.addNode();
      await h.ops.sensorNodes.setPlacement(
        'node-1',
        SensorPlacement(itemId: sack.id),
      );
      attention.add({'node-1'});
      final farmer = await firstWhere(
        h.ops.analytics.watchNextActions(Role.farmer),
        (list) => ofKind(list, NextActionKind.sensorNeedsAttention).isNotEmpty,
      );
      expect(
        ofKind(farmer, NextActionKind.sensorNeedsAttention).single.itemId,
        sack.id,
      );
      expect(
        ofKind(await actions(Role.buyer), NextActionKind.sensorNeedsAttention),
        isEmpty,
      );
    });
  });

  test('new kinds sort by their documented priorities', () async {
    final pantry = await h.addLocation('Pantry', type: LocationType.room);
    await h.addItem(role: Role.household, label: 'Tin', locationId: pantry.id);
    await h.addSighting(safety: SafetyLevel.venomous);
    for (var i = 0; i < 3; i++) {
      await h.addSighting(locationId: pantry.id, minutesAgo: i);
    }
    await h.addNode(locationId: pantry.id);
    await h.ops.sensorEvents.record([
      for (var i = 0; i < 5; i++)
        sensorEvent(
          seq: i,
          startedAt: ago(Duration(minutes: i)),
        ),
    ]);
    attention.add({'node-1'});
    final list = await firstWhere(
      h.ops.analytics.watchNextActions(Role.household),
      (list) => ofKind(list, NextActionKind.sensorNeedsAttention).isNotEmpty,
    );
    final kinds = [for (final a in list) a.kind];
    int at(NextActionKind kind) => kinds.indexOf(kind);
    expect(at(NextActionKind.pestSafetyAlert), 0);
    expect(
      at(NextActionKind.pestSightingsRepeated),
      lessThan(at(NextActionKind.sensorActivity)),
    );
    expect(
      at(NextActionKind.sensorActivity),
      lessThan(at(NextActionKind.reviewDue)),
    );
    expect(
      at(NextActionKind.reviewDue),
      lessThan(at(NextActionKind.sensorNeedsAttention)),
    );
    final priorities = [for (final a in list) a.priority];
    expect(priorities, orderedEquals([...priorities]..sort()));
  });
}
