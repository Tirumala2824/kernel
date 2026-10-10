import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

/// A zero-shot text prompt for Stage 1. [id] becomes the candidate hint.
/// Background prompts describe ordinary scenes: a tile whose best match is
/// a background prompt gives no candidate.
class SignPrompt {
  const SignPrompt(this.id, this.text, {this.background = false});

  final String id;
  final String text;
  final bool background;
}

/// Pest-sign prompts (stable snake_case ids) plus a few background ones.
const List<SignPrompt> defaultSignPrompts = [
  SignPrompt('rodent_droppings', 'mouse droppings on a floor'),
  SignPrompt('rat_droppings', 'rat droppings near a wall'),
  SignPrompt('rodent', 'a mouse or a rat'),
  SignPrompt('gnaw_marks', 'gnaw marks on wood or a food packet'),
  SignPrompt('cockroach', 'a cockroach'),
  SignPrompt(
    'cockroach_droppings',
    'cockroach droppings like black pepper specks',
  ),
  SignPrompt('gecko', 'a gecko on a wall'),
  SignPrompt('lizard', 'a lizard'),
  SignPrompt('spider', 'a spider'),
  SignPrompt('spider_web', 'a spider web in a corner'),
  SignPrompt('scorpion', 'a scorpion'),
  SignPrompt('termite_mud_tube', 'a termite mud tube on a wall'),
  SignPrompt('termite_damage', 'termite damage in wood'),
  SignPrompt('ant_trail', 'a trail of ants'),
  SignPrompt('bed_bug', 'a bed bug on fabric'),
  SignPrompt('mosquito', 'a mosquito'),
  SignPrompt('house_fly', 'a house fly'),
  SignPrompt('stored_grain_beetle', 'small beetles in stored grain'),
  SignPrompt('grain_moth_webbing', 'moth webbing in stored grain or flour'),
  SignPrompt('snake', 'a snake'),
  SignPrompt('plain_floor', 'a clean empty floor', background: true),
  SignPrompt('plain_wall', 'a plain painted wall', background: true),
  SignPrompt(
    'household_object',
    'an ordinary household object',
    background: true,
  ),
];

class SignMatch {
  const SignMatch(this.prompt, this.similarity);

  final SignPrompt prompt;

  /// Cosine similarity of the image and prompt embeddings. Not calibrated.
  final double similarity;
}

/// Stage 1: zero-shot ranking of still tiles against [prompts] with an
/// injected on-device [Embedder] (text and image vectors must share one
/// space). Prompt vectors are cached per embedder model version.
///
/// Every tile gives at most one [SignalCandidate] of kind
/// [SignalKind.embeddingMatch], with `hint` = prompt id and `score` = the
/// cosine similarity clamped to 0..1. Never throws; an unavailable embedder
/// gives no candidates.
class SignRanker {
  SignRanker(
    this._embedder, {
    this.prompts = defaultSignPrompts,
    this.dim = 256,
    this.minSimilarity = 0.2,
    this.textTask = EmbeddingTask.searchQuery,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Embedder _embedder;
  final List<SignPrompt> prompts;

  /// Matryoshka dimension: 128, 256, 512 or 768.
  final int dim;

  /// Below this similarity a tile gives no candidate. Needs calibration on
  /// device with the chosen embedder.
  final double minSimilarity;
  final EmbeddingTask textTask;
  final DateTime Function() _clock;

  Map<String, EmbeddingVector> _textVectors = const {};
  String? _cachedVersion;
  Future<Map<String, EmbeddingVector>>? _preparing;

  /// Drops cached prompt vectors (e.g. after the embedder model changed).
  void clearCache() {
    _textVectors = const {};
    _cachedVersion = null;
  }

  /// All prompts scored against [encodedImage] (PNG or JPEG), best first.
  /// Empty when the embedder is unavailable or the vectors do not match.
  Future<List<SignMatch>> scoreImage(Uint8List encodedImage) async {
    final text = await _vectors();
    return _score(encodedImage, text);
  }

  Future<SignalCandidate?> rankTile(ImageTile tile) async {
    final text = await _vectors();
    return _candidate(tile, await _score(tile.image, text));
  }

  /// One candidate per tile whose best prompt is a sign above
  /// [minSimilarity], in tile order.
  Future<List<SignalCandidate>> rankTiles(List<ImageTile> tiles) async {
    if (tiles.isEmpty) return const [];
    final text = await _vectors();
    if (text.isEmpty) return const [];
    final out = <SignalCandidate>[];
    for (final tile in tiles) {
      final c = _candidate(tile, await _score(tile.image, text));
      if (c != null) out.add(c);
    }
    return out;
  }

  SignalCandidate? _candidate(ImageTile tile, List<SignMatch> matches) {
    if (matches.isEmpty) return null;
    final best = matches.first;
    if (best.prompt.background || best.similarity < minSimilarity) return null;
    return SignalCandidate(
      id: 'sign:${tile.candidateId}',
      source: SignalSource.camera,
      kind: SignalKind.embeddingMatch,
      score: best.similarity.clamp(0.0, 1.0).toDouble(),
      detectedAt: _clock(),
      box: tile.box,
      hint: best.prompt.id,
    );
  }

  Future<List<SignMatch>> _score(
    Uint8List image,
    Map<String, EmbeddingVector> text,
  ) async {
    if (text.isEmpty) return const [];
    EmbeddingVector? v;
    try {
      v = await _embedder.embedImage(image, dim: dim);
    } catch (_) {
      return const [];
    }
    if (v == null) return const [];
    final out = <SignMatch>[];
    for (final p in prompts) {
      final t = text[p.id];
      // Vectors from different models or sizes are not comparable.
      if (t == null || t.dim != v.dim || t.modelVersion != v.modelVersion) {
        continue;
      }
      out.add(SignMatch(p, v.cosine(t)));
    }
    out.sort((a, b) => b.similarity.compareTo(a.similarity));
    return out;
  }

  Future<Map<String, EmbeddingVector>> _vectors() async {
    String? version;
    try {
      if (!await _embedder.isAvailable()) return const {};
      version = await _embedder.modelVersion();
    } catch (_) {
      return const {};
    }
    if (version != _cachedVersion) {
      _textVectors = const {};
      _cachedVersion = version;
    }
    if (_textVectors.length == prompts.length) return _textVectors;
    final pending = _preparing ??= _prepare(version);
    try {
      return await pending;
    } finally {
      if (identical(_preparing, pending)) _preparing = null;
    }
  }

  Future<Map<String, EmbeddingVector>> _prepare(String? version) async {
    final out = Map<String, EmbeddingVector>.of(_textVectors);
    for (final p in prompts) {
      if (out.containsKey(p.id)) continue;
      try {
        final v = await _embedder.embedText(p.text, task: textTask, dim: dim);
        if (v != null) out[p.id] = v;
      } catch (_) {
        // Missing prompts are retried on the next call.
      }
    }
    if (version == _cachedVersion) _textVectors = Map.unmodifiable(out);
    return out;
  }
}
