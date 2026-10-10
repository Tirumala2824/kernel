import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';
import 'media.dart';
import 'runtime_manager.dart';

/// Whole budget of one embedding, queue wait and model load included.
const Duration embedTimeout = Duration(seconds: 15);

/// Matryoshka sizes EmbeddingGemma supports.
const Set<int> embeddingDims = {128, 256, 512, 768};

/// Longest text embedded, in Unicode code points (EmbeddingGemma takes
/// 2048 tokens; the rest is cut).
const int maxEmbedTextChars = 2000;

/// EmbeddingGemma prompt format (google/embeddinggemma model card):
/// queries `task: search result | query: ...`, documents
/// `title: none | text: ...`.
String embeddingPrompt(EmbeddingTask task, String text) => switch (task) {
  EmbeddingTask.searchQuery => 'task: search result | query: $text',
  EmbeddingTask.searchDocument => 'title: none | text: $text',
  EmbeddingTask.classification => 'task: classification | query: $text',
  EmbeddingTask.similarity => 'task: sentence similarity | query: $text',
};

/// Control characters removed, whitespace collapsed, at most
/// [maxEmbedTextChars] code points. Empty when nothing is left.
String sanitizeEmbedText(String raw) {
  final kept = raw.runes.map(
    (c) => c <= 0x1F || (c >= 0x7F && c <= 0x9F) || c == 0xFEFF ? 0x20 : c,
  );
  var s = String.fromCharCodes(kept).replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = s.runes.toList();
  if (runes.length > maxEmbedTextChars) {
    s = String.fromCharCodes(runes.take(maxEmbedTextChars)).trim();
  }
  return s;
}

/// First [dim] values, re-normalised to unit length (Matryoshka). Null
/// when the vector is shorter than [dim], all zero or not finite.
Float32List? truncateAndNormalize(List<double> full, int dim) {
  if (dim <= 0 || full.length < dim) return null;
  var sum = 0.0;
  for (var i = 0; i < dim; i++) {
    final v = full[i];
    if (!v.isFinite) return null;
    sum += v * v;
  }
  final norm = math.sqrt(sum);
  if (!norm.isFinite || norm <= 1e-12) return null;
  final out = Float32List(dim);
  for (var i = 0; i < dim; i++) {
    out[i] = full[i] / norm;
  }
  return out;
}

/// Production [Embedder] on EmbeddingGemma (LiteRT-LM), entirely on the
/// phone. GPU first, CPU fallback (native). Text, image (PNG/JPEG) and
/// audio (RIFF WAV mono 16 kHz 16-bit, at most 30 s); image and audio need
/// a model whose header lists those inputs.
///
/// - Never throws: no model, busy, timeout, unsupported input or any
///   bridge error returns null.
/// - Runs on the shared [RuntimeManager] (slot [RuntimeSlot.embedder]), so
///   EmbeddingGemma is never in memory together with Gemma.
/// - Inputs are never logged or stored.
class LocalEmbedder implements Embedder {
  LocalEmbedder({
    this._modelPath,
    RuntimeManager? runtime,
    @visibleForTesting LlmHost? host,
    @visibleForTesting this._timeout = embedTimeout,
  }) : _runtime =
           runtime ??
           (host != null ? RuntimeManager(host: host) : RuntimeManager.shared);

  final ModelPathResolver? _modelPath;
  final RuntimeManager _runtime;
  final Duration _timeout;
  int _seq = 0;

  LlmHost get _host => _runtime.host;

  /// (resolved, path): resolved is false when a resolver exists and has no
  /// model, so the legacy directory is not consulted.
  Future<(bool, String?)> _resolve() async {
    final resolver = _modelPath;
    if (resolver == null) return (true, null);
    try {
      final path = await resolver();
      if (path == null || path.isEmpty) return (false, null);
      return (true, path);
    } catch (_) {
      return (false, null);
    }
  }

  Future<NativeModelInfo?> _info() async {
    try {
      final (ok, path) = await _resolve();
      if (!ok) return null;
      return await _host
          .modelInfo(path, NativeRuntimeSlot.embedder)
          .timeout(_timeout);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async => (await _info()) != null;

  @override
  Future<String?> modelVersion() async => (await _info())?.version;

  @override
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  }) async {
    if (!embeddingDims.contains(dim)) return null;
    final clean = sanitizeEmbedText(text);
    if (clean.isEmpty) return null;
    return _embed(
      NativeEmbedKind.text,
      dim,
      text: embeddingPrompt(task, clean),
    );
  }

  @override
  Future<EmbeddingVector?> embedImage(
    Uint8List encodedImage, {
    int dim = 256,
  }) async {
    if (!embeddingDims.contains(dim) || !isUsableImage(encodedImage)) {
      return null;
    }
    return _embed(NativeEmbedKind.image, dim, bytes: encodedImage);
  }

  @override
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256}) async {
    if (!embeddingDims.contains(dim) || !isUsableClip(wav)) return null;
    return _embed(NativeEmbedKind.audio, dim, bytes: wav);
  }

  Future<EmbeddingVector?> _embed(
    NativeEmbedKind kind,
    int dim, {
    String? text,
    Uint8List? bytes,
  }) async {
    final id = 'embed-${++_seq}';
    final clock = Stopwatch()..start();
    Duration remaining() => _timeout - clock.elapsed;
    try {
      final (ok, path) = await _resolve();
      if (!ok) return null;
      final wait = remaining();
      if (wait <= Duration.zero) return null;
      final result = await _runtime.run(RuntimeSlot.embedder, () {
        final left = remaining();
        if (left <= Duration.zero) {
          throw TimeoutException('embedding budget spent', _timeout);
        }
        return _host
            .embed(
              id,
              NativeEmbedRequest(
                modelPath: path,
                kind: kind,
                text: text,
                bytes: bytes,
                timeoutMs: left.inMilliseconds,
              ),
            )
            .timeout(left);
      }, wait: wait);
      if (result.status != NativeGenerateStatus.ok) return null;
      final values = result.values;
      if (values == null || result.modelVersion.isEmpty) return null;
      final v = truncateAndNormalize(values, dim);
      if (v == null) return null;
      return EmbeddingVector(values: v, modelVersion: result.modelVersion);
    } on TimeoutException {
      unawaited(_host.cancel(id).catchError((Object _) {}));
      return null;
    } catch (_) {
      return null;
    }
  }
}
