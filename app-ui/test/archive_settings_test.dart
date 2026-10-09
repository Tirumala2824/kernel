import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/app/rules.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  group('Archive', () {
    testWidgets('confirm explains history is kept; cancel does nothing', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-8');
      await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(tester, env, location: Routes.inventory);
      routerOf(tester).push(Routes.item(item.id));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('item-menu')));
      await tapVisible(tester, find.byKey(const Key('archive-item')));
      expect(find.text(en.archiveConfirmTitle('R-8')), findsOneWidget);
      expect(find.text(en.archiveConfirmItemBody), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('confirm-cancel')));
      expect(env.items.items.single.isArchived, isFalse);

      await tapVisible(tester, find.byKey(const Key('item-menu')));
      await tapVisible(tester, find.byKey(const Key('archive-item')));
      await tapVisible(tester, find.byKey(const Key('confirm-ok')));
      expect(env.items.items.single.isArchived, isTrue);
      // History is untouched and still visible on the archived item.
      expect(env.scans.scans, hasLength(1));
      expect(find.byKey(const Key('archived-banner')), findsOneWidget);
      expect(find.byKey(const Key('scan-history')), findsOneWidget);

      // Restore brings it back.
      await tapVisible(tester, find.byKey(const Key('restore-item')));
      expect(env.items.items.single.isArchived, isFalse);
    });

    testWidgets('archived items leave lists', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final a = await env.addItem(label: 'Keep');
      await env.addItem(label: 'Gone');
      await env.items.archive(env.items.items.last.id);
      await pumpKernelApp(tester, env, location: Routes.inventory);
      expect(find.text('Keep'), findsOneWidget);
      expect(find.text('Gone'), findsNothing);
      expect(a.isArchived, isFalse);
    });

    testWidgets('lot archive asks first and keeps its sacks', (tester) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'L-1',
          grainType: 'Rice',
          declaredQuantity: 2,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 1),
        ),
      );
      await env.addItem(role: Role.buyer, label: 'B-1', lotId: lot.id);
      await pumpKernelApp(tester, env, location: Routes.inventory);
      routerOf(tester).push(Routes.lot(lot.id));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('archive-lot')));
      expect(find.text(en.archiveConfirmLotBody), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('confirm-ok')));
      expect(env.lots.lots.single.isArchived, isTrue);
      expect(env.items.items, hasLength(1));
      expect(find.text('L-1 / Rice'), findsNothing);
    });
  });

  group('Language picker', () {
    testWidgets('offers follow-device plus every supported locale', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);

      await tapVisible(tester, find.byKey(const Key('language-tile')));
      expect(find.byKey(const Key('language-sheet')), findsOneWidget);
      expect(find.byKey(const Key('language-device')), findsOneWidget);
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          find.byKey(Key('language-${locale.languageCode}')),
          findsOneWidget,
        );
      }
      expect(find.text('English'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('language-en')));
      expect(env.settings.languageWrites, ['en']);
      expect(find.byKey(const Key('language-sheet')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('language-tile')));
      await tapVisible(tester, find.byKey(const Key('language-device')));
      expect(env.settings.languageWrites, ['en', null]);
    });
  });

  group('Settings toggles', () {
    testWidgets('haptics on, voice off by default; both toggle', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      final haptics = find.byKey(const Key('haptics-toggle'));
      final voice = find.byKey(const Key('voice-toggle'));
      expect(tester.widget<SwitchListTile>(haptics).value, isTrue);
      expect(tester.widget<SwitchListTile>(voice).value, isFalse);

      await tapVisible(tester, voice);
      await tapVisible(tester, haptics);
      expect(env.settings.voicePrompts, isTrue);
      expect(env.settings.haptics, isFalse);
    });
  });

  group('Diagnostics', () {
    testWidgets('shows engine info and a device-log row', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.engine.engineInfo = const EngineInfo(
        modelPresent: true,
        modelVersion: 'proxy-1',
        experimental: true,
        targetSampleRate: 16000,
        effectiveSampleRate: 16000,
        delegate: InferenceDelegate.cpu,
        deviceModel: 'I2501',
        osVersion: 'Android 16 (SDK 36)',
        modelNote: 'Trained on non-grain insect recordings',
        audioSource: 'VOICE_RECOGNITION',
        deviceInputSampleRate: 48000,
      );
      await pumpKernelApp(tester, env, location: Routes.diagnostics);

      expect(find.text('Trained on non-grain insect recordings'), findsOneWidget);
      expect(find.text('VOICE_RECOGNITION'), findsOneWidget);
      expect(find.text('48000 Hz'), findsOneWidget);
      expect(find.text('I2501'), findsOneWidget);
      final row = tester
          .widget<SelectableText>(find.byKey(const Key('device-log-row')))
          .data!;
      expect(row, startsWith('| '));
      expect(row, contains('| 0.1.0+1 | Diagnostics (EngineInfo) |'));
      expect(row, contains('model=proxy-1 (experimental)'));
      expect(row, contains('device input=48000 Hz'));
      expect(row, endsWith(' |'));
      expect(find.byKey(const Key('copy-device-row')), findsOneWidget);
    });

    test('device-log row escapes pipes and fills unknowns', () {
      final row = deviceLogRow(
        date: DateTime(2026, 10, 10),
        build: '0.1.0+1',
        info: const EngineInfo(
          modelPresent: false,
          modelVersion: noModelVersion,
          experimental: true,
          targetSampleRate: 16000,
          effectiveSampleRate: null,
          delegate: InferenceDelegate.none,
          deviceModel: 'a|b',
          osVersion: 'os',
        ),
      );
      expect(row, startsWith('| 2026-10-10 |  | 0.1.0+1 |'));
      expect(row, contains('effective=not measured'));
      expect(row, contains('device=a/b'));
      expect(row.split('|'), hasLength(7));
    });
  });
}
