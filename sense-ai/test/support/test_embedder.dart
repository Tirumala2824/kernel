// Test-only Embedder double: deterministic concept vectors, no model.
// Lives under test/ only; never reachable from the production graph.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

/// Text and "images" (UTF-8 bytes of a description) map to one-hot vectors
/// over [concepts]; an image mentioning two concepts gets a blend, so
/// similarities below 1 can be produced on purpose.
class TestEmbedder implements Embedder {
  TestEmbedder(this.concepts, {this.version = 'test-embed-1'});

  final List<String> concepts;
  String version;
  bool available = true;
  bool throwOnImage = false;

  /// Prompt texts for which embedText returns null.
  final Set<String> nullTexts = {};

  /// Overrides the model version of image vectors only.
  String? imageVersion;

  /// Overrides the dimension of image vectors only.
  int? imageDim;

  final List<String> textCalls = [];
  int imageCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> modelVersion() async => version;

  @override
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  }) async {
    textCalls.add(text);
    if (nullTexts.contains(text)) return null;
    return _vector(text, dim, version, unknownAxis: dim - 2);
  }

  @override
  Future<EmbeddingVector?> embedImage(
    Uint8List encodedImage, {
    int dim = 256,
  }) async {
    imageCalls++;
    if (throwOnImage) throw StateError('test embedder failure');
    return _vector(
      utf8.decode(encodedImage),
      imageDim ?? dim,
      imageVersion ?? version,
      unknownAxis: (imageDim ?? dim) - 1,
    );
  }

  @override
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256}) async =>
      null;

  EmbeddingVector _vector(
    String text,
    int dim,
    String modelVersion, {
    required int unknownAxis,
  }) {
    final v = Float32List(dim);
    var any = false;
    for (var i = 0; i < concepts.length && i < dim - 2; i++) {
      if (text.contains(concepts[i])) {
        v[i] = 1;
        any = true;
      }
    }
    // Unknown text and unknown images use different spare axes, so an
    // unrelated image is dissimilar (0) to every prompt.
    if (!any) v[unknownAxis] = 1;
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    for (var i = 0; i < dim; i++) {
      v[i] = v[i] / norm;
    }
    return EmbeddingVector(values: v, modelVersion: modelVersion);
  }
}

Uint8List bytesOf(String description) =>
    Uint8List.fromList(utf8.encode(description));
