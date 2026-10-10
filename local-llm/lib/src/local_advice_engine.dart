import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';
import 'output_guard.dart';
import 'prompts.dart';

/// Whole-request budget, model load included. Past it the request is
/// cancelled and the stream ends without a complete event (static copy).
const Duration adviceTimeout = Duration(seconds: 25);

/// How long to wait for the first opt-in value before treating the user as
/// opted out.
const Duration _optInWait = Duration(seconds: 2);

/// Production [AdviceEngine] on Google AI Edge LiteRT-LM, entirely on the
/// phone.
///
/// - Off until [optIn] says true; while opted out nothing reaches the
///   native side and every stream is empty.
/// - Text only: prompts are rendered from the typed DTO fields
///   (`prompts.dart`). No audio, path or byte field exists anywhere on the
///   way to the model.
/// - Never blocking, never throwing: no model, busy, load failure, the
///   [adviceTimeout] or a guard rejection all end the stream without a
///   complete event, which means "use the static localized copy".
/// - Streams emit at most one event: the complete, guarded text. Partial
///   output is never shown because the guard needs the full text.
/// - Generated text is always experimental and carries the model's
///   sidecar version as `modelVersion`.
///
/// The app must not request advice while a scan capture is running.
class LocalAdviceEngine implements AdviceEngine {
  LocalAdviceEngine({
    required Stream<bool> optIn,
    @visibleForTesting LlmHost? host,
    @visibleForTesting this._timeout = adviceTimeout,
    @visibleForTesting DateTime Function()? clock,
  }) : _optInSource = optIn,
       _host = host ?? PigeonLlmHost(),
       _clock = clock ?? DateTime.now;

  final Stream<bool> _optInSource;
  final LlmHost _host;
  final Duration _timeout;
  final DateTime Function() _clock;

