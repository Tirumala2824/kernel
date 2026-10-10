import 'dart:typed_data';

// On-device embeddings (EmbeddingGemma via LiteRT-LM) and model-header
// probing. Inputs stay on the phone.

enum EmbeddingTask { searchQuery, searchDocument, classification, similarity }

class EmbeddingVector {
  const EmbeddingVector({required this.values, required this.modelVersion});

  /// L2-normalised (re-normalised after Matryoshka truncation).
  final Float32List values;
  final String modelVersion;

  int get dim => values.length;

  double cosine(EmbeddingVector other) {
    if (other.dim != dim) {
      throw ArgumentError('dimension mismatch: $dim vs ${other.dim}');
    }
    return cosineSimilarityFloat32(values, other.values);
  }
}

/// Standard stop words for search index tokenization across the platform.
const standardStopWords = <String>{
  'a', 'an', 'and', 'the', 'for', 'of', 'to', 'in', 'on', 'with', 'is',
  'model', 'models', 'that', 'this', 'it', 'by', 'or', 'up',
};

/// Splits text into clean lowercase search tokens, filtering out stop words.
List<String> tokenizeText(String s) => [
  for (final t in s.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
    if (t.length > 1 && !standardStopWords.contains(t)) t,
];

/// Computes cosine similarity between two Float32 lists.
double cosineSimilarityFloat32(Float32List a, Float32List b) {
  if (a.length != b.length) {
    throw ArgumentError('Vector dimension mismatch: ${a.length} vs ${b.length}');
  }
  var dot = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}

/// Never throws for model problems: returns null (no model, busy, failed).
abstract interface class Embedder {
  Future<bool> isAvailable();
  Future<String?> modelVersion();

  /// [dim] is a Matryoshka size: 128, 256, 512 or 768.
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  });

  /// [encodedImage] is PNG or JPEG bytes.
  Future<EmbeddingVector?> embedImage(Uint8List encodedImage, {int dim = 256});

  /// [wav] is RIFF WAV, mono, 16 kHz, 16-bit PCM.
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256});
}

enum ProbedKind { llm, embedding, unknown }

class ModelProbeResult {
  const ModelProbeResult({
    required this.kind,
    required this.inputModalities,
    required this.backends,
    this.maxContextTokens,
    this.embeddingDim,
    this.socName,
    this.npuBrand,
  });

  final ProbedKind kind;

  /// Subset of {'text', 'vision', 'audio', 'video'}.
  final Set<String> inputModalities;
  final List<String> backends;
  final int? maxContextTokens;
  final int? embeddingDim;
  final String? socName;
  final String? npuBrand;
}

/// Reads a model file header without loading weights (LiteRT-LM ModelInfo).
abstract interface class ModelProbe {
  /// Null when the file is not a readable LiteRT-LM model.
  Future<ModelProbeResult?> probe(String absolutePath);
}
