import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

/// A captured tile with its candidate and the best-matching card hint.
@immutable
class RankedTile {
  const RankedTile({
    required this.tile,
    required this.candidate,
    required this.hintCardId,
    required this.hintScore,
  });

  final ImageTile tile;
  final SignalCandidate? candidate;

  /// Zero-shot card hint: from the sense engine, or from the on-device
  /// embedder when the engine had none. Never a verdict.
  final String? hintCardId;
  final double hintScore;
}

/// Text that represents a card for embedding search.
String cardEmbeddingText(KnowledgeCard card) => [
  card.names['en'] ?? card.id,
  card.summary,
  ...card.signs,
].where((s) => s.trim().isNotEmpty).join('. ');

/// Orders tiles by embedding hint: tiles with a hint first (best score
/// first), then the rest by detector score. When a candidate has no hint
/// and [embedder] is available, the tile image is compared with the card
/// texts on the phone. Any embedder failure just leaves the hint empty.
Future<List<RankedTile>> rankTiles(
  CapturedStill still,
  List<SignalCandidate> candidates, {
  Embedder? embedder,
  List<KnowledgeCard> cards = const [],
}) async {
  final byId = {for (final c in candidates) c.id: c};
  Map<String, EmbeddingVector>? cardVectors;

  Future<Map<String, EmbeddingVector>> vectors() async {
    if (cardVectors != null) return cardVectors!;
    final out = <String, EmbeddingVector>{};
    for (final card in cards) {
      final v = await embedder!.embedText(
        cardEmbeddingText(card),
        task: EmbeddingTask.searchDocument,
      );
      if (v != null) out[card.id] = v;
    }
    return cardVectors = out;
  }

  var useEmbedder = false;
  if (embedder != null && cards.isNotEmpty) {
    try {
      useEmbedder = await embedder.isAvailable();
    } on Object {
      useEmbedder = false;
    }
  }

  final ranked = <RankedTile>[];
  for (final tile in still.tiles) {
    final candidate = byId[tile.candidateId];
    var hint = candidate?.hint;
    var score = hint == null ? 0.0 : candidate!.score;
    if (hint == null && useEmbedder) {
      try {
        final image = await embedder!.embedImage(tile.image);
        if (image != null) {
          for (final MapEntry(:key, :value) in (await vectors()).entries) {
            if (value.dim != image.dim) continue;
            final cos = image.cosine(value);
            if (hint == null || cos > score) {
              hint = key;
              score = cos;
            }
          }
        }
      } on Object catch (error) {
        debugPrint('Kernel: tile embedding unavailable: $error');
      }
    }
    ranked.add(
      RankedTile(
        tile: tile,
        candidate: candidate,
        hintCardId: hint,
        hintScore: score,
      ),
    );
  }
  ranked.sort((a, b) {
    final aHint = a.hintCardId != null;
    final bHint = b.hintCardId != null;
    if (aHint != bHint) return aHint ? -1 : 1;
    if (aHint) return b.hintScore.compareTo(a.hintScore);
    return (b.candidate?.score ?? 0).compareTo(a.candidate?.score ?? 0);
  });
  return ranked;
}
