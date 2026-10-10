import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';

import 'support/dtos.dart';
import 'support/fake_llm_host.dart';
import 'support/media.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Test double that tracks which engine the "native side" holds, and flags
/// any request that arrives while a different engine is still loaded.
class TrackingHost extends FakeLlmHost {
  NativeRuntimeSlot? held;
  final List<String> violations = [];

  void _use(NativeRuntimeSlot slot) {
    if (held != null && held != slot) {
      violations.add('${slot.name} requested while ${held!.name} loaded');
    }
    held = slot;
  }

  @override
  Future<NativeGenerateResult> generate(
    String requestId,
    String? modelPath,
    String systemInstruction,
    String prompt,
    int timeoutMs,
  ) {
    _use(NativeRuntimeSlot.advice);
    return super.generate(
      requestId,
      modelPath,
      systemInstruction,
      prompt,
      timeoutMs,
    );
  }

  @override
  Future<NativeGenerateResult> pestGenerate(
    String requestId,
    NativePestRequest request,
  ) {
    _use(NativeRuntimeSlot.pestId);
    return super.pestGenerate(requestId, request);
  }

  @override
  Future<NativeEmbedResult> embed(String requestId, NativeEmbedRequest request) {
    _use(NativeRuntimeSlot.embedder);
    return super.embed(requestId, request);
  }

  @override
  Future<void> unload() async {
    held = null;
    await super.unload();
  }
}

