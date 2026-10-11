import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/media_picker_service.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

class _WavPicker extends MediaPickerService {
  PickedMedia? media;
  Object? error;
  final requests = <SensorType>[];
  final released = <PickedMedia>[];
  Completer<PickedMedia?>? pickerGate;

  @override
  Future<void> release(PickedMedia? media) async {
    if (media != null) released.add(media);
  }

  @override
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) async {
    requests.add(sensorType);
    if (error case final failure?) throw failure;
    return pickerGate == null ? media : await pickerGate!.future;
  }
}

class _FileEngine extends ScriptedScanEngine {
  final fileCalls =
      <({String itemId, String path, SensorType sensor, bool retainAudio})>[];
  ScanOutcome? returned;
  Completer<void>? fileGate;
  Object? error;

  @override
  Future<ScanOutcome> analyzeAudioFile(
    String itemId,
    String filePath, {
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
    bool retainAudio = false,
  }) async {
    fileCalls.add((
      itemId: itemId,
      path: filePath,
      sensor: sensorType,
      retainAudio: retainAudio,
    ));
    await fileGate?.future;
    if (error case final failure?) throw failure;
    return returned = next(itemId);
  }
}

class _CaptureEnv extends TestEnv {
  _CaptureEnv() : super(role: Role.farmer);

  final _fileEngine = _FileEngine();

  @override
  _FileEngine get engine => _fileEngine;

  final picker = _WavPicker();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    mediaPickerServiceProvider.overrideWithValue(picker),
  ];
}

class _PendingScans extends InMemoryScanRepository {
  _PendingScans(super.items);

  final gate = Completer<void>();
  final writes = <ScanOutcome>[];

  @override
  Future<ScanRecord> record(ScanOutcome outcome) async {
    writes.add(outcome);
    await gate.future;
    return super.record(outcome);
  }
}

class _PendingCaptureEnv extends _CaptureEnv {
  late final pendingScans = _PendingScans(items);

  @override
  _PendingScans get scans => pendingScans;
}

PickedMedia _wav() => PickedMedia(
  path: '/local/grain.wav',
  fileName: 'grain.wav',
  bytes: Uint8List(0),
  mediaType: 'audio',
  // A transport hint is not calibrated sensor provenance.
  sensorType: SensorType.contactPiezo,
);

