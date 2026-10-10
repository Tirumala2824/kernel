import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';

import 'support/dtos.dart';
import 'support/fake_llm_host.dart';

/// Lets queued microtasks and zero-delay timers run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeLlmHost host;
  late StreamController<bool> optIn;
  late LocalAdviceEngine engine;

  LocalAdviceEngine build({Duration timeout = adviceTimeout}) =>
      LocalAdviceEngine(
        optIn: optIn.stream,
        host: host,
        timeout: timeout,
        clock: () => DateTime.utc(2026, 10, 10, 8),
      );

  setUp(() {
    host = FakeLlmHost();
    optIn = StreamController<bool>.broadcast();
    engine = build();
  });

  tearDown(() async {
    await engine.dispose();
    await optIn.close();
  });

  group('opted out', () {
    test('status is optedOut and the native side is never touched', () async {
      final statuses = <AdviceStatus>[];
      final sub = engine.watchStatus().listen(statuses.add);
      optIn.add(false);
      await settle();

      final texts = await engine.explainResult(resultInput()).toList();
      final reminder = await engine
          .suggestReminderText(reminderInput())
          .toList();
      final report = await engine.draftReportNarrative(reportInput()).toList();

      expect(statuses, [AdviceStatus.optedOut]);
      expect(texts, isEmpty);
      expect(reminder, isEmpty);
      expect(report, isEmpty);
      expect(
        host.calls,
        isEmpty,
        reason: 'opt-out short-circuits before any bridge call',
      );
      await sub.cancel();
    });

    test('no opt-in value at all counts as opted out', () async {
      final texts = await build(timeout: const Duration(seconds: 5))
          .explainResult(resultInput())
          .toList();
      expect(texts, isEmpty);
      expect(host.calls, isEmpty);
    });

    test('turning the assistant off unloads the model', () async {
      engine.watchStatus().listen((_) {});
      optIn.add(true);
      await settle();
      optIn.add(false);
      await settle();
      expect(host.calls, contains('unload'));
    });
  });

  group('status transitions', () {
    test(
      'noModel -> ready -> loading -> ready -> busy -> ready -> failed',
      () async {
        host.currentStatus = nativeStatus(modelPresent: false);
        final statuses = <AdviceStatus>[];
        engine.watchStatus().listen(statuses.add);

        optIn.add(true);
        await settle();
        expect(statuses.last, AdviceStatus.noModel);

        host.push(nativeStatus(state: NativeEngineState.unloaded));
        host.push(nativeStatus(state: NativeEngineState.loading));
        host.push(nativeStatus(state: NativeEngineState.ready, backend: 'gpu'));
        host.push(nativeStatus(state: NativeEngineState.busy, backend: 'gpu'));
        host.push(nativeStatus(state: NativeEngineState.ready, backend: 'gpu'));
        host.push(nativeStatus(state: NativeEngineState.failed));
        await settle();

        expect(statuses, [
          AdviceStatus.optedOut,
          AdviceStatus.noModel,
          AdviceStatus.ready,
          AdviceStatus.loading,
          AdviceStatus.ready,
          AdviceStatus.busy,
          AdviceStatus.ready,
          AdviceStatus.failed,
        ]);
      },
    );

    test('a late listener gets the current status first', () async {
      engine.watchStatus().listen((_) {});
      optIn.add(true);
      await settle();
      host.push(nativeStatus(state: NativeEngineState.ready));
      expect(await engine.watchStatus().first, AdviceStatus.ready);
    });

    test('a bridge failure on status reads as failed', () async {
      host.statusError = PlatformException(code: 'channel-error');
      final statuses = <AdviceStatus>[];
      engine.watchStatus().listen(statuses.add);
      optIn.add(true);
      await settle();
      expect(statuses.last, AdviceStatus.failed);
    });

    test('busy while generating, ready afterwards', () async {
      final gate = Completer<NativeGenerateResult>();
      host.onGenerate = (_) => gate.future;
      final statuses = <AdviceStatus>[];
      engine.watchStatus().listen(statuses.add);
      optIn.add(true);
      await settle();

      final done = engine.explainResult(resultInput()).toList();
      await settle();
      await settle();
      expect(statuses.last, AdviceStatus.busy);

      gate.complete(nativeResult());
      expect(await done, hasLength(1));
      expect(statuses.last, AdviceStatus.ready);
    });
  });

  group('generation', () {
    setUp(() async {
      engine.watchStatus().listen((_) {});
      optIn.add(true);
      await settle();
    });

    test(
      'emits one complete, experimental text with the sidecar version',
      () async {
        final texts = await engine
            .explainResult(resultInput(), languageTag: 'hi-IN')
            .toList();

        expect(texts, hasLength(1));
        final t = texts.single;
        expect(t.complete, isTrue);
        expect(t.experimental, isTrue);
        expect(t.modelVersion, 'gemma-4-E2B-it@0123456789ab');
        expect(t.languageTag, 'hi');
        expect(t.generatedAt, DateTime.utc(2026, 10, 10, 8));
        expect(t.text, startsWith('The scan heard likely insect sounds.'));

        final call = host.generateCalls.single;
        expect(call.systemInstruction, contains('Answer only in Hindi'));
        expect(call.prompt, contains('- Grain: Wheat'));
        expect(call.timeoutMs, lessThanOrEqualTo(25000));
      },
    );

    test(
      'falls back to the model info version when native sends none',
      () async {
        host.onGenerate = (_) async => nativeResult(modelVersion: '');
        final t = await engine.suggestReminderText(reminderInput()).single;
        expect(t.modelVersion, 'gemma-4-E2B-it@0123456789ab');
      },
    );

    test('guard rejection ends the stream without a complete event', () async {
      host.onGenerate = (_) async => nativeResult(
        text: 'Your grain is safe. Spray some pesticide anyway.',
      );
      expect(await engine.explainResult(resultInput()).toList(), isEmpty);
    });

    test('timeout cancels the native request and falls back', () async {
      await engine.dispose();
      engine = build(timeout: const Duration(milliseconds: 50));
      engine.watchStatus().listen((_) {});
      optIn.add(true);
      await settle();
      host.onGenerate = (_) => Completer<NativeGenerateResult>().future;

      final texts = await engine.explainResult(resultInput()).toList();

      expect(texts, isEmpty);
      expect(host.cancelled, [host.generateCalls.single.requestId]);
    });

    test('non-ok native results fall back silently', () async {
      for (final status in [
        NativeGenerateStatus.busy,
        NativeGenerateStatus.noModel,
        NativeGenerateStatus.loadFailed,
        NativeGenerateStatus.timeout,
        NativeGenerateStatus.cancelled,
        NativeGenerateStatus.error,
      ]) {
        host.onGenerate = (_) async => nativeResult(status: status);
        expect(
          await engine.explainResult(resultInput()).toList(),
          isEmpty,
          reason: '$status',
        );
      }
    });

    test('bridge errors never throw', () async {
      host.onGenerate = (_) async => throw PlatformException(code: 'boom');
      expect(
        await engine.draftReportNarrative(reportInput()).toList(),
        isEmpty,
      );
    });

    test('no model installed: nothing is generated', () async {
      host.info = null;
      expect(await engine.explainResult(resultInput()).toList(), isEmpty);
      expect(host.calls, isNot(contains('generate')));
      expect(await engine.modelInfo(), isNull);
    });

    test('noModel or failed status short-circuits', () async {
      host.push(nativeStatus(modelPresent: false));
      expect(await engine.explainResult(resultInput()).toList(), isEmpty);
      host.push(nativeStatus(state: NativeEngineState.failed));
      expect(await engine.explainResult(resultInput()).toList(), isEmpty);
      expect(host.calls, isNot(contains('generate')));
    });

    test('a second request while one runs is rejected, not queued', () async {
      final gate = Completer<NativeGenerateResult>();
      host.onGenerate = (_) => gate.future;
      final first = engine.explainResult(resultInput()).toList();
      await settle();
      await settle();

      final second = await engine.explainResult(resultInput()).toList();
      expect(second, isEmpty);
      expect(host.generateCalls, hasLength(1));

      gate.complete(nativeResult());
      expect(await first, hasLength(1));
    });

    test('cancelling the subscription cancels the native request', () async {
      host.onGenerate = (_) => Completer<NativeGenerateResult>().future;
      final sub = engine.explainResult(resultInput()).listen((_) {});
      await settle();
      await settle();
      await sub.cancel();
      expect(host.cancelled, [host.generateCalls.single.requestId]);
    });

    test('modelInfo maps the native sidecar info', () async {
      final info = await engine.modelInfo();
      expect(info!.id, 'gemma-4-E2B-it');
      expect(info.version, 'gemma-4-E2B-it@0123456789ab');
      expect(info.sizeBytes, 2588147712);
      expect(info.backend, 'none');
    });

    test('warmUp asks the native side to load', () async {
      await engine.warmUp();
      expect(host.calls, contains('load'));
    });
  });
}
