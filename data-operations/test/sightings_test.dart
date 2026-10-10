import 'dart:io';

import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  Future<List<Sighting>> recent({Role? role, String? locationId}) =>
      h.ops.sightings.watchRecent(role: role, locationId: locationId).first;

  test('create stores the AI analysis, the user validation and no verified '
      'finding, with tracking columns', () async {
    final kitchen = await h.addLocation('Kitchen', type: LocationType.room);
    final sighting = await h.addSighting(
      locationId: kitchen.id,
      userCardId: '  house_rat ',
      notes: '  by the sink ',
      sound: const SoundAnalysis(
        preFilter: [ScoredLabel(label: 'Rodent squeak', score: 0.41)],
        groupHint: PestGroup.rodent,
        modelVersion: 'yamnet-test',
        description: 'High squeaks',
      ),
      distance: const DistanceEstimate(
        method: DistanceMethod.arcoreDepth,
        meters: 1.25,
        lowMeters: 1.1,
        highMeters: 1.4,
        confidence: 0.7,
      ),
      latitude: 12.97,
      longitude: 77.59,
      accuracyMeters: 8,
    );
    expect(sighting.id, isUuid);
    expect(sighting.syncState, SyncState.localOnly);
    expect(sighting.createdAt, h.clock.now);
    expect(sighting.verifiedFinding, isNull);
    expect(sighting.userValidated, isTrue);
    expect(sighting.userCardId, 'house_rat');
    expect(sighting.notes, 'by the sink');

    final stored = (await h.ops.sightings.get(sighting.id))!;
    final a = stored.analysis!;
    expect(a.cardId, 'german_cockroach');
    expect(a.aiConfidence, 0.7);
    expect(a.agreement, 0.6);
    expect(a.samples, 5);
    expect(a.taxonomyPath, ['Insect', 'Cockroach', 'German cockroach']);
    expect(a.safety, SafetyLevel.caution);
    expect(a.modelVersion, 'gemma-test-e2b');
    expect(a.promptVersion, 'pest-prompt-test-1');
    expect(a.experimental, isTrue);
    expect(a.createdAt, DateTime.utc(2026, 10, 1, 7, 59));
    expect(stored.sound!.preFilter.single.label, 'Rodent squeak');
    expect(stored.sound!.preFilter.single.score, 0.41);
    expect(stored.sound!.groupHint, PestGroup.rodent);
    expect(stored.sound!.description, 'High squeaks');
    expect(stored.distance!.method, DistanceMethod.arcoreDepth);
    expect(stored.distance!.meters, 1.25);
    expect(stored.distance!.isAvailable, isTrue);
    expect(stored.latitude, 12.97);
    expect(stored.accuracyMeters, 8);
    // AI label and the user's correction are separate fields.
    expect(stored.userCardId, isNot(a.cardId));
  });

  test('create rejects invalid drafts', () async {
    final archived = await h.addLocation('Old shed');
    await h.ops.locations.archive(archived.id);
    final item = await h.addItem();
    await h.ops.items.archive(item.id);

    Future<void> rejects(SightingDraft draft) =>
        expectLater(h.ops.sightings.create(draft), throwsArgumentError);
    SightingDraft draft({
      String? locationId,
      String? itemId,
      PestAnalysis? analysis,
      SignalSource source = SignalSource.camera,
      DistanceEstimate? distance,
      double? latitude,
      double? longitude,
      double? accuracyMeters,
      String? mediaPath,
      SoundAnalysis? sound,
    }) => SightingDraft(
      role: Role.household,
      source: source,
      observedAt: h.clock.now,
      userValidated: true,
      locationId: locationId,
      itemId: itemId,
      analysis: analysis,
      distance: distance,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      mediaPath: mediaPath,
      sound: sound,
    );

    await rejects(draft(locationId: 'no-such-location'));
    await rejects(draft(locationId: archived.id));
    await rejects(draft(itemId: 'no-such-item'));
    await rejects(draft(itemId: item.id));
    await rejects(draft(latitude: 12.9));
    await rejects(draft(latitude: 12.9, longitude: 77.5));
    await rejects(draft(accuracyMeters: 5));
    await rejects(draft(latitude: 91, longitude: 0, accuracyMeters: 5));
    await rejects(draft(analysis: pestAnalysis(aiConfidence: 1.2)));
    await rejects(draft(analysis: pestAnalysis(agreement: -0.1)));
    await rejects(draft(analysis: pestAnalysis(samples: 0)));
    await rejects(draft(analysis: pestAnalysis(cardId: ' ')));
    await rejects(draft(analysis: pestAnalysis(experimental: false)));
    await rejects(
      draft(
        source: SignalSource.microphone,
        analysis: pestAnalysis(source: SignalSource.camera),
      ),
    );
    await rejects(
      draft(
        distance: const DistanceEstimate(
          method: DistanceMethod.unavailable,
          meters: 2,
          unavailableReason: 'low_texture',
        ),
      ),
    );
    await rejects(
      draft(
        distance: const DistanceEstimate(
          method: DistanceMethod.focusDistance,
          meters: -1,
        ),
      ),
    );
    await rejects(
      draft(
        sound: const SoundAnalysis(
          preFilter: [ScoredLabel(label: 'x', score: double.nan)],
          groupHint: PestGroup.unknown,
          modelVersion: 'yamnet-test',
        ),
      ),
    );
    await rejects(draft(mediaPath: 'relative/clip.wav'));
    expect(await recent(), isEmpty);
  });

  test('a media path needs the keep-sighting-media setting', () async {
    final path = p.join(h.reportDir.path, 'still.jpg');
    await expectLater(
      h.addSighting(mediaPath: path),
      throwsA(isA<StateError>()),
    );
    await h.ops.settings.setKeepSightingMedia(true);
    final sighting = await h.addSighting(mediaPath: path);
    expect(sighting.mediaPath, path);
  });

  test('watchRecent is newest first, filters by role and nested location, '
      'and honours the limit', () async {
    final house = await h.addLocation('House', type: LocationType.home);
    final kitchen = await h.addLocation(
      'Kitchen',
      type: LocationType.room,
      parentId: house.id,
    );
    final yard = await h.addLocation('Yard', type: LocationType.home);
    final tin = await h.addItem(
      role: Role.household,
      label: 'Rice tin',
      locationId: kitchen.id,
    );
    final old = await h.addSighting(minutesAgo: 60, locationId: kitchen.id);
    final mid = await h.addSighting(minutesAgo: 30, itemId: tin.id);
    final newest = await h.addSighting(minutesAgo: 1, locationId: yard.id);
    final farmer = await h.addSighting(role: Role.farmer, minutesAgo: 5);

    expect(
      [for (final s in await recent()) s.id],
      [newest.id, farmer.id, mid.id, old.id],
    );
    expect(
      [for (final s in await recent(role: Role.household)) s.id],
      [newest.id, mid.id, old.id],
    );
    // House covers the kitchen, and the tin stored in the kitchen.
    expect(
      [for (final s in await recent(locationId: house.id)) s.id],
      [mid.id, old.id],
    );
    final limited = await h.ops.sightings.watchRecent(limit: 2).first;
    expect([for (final s in limited) s.id], [newest.id, farmer.id]);
    expect(() => h.ops.sightings.watchRecent(limit: 0), throwsArgumentError);
  });

  test('archived locations and items are excluded from watchRecent, but '
      'item history keeps them', () async {
    final shed = await h.addLocation('Shed', type: LocationType.room);
    final tin = await h.addItem(role: Role.household, label: 'Dal tin');
    final inShed = await h.addSighting(locationId: shed.id, itemId: tin.id);
    final loose = await h.addSighting(minutesAgo: 3);

    final stream = h.ops.sightings.watchRecent();
    expect((await stream.first).length, 2);
    await h.ops.locations.archive(shed.id);
    final after = await firstWhere(stream, (list) => list.length == 1);
    expect(after.single.id, loose.id);

    final history = await h.ops.sightings.watchForItem(tin.id).first;
    expect([for (final s in history) s.id], [inShed.id]);
  });

  test('watchForItem is newest first and streams new sightings', () async {
    final tin = await h.addItem(role: Role.household, label: 'Atta tin');
    final first = await h.addSighting(itemId: tin.id, minutesAgo: 10);
    final stream = h.ops.sightings.watchForItem(tin.id);
    expect([for (final s in await stream.first) s.id], [first.id]);
    final second = await h.addSighting(itemId: tin.id, minutesAgo: 2);
    final both = await firstWhere(stream, (list) => list.length == 2);
    expect([for (final s in both) s.id], [second.id, first.id]);
  });

  test('setVerifiedFinding sets the finding once and never overwrites it, '
      'leaving the AI analysis untouched', () async {
    final sighting = await h.addSighting();
    h.clock.advance(const Duration(hours: 1));
    final verified = await h.ops.sightings.setVerifiedFinding(
      sighting.id,
      VerifiedFinding.pestsFound,
    );
    expect(verified.verifiedFinding, VerifiedFinding.pestsFound);
    expect(verified.updatedAt, h.clock.now);
    expect(verified.analysis!.cardId, sighting.analysis!.cardId);
    expect(verified.analysis!.aiConfidence, sighting.analysis!.aiConfidence);

    await expectLater(
      h.ops.sightings.setVerifiedFinding(
        sighting.id,
        VerifiedFinding.noneFound,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      h.ops.sightings.setVerifiedFinding(
        sighting.id,
        VerifiedFinding.pestsFound,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await h.ops.sightings.get(sighting.id))!.verifiedFinding,
      VerifiedFinding.pestsFound,
    );
    await expectLater(
      h.ops.sightings.setVerifiedFinding('nope', VerifiedFinding.noneFound),
      throwsArgumentError,
    );
  });

  test('delete removes the sighting and its kept media file, and is a no-op '
      'for unknown ids', () async {
    await h.ops.settings.setKeepSightingMedia(true);
    final file = File(p.join(h.reportDir.path, 'clip.wav'));
    await file.writeAsBytes([1, 2, 3]);
    final withMedia = await h.addSighting(mediaPath: file.path);
    final gone = File(p.join(h.reportDir.path, 'missing.jpg'));
    final missingMedia = await h.addSighting(mediaPath: gone.path);
    final keep = await h.addSighting();

    await h.ops.sightings.delete(withMedia.id);
    expect(file.existsSync(), isFalse);
    expect(await h.ops.sightings.get(withMedia.id), isNull);
    await h.ops.sightings.delete(missingMedia.id);
    await h.ops.sightings.delete('no-such-sighting');
    expect([for (final s in await recent()) s.id], [keep.id]);
  });

  test('the database refuses edits to a stored AI analysis', () async {
    final sighting = await h.addSighting();
    // Only reachable below the repository; the trigger is the backstop.
    await expectLater(
      h.rawStatement(
        "UPDATE sightings SET analysis = NULL WHERE id = '${sighting.id}'",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      h.rawStatement(
        "UPDATE sightings SET user_validated = 0, "
        "verified_finding = 'noneFound' WHERE id = '${sighting.id}'",
      ),
      completes,
    );
    await expectLater(
      h.rawStatement(
        "UPDATE sightings SET verified_finding = 'pestsFound' "
        "WHERE id = '${sighting.id}'",
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}