void main() {
  late FakeLlmHost host;
  late RuntimeManager runtime;

  setUp(() {
    host = FakeLlmHost();
    runtime = RuntimeManager(
      host: host,
      idleUnload: const Duration(milliseconds: 40),
    );
  });

  tearDown(() => runtime.dispose());

  group('serialisation', () {
    test('requests run one at a time, in order', () async {
      final events = <String>[];
      final gate = Completer<void>();
      final a = runtime.run(RuntimeSlot.advice, () async {
        events.add('a start');
        await gate.future;
        events.add('a end');
        return 'a';
      });
      final b = runtime.run(RuntimeSlot.advice, () async {
        events.add('b start');
        return 'b';
      });
      await settle();
      expect(events, ['a start']);
      expect(runtime.isBusy, isTrue);
      gate.complete();
      expect(await a, 'a');
      expect(await b, 'b');
      expect(events, ['a start', 'a end', 'b start']);
    });

    test('a request that waits too long never runs', () async {
      final gate = Completer<void>();
      final first = runtime.run(RuntimeSlot.pestId, () => gate.future);
      var ran = false;
      await expectLater(
        runtime.run(RuntimeSlot.advice, () async {
          ran = true;
        }, wait: const Duration(milliseconds: 20)),
        throwsA(isA<TimeoutException>()),
      );
      gate.complete();
      await first;
      // The queue keeps working after the abandoned waiter.
      expect(await runtime.run(RuntimeSlot.pestId, () async => 7), 7);
      expect(ran, isFalse);
    });

    test('task errors are rethrown and release the runtime', () async {
      await expectLater(
        runtime.run(RuntimeSlot.advice, () async => throw StateError('x')),
        throwsStateError,
      );
      expect(runtime.isBusy, isFalse);
      expect(await runtime.run(RuntimeSlot.advice, () async => 1), 1);
    });
  });

  group('mutual exclusion', () {
    test('switching slots unloads first; the same slot does not', () async {
      await runtime.run(RuntimeSlot.advice, () async => host.calls.add('a'));
      await runtime.run(RuntimeSlot.advice, () async => host.calls.add('a'));
      await runtime.run(RuntimeSlot.embedder, () async => host.calls.add('e'));
      await runtime.run(RuntimeSlot.pestId, () async => host.calls.add('p'));
      expect(host.calls, ['a', 'a', 'unload', 'e', 'unload', 'p']);
      expect(runtime.loadedSlot, RuntimeSlot.pestId);
    });

    test('Gemma and EmbeddingGemma are never requested together', () async {
      final tracking = TrackingHost()
        ..onEmbed = ((_, _) async => nativeEmbed(values: List.filled(768, 0.1)))
        ..onPest = ((_, _) async => nativeResult(text: '[]'));
      final shared = RuntimeManager(host: tracking);
      final optIn = StreamController<bool>.broadcast();
      final advice = LocalAdviceEngine(optIn: optIn.stream, runtime: shared);
      final embedder = LocalEmbedder(runtime: shared);
      final analyzer = LocalPestAnalyzer(runtime: shared);
      advice.watchStatus().listen((_) {});
      optIn.add(true);
      await settle();

      // Interleaved callers from different features.
      final results = await Future.wait<Object?>([
        embedder.embedText('rice weevil'),
        advice.explainResult(resultInput()).toList(),
        embedder.embedText('rat droppings'),
        analyzer.proposeRegions(pngBytes(), labels: const ['insect']),
        advice.suggestReminderText(reminderInput()).toList(),
      ]);

      expect(tracking.violations, isEmpty);
      expect(results[0], isNotNull);
      expect(tracking.calls.where((c) => c == 'unload').length, greaterThan(1));
      await advice.dispose();
      await analyzer.dispose();
      await shared.dispose();
      await optIn.close();
    });

    test('release only unloads its own slot', () async {
      await runtime.run(RuntimeSlot.pestId, () async {});
      await runtime.release(RuntimeSlot.advice);
      expect(host.calls, isNot(contains('unload')));
      await runtime.release(RuntimeSlot.pestId);
      expect(host.calls, ['unload']);
      expect(runtime.loadedSlot, isNull);
      // Nothing loaded: release is allowed (frees whatever native holds).
      await runtime.release(RuntimeSlot.advice);
      expect(host.calls, ['unload', 'unload']);
    });

    test('release never interrupts another slot that is running', () async {
      final gate = Completer<void>();
      final running = runtime.run(RuntimeSlot.embedder, () => gate.future);
      await settle();
      await runtime.release(RuntimeSlot.advice);
      expect(host.calls, isEmpty);
      gate.complete();
      await running;
    });
  });

  group('idle unload and memory pressure', () {
    test('unloads after the idle time', () async {
      await runtime.run(RuntimeSlot.advice, () async {});
      expect(runtime.loadedSlot, RuntimeSlot.advice);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(host.calls, ['unload']);
      expect(runtime.loadedSlot, isNull);
    });

    test('a new request restarts the idle timer', () async {
      await runtime.run(RuntimeSlot.advice, () async {});
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await runtime.run(RuntimeSlot.advice, () async {});
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(host.calls, isEmpty, reason: 'timer was reset');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(host.calls, ['unload']);
    });

    test('never idle-unloads during a running request', () async {
      final gate = Completer<void>();
      await runtime.run(RuntimeSlot.advice, () async {});
      final long = runtime.run(RuntimeSlot.advice, () => gate.future);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(host.calls, isEmpty);
      gate.complete();
      await long;
    });

    test('trimMemory unloads now', () async {
      await runtime.run(RuntimeSlot.embedder, () async {});
      await runtime.trimMemory();
      expect(host.calls, ['unload']);
      expect(runtime.loadedSlot, isNull);
    });

    test('follows native unloads (onTrimMemory, native idle)', () async {
      await runtime.run(RuntimeSlot.advice, () async {});
      host.push(nativeStatus(state: NativeEngineState.unloaded));
      expect(runtime.loadedSlot, isNull);
      host.push(
        nativeStatus(
          state: NativeEngineState.ready,
          slot: NativeRuntimeSlot.embedder,
        ),
      );
      expect(runtime.loadedSlot, RuntimeSlot.embedder);
      // Next advice request unloads the embedder first.
      await runtime.run(RuntimeSlot.advice, () async {});
      expect(host.calls, ['unload']);
    });

    test('unload errors are swallowed', () async {
      final failing = _FailingUnloadHost();
      final r = RuntimeManager(host: failing);
      await r.run(RuntimeSlot.advice, () async {});
      await r.unload();
      await r.run(RuntimeSlot.embedder, () async {});
      expect(r.loadedSlot, RuntimeSlot.embedder);
      await r.dispose();
    });
  });

  test('advice opt-out frees only an advice engine', () async {
    final optIn = StreamController<bool>.broadcast();
    final advice = LocalAdviceEngine(optIn: optIn.stream, runtime: runtime);
    advice.watchStatus().listen((_) {});
    optIn.add(true);
    await settle();
    await runtime.run(RuntimeSlot.pestId, () async {});
    host.calls.clear();
    optIn.add(false);
    await settle();
    expect(host.calls, isNot(contains('unload')));
    await advice.dispose();
    await optIn.close();
  });
}

class _FailingUnloadHost extends FakeLlmHost {
  @override
  Future<void> unload() async => throw StateError('detached');
}
