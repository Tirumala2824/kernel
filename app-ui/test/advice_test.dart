import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/copy.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

const _proxyInfo = EngineInfo(
  modelPresent: true,
  modelVersion: 'proxy-1',
  experimental: true,
  targetSampleRate: 16000,
  effectiveSampleRate: 16000,
  delegate: InferenceDelegate.cpu,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

Future<(TestEnv, GrainItem, ScanRecord)> _resultEnv({
  Classification result = Classification.uncertain,
}) async {
  final env = TestEnv(role: Role.farmer);
  env.engine.engineInfo = _proxyInfo;
  final item = await env.addItem(label: 'Sack R-004');
  final scan = await env.scans.record(modelOutcome(item.id, result));
  return (env, item, scan);
}

ModelImportProgress _copying(int copied, int? total) => ModelImportProgress(
  phase: ModelImportPhase.copying,
  bytesCopied: copied,
  totalBytes: total,
);

void main() {
  group('Explain this result (on-phone assistant)', () {
    testWidgets('hidden while opted out, even if a model is ready', (
      tester,
    ) async {
      final (env, item, scan) = await _resultEnv();
      env.advice
        ..info = testAdviceModel
        ..status = AdviceStatus.ready;
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));
      expect(find.text(en.headlineInspectionNeeded), findsOneWidget);
      expect(find.byKey(const Key('explain-result')), findsNothing);
      expect(env.advice.explainCalls, isEmpty);
    });

    testWidgets('hidden when opted in but no model is installed', (
      tester,
    ) async {
      final (env, item, scan) = await _resultEnv();
      await env.settings.setLocalAdviceOptIn(true);
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));
      expect(find.byKey(const Key('explain-result')), findsNothing);
    });

    testWidgets('ready: streams a labelled card built from record fields', (
      tester,
    ) async {
      final (env, item, scan) = await _resultEnv();
      await env.addInspection(item.id, VerifiedFinding.inconclusive);
      await env.enableAdvice();
      final controller = StreamController<AdviceText>();
      env.advice.explainController = controller;
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));

      await tapVisible(tester, find.byKey(const Key('explain-result')));
      expect(find.byKey(const Key('advice-shimmer')), findsOneWidget);
      expect(find.text(en.adviceGenerating), findsOneWidget);
      expect(find.byKey(const Key('explain-result')), findsNothing);

      final events = adviceEvents([
        'The model was unsure about this sack.',
        'Open it and look for insects.',
      ]);
      controller.add(events.first);
      await tester.pumpAndSettle();
      expect(find.text(events.first.text), findsOneWidget);
      expect(
        find.text(en.adviceProvenance(testAdviceModelVersion)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('advice-shimmer')), findsOneWidget);

      controller.add(events.last);
      await tester.pumpAndSettle();
      expect(find.text(events.last.text), findsOneWidget);
      expect(find.byKey(const Key('advice-shimmer')), findsNothing);
      expect(find.text(en.adviceNotDecision), findsOneWidget);
      // The model result and the static honesty copy stay on screen.
      expect(find.text(en.headlineInspectionNeeded), findsOneWidget);
      expect(find.text(en.physicalInspectionNote), findsOneWidget);

      final (input, tag) = env.advice.explainCalls.single;
      expect(tag, 'en');
      expect(input.role, Role.farmer);
      expect(input.grainType, 'Wheat');
      expect(input.classification, Classification.uncertain);
      expect(input.confidence, scan.confidence);
      expect(input.quality, ScanQuality.pass);
      expect(input.qualityReasons, isEmpty);
      expect(input.pestModelExperimental, isTrue);
      expect(input.storageDays, daysSince(item.storageDate));
      expect(input.latestVerifiedFinding, VerifiedFinding.inconclusive);
      unawaited(controller.close());
    });

    testWidgets('a stream that ends without complete shows static copy', (
      tester,
    ) async {
      final (env, item, scan) = await _resultEnv();
      await env.enableAdvice();
      env.advice.explainScript = adviceEvents([
        'Partial text',
      ], complete: false);
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));

      await tapVisible(tester, find.byKey(const Key('explain-result')));
      expect(find.byKey(const Key('explain-static')), findsOneWidget);
      expect(find.text(en.adviceStaticInspection), findsOneWidget);
      expect(find.text('Partial text'), findsNothing);
      expect(find.byKey(const Key('advice-provenance')), findsNothing);
    });

    testWidgets('an empty stream (busy, filtered) also falls back', (
      tester,
    ) async {
      final (env, item, scan) = await _resultEnv(
        result: Classification.clean,
      );
      await env.enableAdvice();
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));
      await tapVisible(tester, find.byKey(const Key('explain-result')));
      expect(find.text(en.adviceStaticClean), findsOneWidget);
    });

    testWidgets('passes the active language', (tester) async {
      final (env, item, scan) = await _resultEnv();
      await env.enableAdvice();
      await env.settings.setLanguageTag('hi');
      env.advice.explainScript = adviceEvents(['ठीक'], languageTag: 'hi');
      await pumpKernelApp(tester, env, location: Routes.result(item.id, scan.id));
      await tapVisible(tester, find.byKey(const Key('explain-result')));
      expect(env.advice.explainCalls.single.$2, 'hi');
    });

    testWidgets('never runs during a capture', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'Sack R-9');
      await env.enableAdvice();
      final gate = Completer<void>();
      env.engine.gate = gate;
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tester.tap(find.byKey(const Key('start-capture')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('level-meter')), findsOneWidget);
      expect(find.byKey(const Key('explain-result')), findsNothing);
      expect(env.advice.explainCalls, isEmpty);
      gate.complete();
      await tester.pumpAndSettle();
      // On the result screen it is offered, but only runs when tapped.
      expect(find.byKey(const Key('explain-result')), findsOneWidget);
      expect(env.advice.explainCalls, isEmpty);
    });
  });

  group('Settings: on-phone AI assistant', () {
    testWidgets('opt-in is off by default and explains itself', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      final toggle = find.byKey(const Key('advice-toggle'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(find.text(en.adviceToggleBody), findsOneWidget);
      expect(find.text(en.adviceStatusOff), findsOneWidget);
      expect(find.text(en.adviceHelp), findsOneWidget);
      expect(find.text(en.adviceModelNone), findsWidgets);

      await tapVisible(tester, toggle);
      expect(env.settings.localAdviceWrites, [true]);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(find.text(en.adviceStatusNoModel), findsOneWidget);
    });

    testWidgets('shows status and model details', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.enableAdvice();
      await pumpKernelApp(tester, env, location: Routes.settings);
      expect(find.text(en.adviceStatusReady), findsOneWidget);
      expect(find.text(testAdviceModel.id), findsOneWidget);
      expect(find.text(testAdviceModelVersion), findsOneWidget);
      expect(find.text(en.unitGb('2.6')), findsOneWidget);
      expect(find.text(en.adviceBackendGpu), findsOneWidget);
    });

    testWidgets('import: picker, free-space check, progress, done', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setLocalAdviceOptIn(true);
      env.pickedModelUri = 'content://downloads/gemma.litertlm';
      final controller = StreamController<ModelImportProgress>();
      env.adviceModels
        ..importController = controller
        ..onDone = () => env.advice
          ..info = testAdviceModel
          ..status = AdviceStatus.ready;
      await pumpKernelApp(tester, env, location: Routes.settings);

      await tapVisible(tester, find.byKey(const Key('advice-import')));
      expect(env.pickerCalls, 1);
      expect(env.adviceModels.freeSpaceCalls, 1);
      expect(env.adviceModels.importedUris, [
        'content://downloads/gemma.litertlm',
      ]);

      controller.add(_copying(1300000000, 2600000000));
      await tester.pumpAndSettle();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('advice-import-progress')),
      );
      expect(bar.value, closeTo(0.5, 0.001));
      expect(
        find.text(en.adviceImportCopying(en.unitGb('1.3'), en.unitGb('2.6'))),
        findsOneWidget,
      );

      controller.add(
        const ModelImportProgress(
          phase: ModelImportPhase.verifying,
          bytesCopied: 2600000000,
          totalBytes: 2600000000,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.adviceImportVerifying), findsOneWidget);

      controller.add(
        const ModelImportProgress(
          phase: ModelImportPhase.done,
          bytesCopied: 2600000000,
          totalBytes: 2600000000,
        ),
      );
      unawaited(controller.close());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('advice-import-done')), findsOneWidget);
      expect(find.byKey(const Key('advice-import-progress')), findsNothing);
      expect(find.text(testAdviceModelVersion), findsOneWidget);
      expect(find.text(en.adviceStatusReady), findsOneWidget);
    });

    testWidgets('import failure is shown, nothing else changes', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setLocalAdviceOptIn(true);
      env.pickedModelUri = 'content://x/broken.litertlm';
      env.adviceModels.importScript = [
        _copying(1000, 5000),
        const ModelImportProgress(
          phase: ModelImportPhase.failed,
          bytesCopied: 1000,
          totalBytes: 5000,
          error: 'not a .litertlm file',
        ),
      ];
      await pumpKernelApp(tester, env, location: Routes.settings);
      await tapVisible(tester, find.byKey(const Key('advice-import')));
      expect(find.byKey(const Key('advice-import-error')), findsOneWidget);
      expect(
        find.text(en.adviceImportFailed('not a .litertlm file')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('advice-import-done')), findsNothing);
    });

    testWidgets('import stops when the model does not fit', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setLocalAdviceOptIn(true);
      env.pickedModelUri = 'content://x/gemma.litertlm';
      env.adviceModels
        ..freeSpace = 1000000000
        ..importScript = [_copying(0, 2600000000)];
      await pumpKernelApp(tester, env, location: Routes.settings);
      await tapVisible(tester, find.byKey(const Key('advice-import')));
      expect(
        find.text(en.adviceImportNoSpace(en.unitGb('2.6'), en.unitGb('1.0'))),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the picker imports nothing', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      await tapVisible(tester, find.byKey(const Key('advice-import')));
      expect(env.pickerCalls, 1);
      expect(env.adviceModels.importedUris, isEmpty);
      expect(find.byKey(const Key('advice-import-error')), findsNothing);
    });

    testWidgets('delete asks first, then removes the model', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await env.enableAdvice();
      env.adviceModels.onDelete = () => env.advice
        ..info = null
        ..status = AdviceStatus.noModel;
      await pumpKernelApp(tester, env, location: Routes.settings);

      await tapVisible(tester, find.byKey(const Key('advice-delete')));
      expect(find.text(en.adviceDeleteConfirmTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(env.adviceModels.deleteCalls, 0);

      await tapVisible(tester, find.byKey(const Key('advice-delete')));
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(env.adviceModels.deleteCalls, 1);
      expect(find.byKey(const Key('advice-delete')), findsNothing);
      expect(find.text(en.adviceStatusNoModel), findsOneWidget);
    });
  });
}
