// Saving a sighting: room picker, the optional one-time location with the
// 25 m accuracy gate, keep-media, notes, and discarding buffered media.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/pest_id/pest_platform.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

/// Confirms a box, then opens the save screen.
Future<void> _openSave(WidgetTester tester, PestEnv env) async {
  await pumpKernelApp(tester, env, location: Routes.pestCamera);
  env.sense.candidates.add([testCandidate('c1')]);
  await tester.pumpAndSettle();
  await tapVisible(tester, find.byKey(const Key('pest-box-c1')));
  await tapVisible(tester, find.byKey(const Key('pest-save')));
}

PestEnv _env() {
  final env = PestEnv(role: Role.household);
  env.knowledge.cards = [testCard('test_cockroach')];
  return env;
}

class _PendingSightingRepository extends InMemorySightingRepository {
  final createGate = Completer<void>();
  final attempted = <SightingDraft>[];

  @override
  Future<Sighting> create(SightingDraft draft) async {
    attempted.add(draft);
    await createGate.future;
    return super.create(draft);
  }
}

class _PendingSaveEnv extends PestEnv {
  _PendingSaveEnv() : super(role: Role.household);

  @override
  // ignore: overridden_fields
  final _PendingSightingRepository sightings = _PendingSightingRepository();
}

void main() {
  group('accuracy gate', () {
    test('25 m or better is precise; worse or approximate is not', () {
      expect(classifyFix(12.9, 77.6, 25).isPrecise, isTrue);
      expect(classifyFix(12.9, 77.6, 4.5).isPrecise, isTrue);
      expect(classifyFix(12.9, 77.6, 25.1).isPrecise, isFalse);
      expect(classifyFix(12.9, 77.6, 1800).status, LocationFixStatus.imprecise);
      expect(
        classifyFix(12.9, 77.6, 10, reducedAccuracy: true).status,
        LocationFixStatus.imprecise,
      );
      expect(classifyFix(12.9, 77.6, 0).isPrecise, isFalse);
    });
  });

  testWidgets('saves room, notes and the AI analysis; no location unless '
      'asked; media discarded after saving', (tester) async {
    final env = _env();
    final kitchen = await env.locations.create(
      const LocationDraft(type: LocationType.room, name: 'Kitchen'),
    );
    await _openSave(tester, env);

    expect(env.locator.calls, 0);
    await tester.tap(find.byKey(const Key('pest-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pest-notes')),
      'Behind the stove',
    );
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));

    final draft = env.sightings.drafts.single;
    expect(draft.locationId, kitchen.id);
    expect(draft.notes, 'Behind the stove');
    expect(draft.latitude, isNull);
    expect(draft.analysis?.cardId, 'test_cockroach');
    expect(draft.source, SignalSource.camera);
    expect(draft.mediaPath, isNull);
    expect(env.locator.calls, 0);
    expect(env.sense.discardCalls, greaterThanOrEqualTo(1));
    // Lands on the new sighting.
    expect(find.text(en.pestDetailTitle), findsWidgets);
  });

  testWidgets('location permission denied saves room only', (tester) async {
    final env = _env();
    env.locator.fix = const LocationFix(LocationFixStatus.denied);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(env.locator.calls, 1);
    expect(find.text(en.pestLocationDenied), findsOneWidget);
    expect(find.byKey(const Key('pest-pin')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.sightings.drafts.single.latitude, isNull);
  });

  testWidgets('approximate location is too imprecise: room only', (
    tester,
  ) async {
    final env = _env();
    env.locator.fix = classifyFix(12.97, 77.59, 1500, reducedAccuracy: true);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(find.text(en.pestLocationImprecise), findsOneWidget);
    expect(find.byKey(const Key('pest-pin')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    final draft = env.sightings.drafts.single;
    expect(draft.latitude, isNull);
    expect(draft.longitude, isNull);
    expect(draft.accuracyMeters, isNull);
  });

  testWidgets('precise but 30 m is still too imprecise', (tester) async {
    final env = _env();
    env.locator.fix = classifyFix(12.97, 77.59, 30);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(find.text(en.pestLocationImprecise), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.sightings.drafts.single.latitude, isNull);
  });

  testWidgets('precise location within 25 m shows a pin and is saved', (
    tester,
  ) async {
    final env = _env();
    env.locator.fix = classifyFix(12.97161, 77.59456, 8);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(find.byKey(const Key('pest-pin')), findsOneWidget);
    expect(find.text(en.pestLocationPinned(8)), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    final draft = env.sightings.drafts.single;
    expect(draft.latitude, 12.97161);
    expect(draft.longitude, 77.59456);
    expect(draft.accuracyMeters, 8);
  });

  testWidgets('keep media is off by default; when on the tile is kept', (
    tester,
  ) async {
    final env = _env();
    await _openSave(tester, env);

    final toggle = find.byKey(const Key('pest-keep-media'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tapVisible(tester, toggle);
    expect(env.settings.keepSightingMedia, isTrue);

    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.media.kept.single.$2, 'jpg');
    expect(env.sightings.drafts.single.mediaPath, contains('sighting_media'));
  });

  testWidgets('locate then cancel never claims a pin was saved', (
    tester,
  ) async {
    final env = _env();
    env.locator.fix = classifyFix(12.97161, 77.59456, 8);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(env.locator.calls, 1);
    expect(env.sightings.drafts, isEmpty);
    expect(env.sightings.all, isEmpty);
    expect(find.text('Pin ready to save (within 8 m)'), findsOneWidget);
    expect(find.text('Pin saved (within 8 m)'), findsNothing);
    expect(find.text(en.pestSaved), findsNothing);

    await tapVisible(tester, find.byKey(const Key('pest-save-cancel')));

    expect(env.sightings.drafts, isEmpty);
    expect(env.sightings.all, isEmpty);
    expect(find.text('Pin saved (within 8 m)'), findsNothing);
    expect(find.text(en.pestSaved), findsNothing);
    expect(env.sense.discardCalls, greaterThanOrEqualTo(1));

    await _openSave(tester, env);
    expect(find.byKey(const Key('pest-pin')), findsNothing);
  });

  testWidgets('locate then failed save never claims persistence', (
    tester,
  ) async {
    final env = _PendingSaveEnv();
    env.knowledge.cards = [testCard('test_cockroach')];
    env.locator.fix = classifyFix(12.97161, 77.59456, 8);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    expect(env.sightings.attempted, isEmpty);
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.sightings.attempted.single.latitude, 12.97161);
    expect(env.sightings.all, isEmpty);
    expect(find.text(en.pestSaved), findsNothing);

    env.sightings.createGate.completeError(StateError('test: storage full'));
    await tester.pumpAndSettle();

    expect(find.text(en.pestSaveFailed), findsOneWidget);
    expect(env.sightings.all, isEmpty);
    expect(env.sightings.drafts, isEmpty);
    expect(find.text('Pin ready to save (within 8 m)'), findsOneWidget);
    expect(find.text('Pin saved (within 8 m)'), findsNothing);
    expect(find.text(en.pestSaved), findsNothing);
    expect(find.text(en.pestDetailTitle), findsNothing);
  });

  testWidgets('a located pin stays staged until repository create succeeds', (
    tester,
  ) async {
    final env = _PendingSaveEnv();
    env.knowledge.cards = [testCard('test_cockroach')];
    env.locator.fix = classifyFix(12.97161, 77.59456, 8);
    await _openSave(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-save-location')));
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.sightings.attempted, hasLength(1));
    expect(env.sightings.all, isEmpty);
    expect(find.text('Pin ready to save (within 8 m)'), findsOneWidget);
    expect(find.text('Pin saved (within 8 m)'), findsNothing);
    expect(find.text(en.pestSaved), findsNothing);
    expect(find.text(en.pestDetailTitle), findsNothing);

    env.sightings.createGate.complete();
    await tester.pumpAndSettle();

    expect(env.sightings.all.single.latitude, 12.97161);
    expect(env.sightings.all.single.longitude, 77.59456);
    expect(env.sightings.all.single.accuracyMeters, 8);
    expect(find.text(en.pestSaved), findsOneWidget);
    expect(find.text(en.pestDetailTitle), findsWidgets);
  });

  testWidgets('no rooms yet: a quiet note, saving still works', (tester) async {
    final env = _env();
    await _openSave(tester, env);

    expect(find.byKey(const Key('pest-no-rooms')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    expect(env.sightings.drafts.single.locationId, isNull);
  });
}