void main() {
  testWidgets('owned WAV is released after successful or failed analysis', (tester) async {
    for (final fails in [false, true]) {
      final env = _CaptureEnv();
      final item = await env.addItem();
      env.picker.media = _wav();
      if (fails) env.engine.error = StateError('test decoder failure');
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tapVisible(tester, find.byKey(const Key('upload-audio-file')));
      expect(env.picker.released, [same(env.picker.media)], reason: 'fails=$fails');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('late WAV picker result is released after capture screen disposal', (tester) async {
    final env = _CaptureEnv();
    final item = await env.addItem();
    final media = _wav();
    env.picker.pickerGate = Completer<PickedMedia?>();
    await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
    await tester.tap(find.byKey(const Key('upload-audio-file')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    env.picker.pickerGate!.complete(media);
    await tester.pumpAndSettle();
    expect(env.picker.released, [same(media)]);
    expect(env.engine.fileCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'WAV analysis stays indeterminate until the engine returns, then saves',
    (tester) async {
      final env = _PendingCaptureEnv();
      final item = await env.addItem();
      env.picker.media = _wav();
      env.engine.fileGate = Completer<void>();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tester.tap(find.byKey(const Key('upload-audio-file')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(env.engine.fileCalls, hasLength(1));
      expect(env.pendingScans.writes, isEmpty);
      expect(find.text(en.captureSaving), findsNothing);
      expect(find.text(en.captureChecking), findsOneWidget);
      expect(find.byKey(const Key('capture-progress')), findsNothing);
      expect(find.byKey(const Key('level-meter')), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('file-analysis-progress')),
            )
            .value,
        isNull,
      );
      env.engine.fileGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(env.pendingScans.writes, hasLength(1));
      expect(env.pendingScans.scans, isEmpty);
      expect(find.text(en.captureSaving), findsOneWidget);
      expect(find.byKey(const Key('file-analysis-progress')), findsNothing);
      expect(find.byKey(const Key('capture-progress')), findsNothing);
      expect(find.byKey(const Key('level-meter')), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('scan-saving-progress')),
            )
            .value,
        isNull,
      );
      env.pendingScans.gate.complete();
      await tester.pumpAndSettle();
      expect(env.pendingScans.scans, hasLength(1));
      expect(
        routerOf(tester).state.uri.path,
        Routes.result(item.id, env.pendingScans.scans.single.id),
      );
    },
  );

  testWidgets(
    'WAV persistence failure is not an analysis failure or a saved result',
    (tester) async {
      final env = _PendingCaptureEnv();
      final item = await env.addItem();
      env.picker.media = _wav();
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      await tester.tap(find.byKey(const Key('upload-audio-file')));
      await tester.pump();
      await tester.pump();
      expect(env.pendingScans.writes, hasLength(1));
      expect(find.text(en.captureSaving), findsOneWidget);
      env.pendingScans.gate.completeError(StateError('storage failed'));
      await tester.pumpAndSettle();
      expect(
        find.text(en.scanCouldNotSave('Bad state: storage failed')),
        findsOneWidget,
      );
      expect(env.pendingScans.scans, isEmpty);
      expect(routerOf(tester).state.uri.path, Routes.scanItem(item.id));
      expect(find.byKey(const Key('start-capture')), findsOneWidget);
    },
  );

  testWidgets(
    'WAV import goes straight to ordinary audio without calibration',
    (tester) async {
      final env = _CaptureEnv();
      final item = await env.addItem();
      env.picker.media = _wav();
      env.permissions.microphone = PermissionAccess.denied;
      await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
      expect(find.textContaining('Sensor Tag'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

      expect(find.text('Select Audio Sensor Transducer'), findsNothing);
      expect(find.textContaining('calibrated screening'), findsNothing);
      expect(env.picker.requests, [SensorType.audioAir]);
      expect(env.engine.fileCalls, [
        (
          itemId: item.id,
          path: '/local/grain.wav',
          sensor: SensorType.audioAir,
          retainAudio: false,
        ),
      ]);
      expect(env.permissions.micRequests, 0);
      expect(env.engine.calls, isEmpty);
      final saved = env.scans.scans.single;
      final outcome = env.engine.returned!;
      expect(saved.id, outcome.scanId);
      expect(saved.result, Classification.notEvaluated);
      expect(saved.confidence, isNull);
      expect(saved.modelVersion, noModelVersion);
      expect(saved.experimental, isTrue);
      expect(saved.durationMs, outcome.durationMs);
      expect(saved.sampleRate, outcome.sampleRate);
      expect(find.text(en.headlineNotEvaluated), findsOneWidget);
    },
  );

  testWidgets('cancelling WAV selection does not analyze or save', (
    tester,
  ) async {
    final env = _CaptureEnv();
    final item = await env.addItem();
    await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

    expect(find.text('Import Grain Audio (.wav)'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

    expect(env.picker.requests, [SensorType.audioAir]);
    expect(env.engine.fileCalls, isEmpty);
    expect(env.scans.scans, isEmpty);
    expect(find.text(en.captureReady), findsOneWidget);
  });

  for (final research in [false, true]) {
    testWidgets('WAV retention follows explicit opt-in (research=$research)', (
      tester,
    ) async {
      final env = _CaptureEnv();
      final item = await env.addItem();
      env.picker.media = _wav();
      if (research) {
        await env.settings.setResearchModeOptIn(true);
      } else {
        await env.settings.setRetainAudioOptIn(true);
      }
      env.engine.next = (id) => notEvaluatedOutcome(id, retained: true);
      await pumpKernelApp(
        tester,
        env,
        location: research
            ? Routes.researchScan(item.id)
            : Routes.scanItem(item.id),
      );

      await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

      expect(env.engine.fileCalls.single.retainAudio, isTrue);
      expect(env.scans.scans.single.audioRetained, isTrue);
      expect(
        routerOf(tester).state.uri.path,
        research
            ? Routes.labelSample(item.id, env.scans.scans.single.id)
            : Routes.result(item.id, env.scans.scans.single.id),
      );
    });
  }

  testWidgets('WAV outcomes append without rewriting earlier results', (
    tester,
  ) async {
    final env = _CaptureEnv();
    final item = await env.addItem();
    env.picker.media = _wav();
    env.engine.next = (id) => modelOutcome(
      id,
      Classification.uncertain,
      confidence: 0.43,
      version: 'test-grain-v2',
    );
    await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));
    await tapVisible(tester, find.byKey(const Key('upload-audio-file')));
    final first = env.scans.scans.single;
    expect(first.result, Classification.uncertain);
    expect(first.confidence, 0.43);
    expect(first.modelVersion, 'test-grain-v2');

    env.engine.next = (id) =>
        retryOutcome(id, reasons: [QualityReason.clipping]);
    routerOf(tester).go(Routes.scanItem(item.id));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

    expect(env.scans.scans, hasLength(2));
    expect(env.scans.scans.first, same(first));
    final retry = env.scans.scans.last;
    expect(retry.id, isNot(first.id));
    expect(retry.quality, ScanQuality.retry);
    expect(retry.qualityReasons, [QualityReason.clipping]);
    expect(retry.result, Classification.notEvaluated);
    expect(retry.confidence, isNull);
    expect(find.text(en.headlineRetry), findsOneWidget);
  });

  testWidgets('WAV engine failures leave scan history untouched', (
    tester,
  ) async {
    final env = _CaptureEnv();
    final item = await env.addItem();
    env.picker.media = _wav();
    env.engine.error = StateError('WAV decoder rejected the file');
    await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

    await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

    expect(
      find.textContaining('WAV decoder rejected the file'),
      findsOneWidget,
    );
    expect(env.engine.fileCalls, hasLength(1));
    expect(env.scans.scans, isEmpty);
    expect(find.byKey(const Key('start-capture')), findsOneWidget);
  });

  testWidgets('an unreadable WAV reports the picker failure without saving', (
    tester,
  ) async {
    final env = _CaptureEnv();
    final item = await env.addItem();
    env.picker.error = StateError('WAV is not readable');
    await pumpKernelApp(tester, env, location: Routes.scanItem(item.id));

    await tapVisible(tester, find.byKey(const Key('upload-audio-file')));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('WAV is not readable'), findsOneWidget);
    expect(env.engine.fileCalls, isEmpty);
    expect(env.scans.scans, isEmpty);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('upload-audio-file')))
          .onPressed,
      isNotNull,
    );
  });
}
