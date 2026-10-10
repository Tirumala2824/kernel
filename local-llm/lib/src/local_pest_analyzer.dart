import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';
import 'media.dart';
import 'output_guard.dart';
import 'pest_parsing.dart';
import 'pest_prompts.dart';
import 'runtime_manager.dart';

/// Whole budget of one analysis (all runs, queue wait and model load).
/// Past it the call returns null.
const Duration pestAnalysisBudget = Duration(seconds: 45);

/// Budget of one card-grounded guidance answer (same as grain advice).
const Duration pestGuideTimeout = Duration(seconds: 25);

/// Independent label-only runs for self-consistency.
const int selfConsistencySamples = 3;
const double selfConsistencyTemperature = 0.7;

/// Production [PestAnalyzer] on Gemma 4 E2B (LiteRT-LM), Pest ID mode only
/// (guardrails §8 amendment, §9):
///
/// - The engine is the Pest ID one: vision encoder on GPU (CPU fallback),
///   audio encoder on CPU, visual token budget 560 (Kotlin PestIdConfig).
///   The grain advice engine never gets these encoders.
/// - [analyzeImage]: three label-only runs at temperature 0.7 (regex over
///   the allowed card ids plus "none"), then one constrained-JSON analysis.
///   When at least 2 of 3 runs agree, the JSON label is constrained to that
///   majority, so the reported label, its description and `agreement`
///   (majority count / 3) always refer to the same card. Images go before
///   the text.
/// - [describeSound]: an experimental one- or two-sentence description of
///   the clip with the sound-classifier labels. Gemma's audio understanding
///   is documented for speech only.
/// - [proposeRegions]: Gemma `box_2d` boxes, empty on any failure.
/// - [guide]: text only, grounded in the given cards, guarded against
///   poisons, pesticides, doses, certainty and safety claims.
/// - Never throws, never logs prompts, media or outputs. Media stay in
///   memory for the one call.
/// - Runs on the shared [RuntimeManager] (slot [RuntimeSlot.pestId]); one
///   analysis holds the runtime for all its runs.
class LocalPestAnalyzer implements PestAnalyzer {
  LocalPestAnalyzer({
    this._modelPath,
    RuntimeManager? runtime,
    Stream<bool>? enabled,
    @visibleForTesting LlmHost? host,
    @visibleForTesting this._budget = pestAnalysisBudget,
    @visibleForTesting this._guideTimeout = pestGuideTimeout,
    @visibleForTesting DateTime Function()? clock,
    @visibleForTesting String Function()? newId,
  }) : _runtime =
           runtime ??
           (host != null ? RuntimeManager(host: host) : RuntimeManager.shared),
       _ownsRuntime = runtime == null && host != null,
       _enabledSource = enabled,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? _uuidV4;

  final ModelPathResolver? _modelPath;
  final RuntimeManager _runtime;
  final bool _ownsRuntime;
  final Stream<bool>? _enabledSource;
  final Duration _budget;
  final Duration _guideTimeout;
  final DateTime Function() _clock;
  final String Function() _newId;

  LlmHost get _host => _runtime.host;

  int _seq = 0;
  int _running = 0;
  bool? _enabled;
  final Completer<void> _enabledKnown = Completer<void>();
  bool? _resolvedPresent;
  NativeEngineStatus? _native;
  AdviceStatus? _status;
  bool _started = false;
  StreamSubscription<bool>? _enabledSub;
  StreamSubscription<NativeEngineStatus>? _nativeSub;
  final StreamController<AdviceStatus> _changes =
      StreamController<AdviceStatus>.broadcast(sync: true);

