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
    var dot = 0.0;
    for (var i = 0; i < dim; i++) {
      dot += values[i] * other.values[i];
    }
    return dot;
  }
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
