import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/copy.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

/// Texts that would amount to showing a pest class.
final _classTexts = [
  'Infested',
  'Possible infestation',
  'Uncertain',
  'Clean',
  'No signal detected',
  'Inspection needed',
];

void _expectNoClassShown() {
  for (final text in _classTexts) {
    expect(find.textContaining(text), findsNothing, reason: text);
  }
  expect(find.byKey(const Key('predicted-class')), findsNothing);
}

void main() {
  group('Result screen (F06)', () {
    testWidgets('RETRY shows retry headline, reasons, Retry, provenance', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-004');
      final record = await env.scans.record(
        retryOutcome(
          item.id,
          reasons: const [QualityReason.highNoise, QualityReason.clipping],
        ),
      );
      await pumpKernelApp(
        tester,
        env,
        location: Routes.result(item.id, record.id),
      );

      expect(find.text('Screening result'), findsOneWidget);
      expect(find.text('Recording not usable — try again'), findsOneWidget);
      expect(find.text(QualityReason.highNoise.explanation(en)), findsOneWidget);
      expect(find.text(QualityReason.clipping.explanation(en)), findsOneWidget);
      expect(find.byKey(const Key('retry')), findsOneWidget);
      // Provenance + experimental status always visible.
      expect(find.text('Model: none — Not evaluated'), findsWidgets);
      expect(find.text('Experimental'), findsWidgets);
      _expectNoClassShown();
      // Next actions.
      expect(find.byKey(const Key('record-inspection')), findsOneWidget);
      expect(find.byKey(const Key('scan-another')), findsOneWidget);
      expect(find.byKey(const Key('item-card')), findsOneWidget);
      expect(find.text(en.physicalInspectionNote), findsOneWidget);
    });

    testWidgets('Retry starts a new scan of the same item', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final record = await env.scans.record(retryOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.result(item.id, record.id),
      );
      await tapVisible(tester, find.byKey(const Key('retry')));
      expect(find.text('Guided acoustic scan'), findsOneWidget);
      expect(find.text(positioningTipText), findsOneWidget);
    });

    testWidgets('NOT_EVALUATED shows exact copy and no class', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-005');
      final record = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.result(item.id, record.id),
      );

      expect(
        find.text('Not evaluated — no model installed. Inspect physically.'),
        findsOneWidget,
      );
      expect(find.text('Model: none — Not evaluated'), findsWidgets);
      expect(find.text('Experimental'), findsWidgets);
      expect(find.byKey(const Key('retry')), findsNothing);
      _expectNoClassShown();
      expect(find.byKey(const Key('record-inspection')), findsOneWidget);
      expect(find.byKey(const Key('scan-another')), findsOneWidget);
    });

    test('headline mapping follows design tokens for every state', () {
      expect(
        resultHeadline(
          en,
          quality: ScanQuality.retry,
          classification: Classification.notEvaluated,
          modelVersion: noModelVersion,
        ),
        'Recording not usable — try again',
      );
      expect(
        resultHeadline(
          en,
          quality: ScanQuality.pass,
          classification: Classification.notEvaluated,
          modelVersion: noModelVersion,
        ),
        'Not evaluated — no model installed. Inspect physically.',
      );
      for (final c in [Classification.infested, Classification.uncertain]) {
        expect(
          resultHeadline(
          en,
            quality: ScanQuality.pass,
            classification: c,
            modelVersion: 'v1',
          ),
          'Inspection needed — model result is not verified',
        );
      }
      expect(
        resultHeadline(
          en,
          quality: ScanQuality.pass,
          classification: Classification.clean,
          modelVersion: 'v1',
        ),
        'No signal detected — not a guarantee; inspect before sale/storage '
        'decisions',
      );
      expect(
        provenanceLine(en, modelVersion: noModelVersion, experimental: true),
        'Model: none — Not evaluated',
      );
      expect(
        provenanceLine(en, modelVersion: 'v1', experimental: true),
        'Model v1 — Experimental',
      );
    });
  });

  group('Guided scan (F03)', () {
    testWidgets('mic denied shows explanation; engine never runs', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      env.permissions.microphone = PermissionAccess.denied;
      final item = await env.addItem(label: 'R-1');
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

      expect(find.text(positioningTipText), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('start-capture')));

      expect(find.byKey(const Key('mic-denied')), findsOneWidget);
      expect(find.text('Microphone access is off'), findsOneWidget);
      expect(find.textContaining('never uploaded'), findsOneWidget);
      expect(env.permissions.micRequests, 1);
      expect(env.engine.calls, isEmpty);
      expect(env.scans.scans, isEmpty);

      await tapVisible(tester, find.byKey(const Key('open-settings')));
      expect(env.permissions.settingsOpened, 1);

      // Inventory stays browsable.
      await tapVisible(tester, find.byKey(const Key('browse-inventory')));
      expect(find.text('My Grain'), findsWidgets);
      expect(find.text('R-1'), findsOneWidget);
    });

    testWidgets('permanently denied explains how to re-enable', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.permissions.microphone = PermissionAccess.permanentlyDenied;
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(find.textContaining('blocked for Kernel'), findsOneWidget);
      expect(env.engine.calls, isEmpty);
    });

    testWidgets('granted: captures, persists, then shows NOT_EVALUATED', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-9', grain: 'Paddy');
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

      expect(find.text('Paddy • R-9'), findsOneWidget);
      expect(find.text('Ready to listen'), findsOneWidget);
      expect(find.text('2 s at 16 kHz'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('start-capture')));

      expect(env.engine.calls, hasLength(1));
      expect(env.engine.calls.single.itemId, item.id);
      // Retain-audio opt-in defaults to off.
      expect(env.engine.calls.single.retainAudio, isFalse);
      // Haptics follow the in-app setting (default on); no voice prompts.
      expect(env.engine.calls.single.haptics, isTrue);
      expect(env.voice.spoken, isEmpty);
      expect(env.scans.scans, hasLength(1));
      expect(
        find.text('Not evaluated — no model installed. Inspect physically.'),
        findsOneWidget,
      );
    });

    testWidgets('retain-audio opt-in is passed to the engine', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setRetainAudioOptIn(true);
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(env.engine.calls.single.retainAudio, isTrue);
    });

    testWidgets('a rejected outcome is not shown as a result', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      // Violates the contract: RETRY with a pest class.
      env.engine.next = (id) => ScanOutcome(
        scanId: 'bad',
        itemId: id,
        capturedAt: DateTime.now().toUtc(),
        quality: ScanQuality.retry,
        qualityReasons: const [QualityReason.silence],
        classification: Classification.infested,
        confidence: null,
        experimental: true,
        modelVersion: 'v1',
        latencyMs: 1,
        durationMs: 2000,
        sampleRate: 16000,
        deviceModel: 'd',
        osVersion: 'o',
      );
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tapVisible(tester, find.byKey(const Key('start-capture')));

      expect(env.scans.scans, isEmpty);
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(find.text('Screening result'), findsNothing);
    });

    testWidgets('history lists scans newest first with provenance', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'H-1');
      await env.scans.record(
        retryOutcome(item.id, at: DateTime(2026, 10, 1, 9)),
      );
      await env.scans.record(
        notEvaluatedOutcome(item.id, at: DateTime(2026, 10, 2, 9)),
      );
      await pumpKernelApp(tester, env, location: Routes.item(item.id));

      final history = find.byKey(const Key('scan-history'));
      await tester.ensureVisible(history);
      await tester.pumpAndSettle();
      final chips = tester
          .widgetList<Text>(
            find.descendant(
              of: history,
              matching: find.textContaining('Quality:'),
            ),
          )
          .map((t) => t.data)
          .toList();
      // Newest (pass / not evaluated) first, then the earlier retry.
      expect(chips, ['Quality: Pass', 'Quality: Retry']);
      expect(
        find.descendant(
          of: history,
          matching: find.text('Model: none — Not evaluated'),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: history, matching: find.text('Experimental')),
        findsNWidgets(2),
      );
    });
  });
}

const positioningTipText = 'Press phone against sack, keep still and quiet';
