import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/cards.dart';
import 'support/harness.dart';

void main() {
  test('deleteAllHistory removes sightings with their media and sensor '
      'events, and keeps paired nodes, cards and settings', () async {
    final h = await Harness.create(knowledgeCardsJson: () async => testPack());
    addTearDown(h.dispose);
    await h.ops.settings.setKeepSightingMedia(true);
    await h.ops.settings.setMapsConsent(true);
    final media = File(p.join(h.reportDir.path, 'still.jpg'))
      ..writeAsBytesSync([1, 2]);
    final unrelated = File(p.join(h.reportDir.path, 'other.jpg'))
      ..writeAsBytesSync([3]);
    final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
    await h.addSighting(locationId: kitchen.id, mediaPath: media.path);
    await h.addSighting(locationId: kitchen.id);
    await h.addNode(locationId: kitchen.id);
    await h.ops.sensorEvents.record([
      for (var i = 1; i <= 3; i++) sensorEvent(seq: i, startedAt: h.clock.now),
    ]);
    expect(await h.ops.knowledge.all(), hasLength(4));

    await h.ops.privacy.deleteAllHistory();

    expect(await h.ops.sightings.watchRecent().first, isEmpty);
    expect(media.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    expect(await h.ops.sensorEvents.watchForNode('node-1').first, isEmpty);
    final node = (await h.ops.sensorNodes.get('node-1'))!;
    expect(node.locationId, kitchen.id, reason: 'paired nodes are kept');
    expect(node.keyFingerprint, '0a1b2c3d');
    expect(await h.ops.knowledge.all(), hasLength(4));
    expect(await h.ops.settings.watchKeepSightingMedia().first, isTrue);
    expect(await h.ops.settings.watchMapsConsent().first, isTrue);
    expect(await h.ops.locations.get(kitchen.id), isNotNull);

    // Sync resumes after the wiped events; a replay never restores them.
    expect(await h.ops.sensorEvents.lastSeq('node-1'), 3);
    expect(
      await h.ops.sensorEvents.record([
        for (var i = 1; i <= 4; i++)
          sensorEvent(seq: i, startedAt: h.clock.now),
      ]),
      1,
    );
    final kept = await h.ops.sensorEvents.watchForNode('node-1').first;
    expect([for (final e in kept) e.seq], [4]);
    expect(await h.ops.sensorEvents.lastSeq('node-1'), 4);

    // Running it again is harmless and keeps the higher mark.
    await h.ops.privacy.deleteAllHistory();
    await h.ops.privacy.deleteAllHistory();
    expect(await h.ops.sensorEvents.lastSeq('node-1'), 4);
  });

  test('Pest ID settings default to off on a fresh install and change '
      'independently', () async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    final s = h.ops.settings;
    expect(await s.watchMapsConsent().first, isFalse);
    expect(await s.watchKeepSightingMedia().first, isFalse);

    await s.setMapsConsent(true);
    expect(await firstWhere(s.watchMapsConsent(), (v) => v), isTrue);
    expect(await s.watchKeepSightingMedia().first, isFalse);
    await s.setKeepSightingMedia(true);
    await s.setMapsConsent(false);
    expect(await s.watchMapsConsent().first, isFalse);
    expect(await s.watchKeepSightingMedia().first, isTrue);
    expect(await s.watchRetainAudioOptIn().first, isFalse);
    expect(await s.watchLocalAdviceOptIn().first, isFalse);
  });
}
