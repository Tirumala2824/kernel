import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/models/model_hub_screen.dart';
import 'package:kernel_app/features/sensors/sensors_screen.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

/// Lazily built list rows only exist once scrolled near.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  Finder? within,
}) async {
  final scrollables = within == null
      ? find.byType(Scrollable)
      : find.descendant(of: within, matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(finder, 300, scrollable: scrollables.first);
  await tester.pumpAndSettle();
}

void main() {
  group('Settings: Pest ID, maps and sensors', () {
    testWidgets('maps consent is off by default and asks before turning on', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      final toggle = find.byKey(const Key('maps-consent-toggle'));
      await scrollTo(tester, toggle);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      await tapVisible(tester, toggle);
      expect(find.text(en.hubMapsConfirmBody), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('confirm-cancel')));
      expect(env.settings.mapsConsent, isFalse);
      expect(env.settings.mapsConsentWrites, isEmpty);

      await tapVisible(tester, toggle);
      await tapVisible(tester, find.byKey(const Key('confirm-ok')));
      expect(env.settings.mapsConsent, isTrue);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

      // Turning it off needs no dialog.
      await tapVisible(tester, toggle);
      expect(find.byKey(const Key('confirm-ok')), findsNothing);
      expect(env.settings.mapsConsentWrites, [true, false]);
    });

    testWidgets('keep sighting media toggles and is off by default', (
      tester,
    ) async {
      final env = TestEnv(role: Role.household);
      await pumpKernelApp(tester, env, location: Routes.settings);
      final toggle = find.byKey(const Key('keep-media-toggle'));
      await scrollTo(tester, toggle);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.text(en.hubKeepMediaToggleBody), findsOneWidget);

      await tapVisible(tester, toggle);
      expect(env.settings.keepSightingMedia, isTrue);
      await tapVisible(tester, toggle);
      expect(env.settings.keepSightingMediaWrites, [true, false]);
    });

    testWidgets('opens the Model Hub and Sensors', (tester) async {
      final env = TestEnv(role: Role.buyer);
      await pumpKernelApp(tester, env, location: Routes.settings);

      await scrollTo(tester, find.byKey(const Key('open-model-hub')));
      await tapVisible(tester, find.byKey(const Key('open-model-hub')));
      expect(find.byType(ModelHubScreen), findsOneWidget);
      routerOf(tester).pop();
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('open-sensors')));
      await tapVisible(tester, find.byKey(const Key('open-sensors')));
      expect(find.byType(SensorsScreen), findsOneWidget);
    });
  });

  group('Phase 4 screens at 200% text', () {
    void largeText(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    final vision = testEntry(
      name: 'Gemma 3n E2B vision and text model',
      capabilities: {ModelCapability.imageIn},
      sizeBytes: 2600000000,
    );
    final embedder = testEntry(
      name: 'EmbeddingGemma 300M',
      capabilities: {ModelCapability.embedText},
      sizeBytes: 300000000,
    );

    Future<TestEnv> busyEnv(String code) async {
      final env = TestEnv(role: Role.storageFpo);
      await env.settings.setLanguageTag(code);
      env.provisioner.catalog = [vision, embedder];
      env.modelCatalog.all = [vision, embedder];
      env.modelRegistry.installed = [
        testInstalled(
          path:
              '/data/user/0/com.kernel.kernel_app/files/models/'
              'embeddinggemma-300m_seq512_mixed-precision.tflite',
          capabilities: {
            ModelCapability.embedText,
            ModelCapability.embedImage,
          },
          catalogEntryId: embedder.id,
        ),
      ];
      return env;
    }

    for (final code in ['en', 'ta', 'ml', 'hi']) {
      final l = lookupAppLocalizations(Locale(code));

      testWidgets('$code: Model Hub with consent, progress and results', (
        tester,
      ) async {
        final env = await busyEnv(code);
        env.modelSearch.hits = [
          ModelSearchHit(score: 0.9, title: embedder.name, entry: embedder),
        ];
        env.knowledge.hits = [KnowledgeHit(card: testCard(), score: 0.7)];
        largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.models);
        expect(tester.takeException(), isNull);
        expect(find.text(l.hubGalleryNote), findsOneWidget);

        await tapVisible(tester, find.byKey(const Key('hub-download')));
        expect(tester.takeException(), isNull);
        final agree = find.byKey(const Key('hub-consent-agree'));
        await scrollTo(
          tester,
          agree,
          within: find.byKey(const Key('hub-consent-sheet')),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l.hubConsentAgree), findsOneWidget);
        await tapVisible(tester, agree);
        env.provisioner.emit(
          ProvisionProgress(
            entryId: vision.id,
            phase: ProvisionPhase.waitingForSpace,
            bytesDone: 0,
            totalBytes: vision.sizeBytes,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final field = find.byKey(const Key('hub-search-field'));
        await scrollTo(tester, field);
        await tester.enterText(field, 'weevil');
        await tapVisible(tester, find.byKey(const Key('hub-search-go')));
        await scrollTo(tester, find.byKey(const Key('hub-search-cards')));
        expect(tester.takeException(), isNull);
        await env.provisioner.finish();
        await tester.pumpAndSettle();
      });

      testWidgets('$code: sensor detail with chips, bands and events', (
        tester,
      ) async {
        final env = TestEnv(role: Role.storageFpo);
        await env.settings.setLanguageTag(code);
        await env.sensorNodes.upsert(
          testNode(id: 'n1', name: 'Warehouse rafters ultrasonic node'),
        );
        env.sensorLink
          ..setStatus(
            SensorStatus(
              nodeId: 'n1',
              linkState: SensorLinkState.authenticated,
              health: const {
                SensorHealth.jammed,
                SensorHealth.clipped,
                SensorHealth.surveyNeeded,
                SensorHealth.lowBattery,
              },
              batteryPercent: 12,
            ),
          )
          ..setBands(
            BandFrame(
              nodeId: 'n1',
              seq: 1,
              at: DateTime(2026, 10, 1),
              frameMs: 250,
              noiseFloorDbfs: -80,
              bandEdgesHz: const [20000, 40000, 60000, 80000],
              bandsDbAboveFloor: const [6, 18, 2],
              peakHz: 41000,
              peakDbfs: -50,
            ),
          );
        final now = DateTime.now();
        await env.sensorEvents.record([
          for (var i = 0; i < 4; i++)
            testEvent(
              'n1',
              i,
              at: now.subtract(Duration(minutes: 40 - i * 3)),
              signatureId: i.isEven ? 'rat_22k' : 'grain_larva',
            ),
        ]);
        largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
        expect(tester.takeException(), isNull);
        expect(find.text(l.sensorHealthJammed), findsOneWidget);
        await scrollTo(tester, find.byKey(const Key('sensor-bands')));
        await scrollTo(tester, find.byKey(const Key('sensor-session')));
        await scrollTo(
          tester,
          find.byKey(const Key('sensor-summary-grain_larva')),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l.sensorEventsSummary(2, 6)), findsNWidgets(2));
        await scrollTo(tester, find.byKey(const Key('sensor-event-n1-0')));
        expect(tester.takeException(), isNull);
      });

      testWidgets('$code: sensors list, item evidence and settings', (
        tester,
      ) async {
        final env = TestEnv(role: Role.farmer);
        await env.settings.setLanguageTag(code);
        final sack = await env.addItem(label: 'A rather long sack label R-004');
        await env.sensorNodes.upsert(
          testNode(id: 'n1', name: 'Probe on sack R-004', itemId: sack.id),
        );
        env.sensorLink.setStatus(
          const SensorStatus(
            nodeId: 'n1',
            linkState: SensorLinkState.disconnected,
            health: {SensorHealth.surveyNeeded},
          ),
        );
        await env.sensorEvents.record([
          testEvent('n1', 1, at: DateTime.now().subtract(const Duration(hours: 2))),
        ]);
        largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.sensors);
        expect(tester.takeException(), isNull);
        routerOf(tester).go(Routes.item(sack.id));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.byKey(const Key('sensor-evidence')));
        expect(tester.takeException(), isNull);
        expect(find.text(l.sensorEvidenceTitle), findsOneWidget);
        routerOf(tester).go(Routes.settings);
        await tester.pumpAndSettle();
        await scrollTo(tester, find.byKey(const Key('maps-consent-toggle')));
        expect(find.text(l.hubMapsToggle), findsOneWidget);
        await scrollTo(tester, find.byKey(const Key('open-sensors')));
        expect(tester.takeException(), isNull);
        routerOf(tester).go(Routes.sensorPlacement('n1'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l.sensorPlaceSave), findsOneWidget);
      });
    }
  });
}
