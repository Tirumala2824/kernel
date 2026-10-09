import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/app/rules.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

String _hint(WidgetTester tester) {
  final hint = find.byKey(const Key('level-hint'));
  return tester
      .widgetList<Text>(find.descendant(of: hint, matching: find.byType(Text)))
      .single
      .data!;
}

/// Stream events arrive in the microtask flush at the end of one pump; the
/// rebuild they trigger is drawn by the next.
Future<void> _deliver(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

double? _progress(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byKey(const Key('capture-progress')))
    .value;

void main() {
  group('Live capture levels', () {
    testWidgets('meter, progress and hints follow the level stream', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-1');
      env.engine.gate = Completer<void>();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

      await tester.tap(find.byKey(const Key('start-capture')));
      await tester.pump();
      await tester.pump();
      expect(env.engine.hasLevelListener, isTrue);
      expect(find.byKey(const Key('level-meter')), findsOneWidget);
      expect(_hint(tester), en.hintWaiting);
      expect(_progress(tester), 0);

      // Quiet: RMS below -65 dBFS.
      for (var i = 1; i <= 6; i++) {
        env.engine.emitLevel(level(i * 50, -78));
      }
      await _deliver(tester);
      expect(_hint(tester), en.hintTooQuiet);
      expect(find.text(en.captureElapsed('0.3', '2.0')), findsOneWidget);
      expect(_progress(tester), closeTo(0.15, 1e-9));

      // Rubbing: a peak above -1 dBFS.
      env.engine.emitLevel(level(600, -30, peak: -0.4));
      await _deliver(tester);
      expect(_hint(tester), en.hintTooLoud);

      // Usable level.
      for (var i = 0; i < 6; i++) {
        env.engine.emitLevel(level(700 + i * 50, -42, peak: -24));
      }
      await _deliver(tester);
      expect(_hint(tester), en.hintHoldStill);
      expect(_progress(tester), closeTo(0.475, 1e-9));

      env.engine.emitLevel(level(2000, -42, peak: -24));
      await _deliver(tester);
      expect(_progress(tester), 1);
      expect(find.text(en.captureChecking), findsOneWidget);

      env.engine.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(en.headlineNotEvaluated), findsOneWidget);
      // The level subscription ends with the capture.
      expect(env.engine.hasLevelListener, isFalse);
    });

    test('hint thresholds: -65 dBFS RMS and -1 dBFS peak', () {
      expect(levelHint(const []), LevelHint.waiting);
      expect(levelHint([level(100, -70)]), LevelHint.tooQuiet);
      expect(levelHint([level(100, -60)]), LevelHint.holdStill);
      expect(levelHint([level(100, -20, peak: -0.5)]), LevelHint.tooLoud);
      // Only the recent window counts.
      expect(
        levelHint([
          level(50, -20, peak: -0.2),
          for (var i = 0; i < 6; i++) level(100 + i * 50, -40, peak: -20),
        ]),
        LevelHint.holdStill,
      );
    });
  });

  group('Voice prompts and haptics', () {
    testWidgets('voice prompts are off by default', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      expect(env.settings.voicePrompts, isFalse);

      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(env.engine.calls, hasLength(1));
      expect(env.voice.spoken, isEmpty);
    });

    testWidgets('when on, prompts are spoken before and after capture', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setVoicePrompts(true);
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

      await tester.tap(find.byKey(const Key('start-capture')));
      await tester.pump();
      // Before capture: both prompts, then a short settle gap.
      expect(env.voice.spoken, [en.voicePlacePhone, en.voiceListening]);
      expect(env.engine.calls, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(env.engine.calls, hasLength(1));
      expect(env.voice.spoken, [
        en.voicePlacePhone,
        en.voiceListening,
        en.voiceDone,
      ]);
    });

    testWidgets('the haptics setting is passed to the engine', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setHaptics(false);
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tapVisible(tester, find.byKey(const Key('start-capture')));
      expect(env.engine.calls.single.haptics, isFalse);
    });
  });
}
