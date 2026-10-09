import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

const _note = 'Experimental — trained on non-grain insect recordings, not validated';

const _proxyInfo = EngineInfo(
  modelPresent: true,
  modelVersion: 'proxy-1',
  experimental: true,
  targetSampleRate: 16000,
  effectiveSampleRate: 16000,
  delegate: InferenceDelegate.cpu,
  deviceModel: 'test-device',
  osVersion: 'test-os',
  modelNote: _note,
);

Future<void> _showResult(
  WidgetTester tester,
  TestEnv env,
  Classification c,
) async {
  final item = await env.addItem(label: 'R-5');
  final scan = await env.scans.record(modelOutcome(item.id, c));
  await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));
}

void _expectNoTreatmentAdvice() {
  for (final word in ['fumigat', 'pesticide', 'treat', 'accept', 'reject']) {
    expect(
      find.textContaining(RegExp(word, caseSensitive: false)),
      findsNothing,
      reason: word,
    );
  }
}

void main() {
  group('Result with a model', () {
    testWidgets('model note is shown prominently with provenance', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      env.engine.engineInfo = _proxyInfo;
      await _showResult(tester, env, Classification.uncertain);

      final note = find.byKey(const Key('model-note'));
      expect(note, findsOneWidget);
      expect(
        find.descendant(of: note, matching: find.text(_note)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: note,
          matching: find.text(en.modelNoteTitleExperimental),
        ),
        findsOneWidget,
      );
      // The note sits right under the headline, above everything else.
      expect(
        tester.getTopLeft(note).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('result-headline'))).dy,
        ),
      );
      expect(
        tester.getTopLeft(note).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('item-card'))).dy),
      );
      expect(find.text(en.provenanceExperimental('proxy-1')), findsWidgets);
      expect(find.text(en.experimentalBadge), findsWidgets);
    });

    testWidgets('infested and uncertain say inspection needed', (
      tester,
    ) async {
      for (final c in [Classification.infested, Classification.uncertain]) {
        final env = TestEnv(role: Role.farmer);
        env.engine.engineInfo = _proxyInfo;
        await _showResult(tester, env, c);
        expect(find.text(en.headlineInspectionNeeded), findsOneWidget);
        expect(find.byKey(const Key('predicted-class')), findsOneWidget);
        expect(find.textContaining('(unverified)'), findsWidgets);
        // Recording an inspection is the primary next action.
        expect(
          find.ancestor(
            of: find.text(en.actionRecordInspection),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );
        _expectNoTreatmentAdvice();
      }
    });

    testWidgets('clean always carries "not a guarantee"', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.engine.engineInfo = _proxyInfo;
      await _showResult(tester, env, Classification.clean);
      expect(find.text(en.headlineClean), findsOneWidget);
      expect(find.textContaining('not a guarantee'), findsOneWidget);
      expect(find.text(en.physicalInspectionNote), findsOneWidget);
      _expectNoTreatmentAdvice();
    });

    testWidgets('a scan from another model version flags the missing note', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      env.engine.engineInfo = _proxyInfo;
      final item = await env.addItem();
      final scan = await env.scans.record(
        modelOutcome(item.id, Classification.uncertain, version: 'proxy-0'),
      );
      await pumpKernelApp(
        tester,
        env,
        location: Routes.result(item.id, scan.id),
      );
      expect(find.byKey(const Key('model-note')), findsNothing);
      expect(find.text(en.modelNoteOtherVersion('proxy-0')), findsOneWidget);
    });

    testWidgets('no model: no note, honest NOT_EVALUATED', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.result(item.id, scan.id),
      );
      expect(find.byKey(const Key('model-note')), findsNothing);
      expect(find.text(en.headlineNotEvaluated), findsOneWidget);
      expect(find.text(en.provenanceNone), findsWidgets);
    });

    testWidgets('guided scan shows the model note too', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.engine.engineInfo = _proxyInfo;
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      expect(find.byKey(const Key('scan-model-note')), findsOneWidget);
    });

    testWidgets('the result reveal animates in when motion is allowed', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      // Motion on: the home hero's rings loop, so pump in fixed steps
      // instead of settling.
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(overrides: env.overrides, child: const KernelApp()),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      routerOf(tester).go(Routes.result(item.id, scan.id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final headline = find.byKey(const Key('result-headline'));
      final early = tester
          .widget<Opacity>(
            find.ancestor(of: headline, matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(early, lessThan(1));
      await tester.pump(const Duration(seconds: 1));
      final late = tester
          .widget<Opacity>(
            find.ancestor(of: headline, matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(late, 1);
    });
  });
}
