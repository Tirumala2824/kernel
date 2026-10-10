import 'dart:typed_data';

import 'protocol.dart';

/// A u8 feature spectrogram around one event: dB above the noise floor in
/// 0.5 dB steps, column-major, lowest frequency first. Requested explicitly,
/// held in memory only, never persisted or uploaded (guardrails section 10).
/// It is not audio and cannot be played back.
class SensorSnippet {
  SensorSnippet._({
    required this.eventSeq,
    required this.rows,
    required this.cols,
    required this.fLoHz,
    required this.fHiHz,
    required this.colMs,
    required this.cells,
  });

  final int eventSeq;
  final int rows;
  final int cols;
  final double fLoHz;
  final double fHiHz;
  final double colMs;

  /// rows x cols bytes, column-major.
  final Uint8List cells;

  double dbAboveFloor(int row, int col) => cells[col * rows + row] / 2.0;

  /// Assembles tiles in any order; throws [ProtocolException] if any are missing.
  factory SensorSnippet.fromWire(Uint8List metaBytes, List<Uint8List> tiles) {
    final meta = SnippetMeta.decode(metaBytes);
    final cells = Uint8List(meta.rows * meta.cols);
    final seen = <int>{};
    for (final t in tiles.map(SnippetTile.decode)) {
      if (t.eventSeq != meta.eventSeq) continue;
      if (t.data.length != t.nCols * meta.rows || t.col0 + t.nCols > meta.cols) {
        throw ProtocolException('snippet tile ${t.tileIndex} has a bad size');
      }
      cells.setRange(t.col0 * meta.rows, (t.col0 + t.nCols) * meta.rows, t.data);
      seen.add(t.tileIndex);
    }
    if (seen.length != meta.tileCount) {
      throw ProtocolException('snippet ${meta.eventSeq}: ${seen.length} of ${meta.tileCount} tiles');
    }
    return SensorSnippet._(
      eventSeq: meta.eventSeq,
      rows: meta.rows,
      cols: meta.cols,
      fLoHz: meta.fLoHz10 * 10.0,
      fHiHz: meta.fHiHz10 * 10.0,
      colMs: meta.colDeciMs / 10.0,
      cells: cells,
    );
  }
}
