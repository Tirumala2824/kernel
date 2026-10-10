// The Pest ID and map screens at 200% text, in English and in long-script
// locales, must not overflow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/map/maps_config.dart';
import 'package:kernel_app/features/pest_id/pest_platform.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';
import 'support/test_pest.dart';

/// Long pages at 200% build lazily: scroll the page until [finder] exists.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollTap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tapVisible(tester, finder);
}

void _largeText(WidgetTester tester) {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<PestEnv> _env(String code) async {
  final env = PestEnv(role: Role.household, offline: false);
  await env.settings.setLanguageTag(code);
  env.knowledge.cards = [
    testCard(
      'test_monitor_lizard',
      name: 'A long test name for a protected monitor lizard',
      group: PestGroup.reptile,
      safety: SafetyLevel.protectedWildlife,
      legal: 'Test: protected species, Schedule I.',
    ),
    testCard('test_scorpion', name: 'Test scorpion', safety: SafetyLevel.venomous),
  ];
  return env;
}

void main() {
  for (final code in ['en', 'ta', 'ml']) {
    final l = lookupAppLocalizations(Locale(code));

    group('$code at 200% text', () {
      testWidgets('hub and scan segment', (tester) async {
        final env = await _env(code);
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.scanPest);
        expect(tester.takeException(), isNull);
        expect(find.text(l.pestCameraCardTitle), findsOneWidget);

        routerOf(tester).go(Routes.home);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('camera with boxes, then tiles', (tester) async {
        final env = await _env(code);
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        env.sense.candidates.add([
          testCandidate('a', kind: SignalKind.eyeshine),
          testCandidate(
            'b',
            kind: SignalKind.embeddingMatch,
            hint: 'test_monitor_lizard',
            box: const NormalizedBox(left: 0.8, top: 0.8, width: 0.1, height: 0.1),
          ),
        ]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _scrollTap(tester, find.byKey(const Key('pest-capture')));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('pest-tiles')), findsOneWidget);
      });

      testWidgets('analysis with a protected-wildlife banner and explanation', (
        tester,
      ) async {
        final env = await _env(code);
        env.analyzer
          ..analysis = testAnalysis(
            cardId: 'test_monitor_lizard',
            commonName: 'A long test name for a protected monitor lizard',
            group: PestGroup.reptile,
            safety: SafetyLevel.protectedWildlife,
          )
          ..guideScript = adviceEvents(['A longer explanation sentence.']);
        env.sense.capability = const DistanceCapability(
          arcoreDepth: true,
          focusDistance: false,
        );
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        env.sense.candidates.add([testCandidate('a')]);
        await tester.pumpAndSettle();
        await _scrollTap(tester, find.byKey(const Key('pest-box-a')));
        expect(tester.takeException(), isNull);
        expect(find.text(l.pestSafetyProtectedTitle), findsOneWidget);

        await _scrollTap(tester, find.byKey(const Key('pest-explain')));
        await _scrollTap(tester, find.byKey(const Key('pest-measure')));
        expect(tester.takeException(), isNull);
      });

      testWidgets('analysis unavailable fallback', (tester) async {
        final env = await _env(code);
        env.analyzer.analysis = null;
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        env.sense.candidates.add([
          testCandidate('a', hint: 'test_scorpion'),
        ]);
        await tester.pumpAndSettle();
        await _scrollTap(tester, find.byKey(const Key('pest-box-a')));
        expect(tester.takeException(), isNull);
        expect(find.text(l.pestAnalysisUnavailable), findsOneWidget);
      });

      testWidgets('listen and the sound result', (tester) async {
        final env = await _env(code);
        env.sense
          ..labels['s'] = const [
            ScoredLabel(label: 'Scratching (performance technique)', score: 0.4),
          ]
          ..clips['s'] = testPng;
        env.analyzer.sound = const SoundAnalysis(
          preFilter: [ScoredLabel(label: 'Scratching', score: 0.4)],
          groupHint: PestGroup.rodent,
          modelVersion: 'yamnet-test-1',
          description: 'A test description of a scratching sound.',
        );
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.pestListen);
        expect(tester.takeException(), isNull);

        await _scrollTap(tester, find.byKey(const Key('pest-listen-start')));
        env.sense.sounds.add(
          testCandidate(
            's',
            kind: SignalKind.soundEvent,
            source: SignalSource.microphone,
            box: null,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _scrollTap(tester, find.byKey(const Key('pest-sound-s')));
        expect(tester.takeException(), isNull);
      });

      testWidgets('save sighting with a pin', (tester) async {
        final env = await _env(code);
        await env.locations.create(
          const LocationDraft(type: LocationType.room, name: 'A long room name'),
        );
        env.locator.fix = classifyFix(12.97, 77.59, 12);
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        env.sense.candidates.add([testCandidate('a')]);
        await tester.pumpAndSettle();
        await _scrollTap(tester, find.byKey(const Key('pest-box-a')));
        await _scrollTap(tester, find.byKey(const Key('pest-save')));
        expect(tester.takeException(), isNull);
        await _scrollTap(tester, find.byKey(const Key('pest-save-location')));
        expect(tester.takeException(), isNull);
        await _scrollTap(tester, find.byKey(const Key('pest-save-confirm')));
        expect(tester.takeException(), isNull);
      });

      testWidgets('sightings list and detail', (tester) async {
        final env = await _env(code);
        final s = await env.sightings.add(
          latitude: 12.97,
          longitude: 77.59,
          accuracyMeters: 8,
          userCardId: 'test_scorpion',
        );
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.sightings);
        expect(tester.takeException(), isNull);

        routerOf(tester).go(Routes.sighting(s.id));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _scrollTo(tester, find.text(l.pestDetailVerified));
        expect(find.text(l.pestDetailVerified), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('map: consent, not configured, and with a route', (
        tester,
      ) async {
        final env = await _env(code);
        await env.sightings.add(latitude: 12.97, longitude: 77.59, accuracyMeters: 8);
        env.locator.fix = classifyFix(12.96, 77.58, 10);
        _largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.sightingsMap());
        expect(tester.takeException(), isNull);

        await _scrollTap(tester, find.byKey(const Key('map-consent-open')));
        expect(tester.takeException(), isNull);
        await _scrollTap(tester, find.byKey(const Key('maps-consent-allow')));
        expect(tester.takeException(), isNull);
        expect(find.text(l.mapNotConfigured), findsOneWidget);

        env.mapsConfig.config = const MapsPlatformConfig(
          apiKey: 'test-key-not-real',
          packageName: 'com.kernel.kernel_app',
          certSha1: 'AB',
        );
        ProviderScope.containerOf(
          tester.element(find.byType(KernelApp)),
        ).invalidate(mapsConfigProvider);
        await tester.pumpAndSettle();
        await _scrollTap(tester, find.byKey(const Key('map-route')));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('map-route-summary')), findsOneWidget);
      });
    });
  }
}