  // -------------------------------------------------------------------------
  // Status

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    final source = _enabledSource;
    if (source == null) {
      _enabled = true;
      _enabledKnown.complete();
    } else {
      void set(bool v) {
        _enabled = v;
        if (!_enabledKnown.isCompleted) _enabledKnown.complete();
        _recompute();
      }

      _enabledSub = source.listen(set, onError: (Object _) => set(false));
    }
    _nativeSub = _host.engineStatus.listen((s) {
      _native = s;
      _recompute();
    }, onError: (Object _) {});
    unawaited(_refresh());
    _recompute();
  }

  Future<void> _refresh() async {
    try {
      final status = await _host.status();
      if (_modelPath != null) await _resolve();
      _native = status;
    } catch (_) {
      _native = NativeEngineStatus(
        state: NativeEngineState.failed,
        modelPresent: true,
        backend: 'none',
      );
    }
    _recompute();
  }

  void _recompute() {
    final next = _compute();
    if (next == null || next == _status || _changes.isClosed) return;
    _status = next;
    _changes.add(next);
  }

  AdviceStatus? _compute() {
    if (_enabled == false) return AdviceStatus.optedOut;
    if (_enabled == null) return null;
    final n = _native;
    if (n == null) return null;
    final present = _modelPath == null
        ? n.modelPresent
        : (_resolvedPresent ?? false);
    if (!present) return AdviceStatus.noModel;
    if (_running > 0) return AdviceStatus.busy;
    final mine = n.slot == null || n.slot == NativeRuntimeSlot.pestId;
    return switch (n.state) {
      NativeEngineState.unloaded => AdviceStatus.ready,
      NativeEngineState.loading =>
        mine ? AdviceStatus.loading : AdviceStatus.busy,
      NativeEngineState.ready => AdviceStatus.ready,
      NativeEngineState.busy => AdviceStatus.busy,
      NativeEngineState.failed =>
        mine ? AdviceStatus.failed : AdviceStatus.ready,
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

  Future<bool> _isEnabled() async {
    _ensureStarted();
    if (_enabled == null) {
      try {
        await _enabledKnown.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        return false;
      }
    }
    return _enabled == true;
  }

  /// (ok, path): ok is false when a resolver exists and has no model, so
  /// the legacy directory is not consulted.
  Future<(bool, String?)> _resolve() async {
    final resolver = _modelPath;
    if (resolver == null) return (true, null);
    String? path;
    try {
      path = await resolver();
    } catch (_) {
      path = null;
    }
    if (path != null && path.isEmpty) path = null;
    _resolvedPresent = path != null;
    _recompute();
    return (path != null, path);
  }

  void _setRunning(bool on) {
    _running += on ? 1 : -1;
    if (_running < 0) _running = 0;
    _recompute();
  }

  /// One native Pest ID run within [left]. Null on timeout, a non-ok
  /// status or a bridge error; a timeout cancels the native request.
  Future<NativeGenerateResult?> _generate(
    NativePestRequest Function(int timeoutMs) build,
    Duration Function() left, {
    void Function(String id)? onId,
  }) async {
    final remaining = left();
    if (remaining <= Duration.zero) return null;
    final id = 'pest-${++_seq}';
    onId?.call(id);
    try {
      final r = await _host
          .pestGenerate(id, build(remaining.inMilliseconds))
          .timeout(remaining);
      return r.status == NativeGenerateStatus.ok ? r : null;
    } on TimeoutException {
      unawaited(_host.cancel(id).catchError((Object _) {}));
      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // analyzeImage

  @override
  Future<PestAnalysis?> analyzeImage(PestImageRequest request) async {
    final clock = Stopwatch()..start();
    Duration left() => _budget - clock.elapsed;
    var running = false;
    try {
      if (!await _isEnabled()) return null;
      if (!isUsableImage(request.crop)) return null;
      final contextImage = request.context;
      final images = <Uint8List>[
        request.crop,
        if (contextImage != null && isUsableImage(contextImage)) contextImage,
      ];
      final choices = [...sanitizeCardIds(request.allowedCardIds), noMatchLabel];
      final (ok, path) = await _resolve();
      if (!ok) return null;
      final scene = PestScene(
        hasContext: images.length > 1,
        room: sanitizeRoomHint(request.roomHint),
        signal: request.candidate?.kind,
      );
      final wait = left();
      if (wait <= Duration.zero) return null;
      _setRunning(true);
      running = true;
      return await _runtime.run(RuntimeSlot.pestId, () async {
        // 1. Self-consistency: label-only votes.
        final vote = renderLabelPrompt(scene, choices);
        final votes = <String?>[];
        for (var i = 0; i < selfConsistencySamples; i++) {
          final r = await _generate(
            (ms) => NativePestRequest(
              modelPath: path,
              systemInstruction: vote.systemInstruction,
              prompt: vote.prompt,
              images: images,
              audioWav: null,
              format: NativeResponseFormat.regex,
              formatSpec: labelPattern(choices),
              temperature: selfConsistencyTemperature,
              topK: 40,
              topP: 0.95,
              // Distinct seeds keep the runs independent samples.
              seed: i + 1,
              maxOutputTokens: 24,
              timeoutMs: ms,
            ),
            left,
          );
          if (r == null) return null;
          votes.add(parseLabel(r.text, choices.toSet()));
        }
        final (majority, count) = majorityVote(votes);
        final strict = majority != null && count * 2 > selfConsistencySamples;
        final jsonChoices = strict ? [majority] : choices;

        // 2. Structured analysis.
        final analysis = renderAnalysisPrompt(
          scene,
          jsonChoices,
          languageTag: request.languageTag,
        );
        final j = await _generate(
          (ms) => NativePestRequest(
            modelPath: path,
            systemInstruction: analysis.systemInstruction,
            prompt: analysis.prompt,
            images: images,
            audioWav: null,
            format: NativeResponseFormat.json,
            formatSpec: analysisSchema(jsonChoices),
            temperature: 0.2,
            topK: 40,
            topP: 0.9,
            seed: 1,
            maxOutputTokens: 640,
            timeoutMs: ms,
          ),
          left,
        );
        if (j == null) return null;
        final parsed = parseAnalysis(j.text, jsonChoices.toSet());
        if (parsed == null) return null;
        final guarded = guardAnalysis(parsed);
        if (guarded == null) return null;
        if (left() <= Duration.zero) return null;
        return PestAnalysis(
          analysisId: _newId(),
          createdAt: _clock().toUtc(),
          source: SignalSource.camera,
          cardId: guarded.cardId == noMatchLabel ? null : guarded.cardId,
          commonName: guarded.commonName,
          group: guarded.effectiveGroup,
          taxonomyPath: guarded.taxonomyPath,
          aiConfidence: guarded.aiConfidence,
          agreement: agreementFor(votes, guarded.cardId),
          samples: selfConsistencySamples,
          keyFeatures: guarded.keyFeatures,
          anomalies: guarded.anomalies,
          insights: guarded.insights,
          safety: guarded.safety,
          modelVersion: j.modelVersion,
          promptVersion: pestPromptVersion,
          latencyMs: clock.elapsedMilliseconds,
        );
      }, wait: wait);
    } catch (_) {
      // TimeoutException waiting for the runtime, bridge errors: null.
      return null;
    } finally {
      if (running) _setRunning(false);
    }
  }

  // -------------------------------------------------------------------------
  // describeSound

  @override
  Future<SoundAnalysis?> describeSound(PestSoundRequest request) async {
    final clock = Stopwatch()..start();
    Duration left() => _budget - clock.elapsed;
    var running = false;
    try {
      if (!await _isEnabled()) return null;
      if (!isUsableClip(request.wav)) return null;
      final labels = cleanScoredLabels(request.preFilter);
      final (ok, path) = await _resolve();
      if (!ok) return null;
      final rendered = renderSoundPrompt(
        labels,
        languageTag: request.languageTag,
      );
      final wait = left();
      if (wait <= Duration.zero) return null;
      _setRunning(true);
      running = true;
      final r = await _runtime.run(
        RuntimeSlot.pestId,
        () => _generate(
          (ms) => NativePestRequest(
            modelPath: path,
            systemInstruction: rendered.systemInstruction,
            prompt: rendered.prompt,
            images: const [],
            audioWav: request.wav,
            format: NativeResponseFormat.none,
            formatSpec: null,
            temperature: 0.3,
            topK: 40,
            topP: 0.9,
            seed: 1,
            maxOutputTokens: 120,
            timeoutMs: ms,
          ),
          left,
        ),
        wait: wait,
      );
      if (r == null) return null;
      final text = tidyOutput(r.text);
      if (!checkPestOutput(text, maxChars: 600).allowed) return null;
      return SoundAnalysis(
        preFilter: labels,
        groupHint: groupHintFromLabels(labels),
        modelVersion: r.modelVersion,
        description: text,
      );
    } catch (_) {
      return null;
    } finally {
      if (running) _setRunning(false);
    }
  }

  // -------------------------------------------------------------------------
  // proposeRegions

  @override
  Future<List<NormalizedBox>> proposeRegions(
    Uint8List image, {
    required List<String> labels,
  }) async {
    final clock = Stopwatch()..start();
    Duration left() => _budget - clock.elapsed;
    var running = false;
    try {
      if (!await _isEnabled()) return const [];
      if (!isUsableImage(image)) return const [];
      final clean = sanitizeRegionLabels(labels);
      if (clean.isEmpty) return const [];
      final (ok, path) = await _resolve();
      if (!ok) return const [];
      final rendered = renderRegionPrompt(clean);
      final wait = left();
      if (wait <= Duration.zero) return const [];
      _setRunning(true);
      running = true;
      final r = await _runtime.run(
        RuntimeSlot.pestId,
        () => _generate(
          (ms) => NativePestRequest(
            modelPath: path,
            systemInstruction: rendered.systemInstruction,
            prompt: rendered.prompt,
            images: [image],
            audioWav: null,
            format: NativeResponseFormat.json,
            formatSpec: regionSchema(clean),
            temperature: 0.0,
            topK: 1,
            topP: 1.0,
            seed: 1,
            maxOutputTokens: 400,
            timeoutMs: ms,
          ),
          left,
        ),
        wait: wait,
      );
      if (r == null) return const [];
      return parseBoxes(r.text, labels: clean.toSet());
    } catch (_) {
      return const [];
    } finally {
      if (running) _setRunning(false);
    }
  }

  // -------------------------------------------------------------------------
  // guide

  @override
  Stream<AdviceText> guide(PestGuideInput input) {
    String? requestId;
    var finished = false;
    late final StreamController<AdviceText> out;
    out = StreamController<AdviceText>(
      onListen: () async {
        try {
          final text = await _runGuide(input, (id) => requestId = id);
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

  Future<AdviceText?> _runGuide(
    PestGuideInput input,
    void Function(String id) onRequestId,
  ) async {
    final clock = Stopwatch()..start();
    Duration left() => _guideTimeout - clock.elapsed;
    if (!await _isEnabled()) return null;
    // Grounded only: without cards there is nothing the model may say.
    if (input.cards.isEmpty) return null;
    final rendered = renderGuidePrompt(input);
    final (ok, path) = await _resolve();
    if (!ok) return null;
    final wait = left();
    if (wait <= Duration.zero) return null;
    _setRunning(true);
    try {
      final r = await _runtime.run(RuntimeSlot.pestId, () {
        return _generate(
          onId: onRequestId,
          (ms) => NativePestRequest(
            modelPath: path,
            systemInstruction: rendered.systemInstruction,
            prompt: rendered.prompt,
            images: const [],
            audioWav: null,
            format: NativeResponseFormat.none,
            formatSpec: null,
            temperature: 0.3,
            topK: 40,
            topP: 0.9,
            seed: 1,
            maxOutputTokens: 320,
            timeoutMs: ms,
          ),
          left,
        );
      }, wait: wait);
      if (r == null) return null;
      final text = tidyOutput(r.text);
      if (!checkPestOutput(text).allowed) return null;
      return AdviceText(
        text: text,
        complete: true,
        modelVersion: r.modelVersion,
        languageTag: rendered.languageTag,
        generatedAt: _clock().toUtc(),
      );
    } on TimeoutException {
      return null;
    } finally {
      _setRunning(false);
    }
  }

  /// Stops listening (tests, app exit). A shared runtime is left running.
  Future<void> dispose() async {
    await _enabledSub?.cancel();
    await _nativeSub?.cancel();
    await _changes.close();
    if (_ownsRuntime) await _runtime.dispose();
  }
}

/// The parsed analysis with every free-text field run through the Pest ID
/// output guard: list items that fail are dropped; a name that fails drops
/// the whole analysis (it would be shown as the label).
ParsedAnalysis? guardAnalysis(ParsedAnalysis a) {
  bool ok(String s, int max) => checkPestOutput(s, maxChars: max).allowed;
  if (!ok(a.commonName, maxNameChars)) return null;
  List<String> keep(List<String> items) =>
      [for (final s in items) if (ok(s, maxItemChars)) s];
  return ParsedAnalysis(
    cardId: a.cardId,
    commonName: a.commonName,
    group: a.group,
    taxonomyPath: keep(a.taxonomyPath),
    aiConfidence: a.aiConfidence,
    keyFeatures: keep(a.keyFeatures),
    anomalies: keep(a.anomalies),
    insights: keep(a.insights),
    safety: a.safety,
    isPest: a.isPest,
  );
}

final math.Random _ids = math.Random.secure();

/// RFC 4122 version 4 identifier for [PestAnalysis.analysisId].
String _uuidV4() {
  final b = List<int>.generate(16, (_) => _ids.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  String hex(int from, int to) => [
    for (var i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