  bool? _optedIn;
  final Completer<void> _optInKnown = Completer<void>();
  NativeEngineStatus? _native;
  AdviceStatus? _status;
  final StreamController<AdviceStatus> _changes =
      StreamController<AdviceStatus>.broadcast(sync: true);
  StreamSubscription<bool>? _optInSub;
  StreamSubscription<NativeEngineStatus>? _nativeSub;
  bool _started = false;
  int _seq = 0;
  bool _generating = false;

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    _optInSub = _optInSource.listen(
      _onOptIn,
      onError: (Object _) => _onOptIn(false),
    );
    // Off by default until the opt-in stream says otherwise.
    _recompute();
  }

  void _onOptIn(bool value) {
    final was = _optedIn;
    _optedIn = value;
    if (!_optInKnown.isCompleted) _optInKnown.complete();
    if (value && was != true) {
      _nativeSub ??= _host.engineStatus.listen(_onNative);
      unawaited(_refreshNative());
    } else if (!value && was == true) {
      // Free the model's memory as soon as the user turns the assistant off.
      unawaited(_host.unload().catchError((Object _) {}));
    }
    _recompute();
  }

  void _onNative(NativeEngineStatus status) {
    _native = status;
    _recompute();
  }

  Future<void> _refreshNative() async {
    try {
      _onNative(await _host.status());
    } catch (_) {
      // The plugin cannot be reached: report failed (static copy), not
      // noModel, which would invite the user to import a model.
      _native = NativeEngineStatus(
        state: NativeEngineState.failed,
        modelPresent: true,
        backend: 'none',
      );
      _recompute();
    }
  }

  void _recompute() {
    final next = _compute();
    if (next == null || next == _status || _changes.isClosed) return;
    _status = next;
    _changes.add(next);
  }

  AdviceStatus? _compute() {
    if (_optedIn != true) return AdviceStatus.optedOut;
    final n = _native;
    if (n == null) return null;
    if (!n.modelPresent) return AdviceStatus.noModel;
    if (_generating) return AdviceStatus.busy;
    return switch (n.state) {
      // Present but not in memory: it loads on the first request.
      NativeEngineState.unloaded => AdviceStatus.ready,
      NativeEngineState.loading => AdviceStatus.loading,
      NativeEngineState.ready => AdviceStatus.ready,
      NativeEngineState.busy => AdviceStatus.busy,
      NativeEngineState.failed => AdviceStatus.failed,
    };
  }

  /// Current status first (once known), then every change.
  @override
  Stream<AdviceStatus> watchStatus() {
    _ensureStarted();
    late final StreamController<AdviceStatus> out;
    StreamSubscription<AdviceStatus>? sub;
    out = StreamController<AdviceStatus>(
      onListen: () {
        final current = _status;
        if (current != null) out.add(current);
        sub = _changes.stream.listen(out.add, onDone: out.close);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<AdviceModelInfo?> modelInfo() async {
    _ensureStarted();
    try {
      final info = await _host.modelInfo();
      if (info == null) return null;
      return AdviceModelInfo(
        id: info.id,
        version: info.version,
        sizeBytes: info.sizeBytes,
        backend: info.backend,
      );
    } catch (_) {
      return null;
    }
  }

  /// Loads the model now (for example when a result screen opens) so the
  /// first request does not pay the load time. No-op unless opted in.
  Future<void> warmUp() async {
    _ensureStarted();
    if (!await _isOptedIn()) return;
    try {
      _onNative(await _host.load());
    } catch (_) {}
  }

  @override
  Stream<AdviceText> explainResult(
    ResultAdviceInput input, {
    String? languageTag,
  }) => _generate(() => renderResultPrompt(input, languageTag: languageTag));

  @override
  Stream<AdviceText> draftReportNarrative(
    ReportNarrativeInput input, {
    String? languageTag,
  }) => _generate(() => renderReportPrompt(input, languageTag: languageTag));

  @override
  Stream<AdviceText> suggestReminderText(
    ReminderAdviceInput input, {
    String? languageTag,
  }) => _generate(() => renderReminderPrompt(input, languageTag: languageTag));

  Future<bool> _isOptedIn() async {
    if (_optedIn == null) {
      try {
        await _optInKnown.future.timeout(_optInWait);
      } on TimeoutException {
        return false;
      }
    }
    return _optedIn == true;
  }

  Stream<AdviceText> _generate(RenderedPrompt Function() render) {
    _ensureStarted();
    String? requestId;
    var finished = false;
    late final StreamController<AdviceText> out;
    out = StreamController<AdviceText>(
      onListen: () async {
        try {
          final text = await _run(render, (id) => requestId = id);
          if (text != null && !out.isClosed) out.add(text);
        } catch (_) {
          // Never throws: an ended stream means static copy.
        } finally {
          finished = true;
          await out.close();
        }
      },
      onCancel: () {
        final id = requestId;
        if (!finished && id != null) {
          unawaited(_host.cancel(id).catchError((Object _) {}));
        }
      },
    );
    return out.stream;
  }

  Future<AdviceText?> _run(
    RenderedPrompt Function() render,
    void Function(String id) onRequestId,
  ) async {
    if (!await _isOptedIn()) return null;
    final status = _status;
    if (status == AdviceStatus.noModel ||
        status == AdviceStatus.failed ||
        status == AdviceStatus.busy ||
        _generating) {
      return null;
    }
    final rendered = render();
    final id = 'advice-${++_seq}';
    onRequestId(id);
    _generating = true;
    _recompute();
    final clock = Stopwatch()..start();
    Duration remaining() => _timeout - clock.elapsed;
    try {
      final NativeModelInfo? info;
      final NativeGenerateResult result;
      try {
        // The first call after an adb copy hashes the file once; it counts
        // against the same budget as the generation.
        info = await _host.modelInfo().timeout(_timeout);
        if (info == null) return null;
        final left = remaining();
        if (left <= Duration.zero) return null;
        result = await _host
            .generate(
              id,
              rendered.systemInstruction,
              rendered.prompt,
              left.inMilliseconds,
            )
            .timeout(left);
      } on TimeoutException {
        unawaited(_host.cancel(id).catchError((Object _) {}));
        return null;
      }
      if (result.status != NativeGenerateStatus.ok) return null;
      final text = tidyOutput(result.text);
      if (!checkOutput(text).allowed) return null;
      return AdviceText(
        text: text,
        complete: true,
        modelVersion: result.modelVersion.isNotEmpty
            ? result.modelVersion
            : info.version,
        languageTag: rendered.languageTag,
        generatedAt: _clock().toUtc(),
      );
    } finally {
      _generating = false;
      _recompute();
    }
  }

  /// Stops listening to the opt-in and native streams (tests, app exit).
  Future<void> dispose() async {
    await _optInSub?.cancel();
    await _nativeSub?.cancel();
    await _changes.close();
  }
}
