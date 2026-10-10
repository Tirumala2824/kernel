// Test-only media builders (headers only; nothing real is captured).
// Lives under test/ only.
import 'dart:typed_data';

/// PNG signature plus a few bytes: enough for the header checks.
Uint8List pngBytes() => Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, //
]);

/// JPEG SOI + APP0 marker start.
Uint8List jpegBytes() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 0x4A, 0x46]);

/// RIFF WAV header with [seconds] of silence (PCM16).
Uint8List wavBytes({
  double seconds = 1,
  int sampleRate = 16000,
  int channels = 1,
  int bits = 16,
  int format = 1,
}) {
  final bytesPerSample = bits ~/ 8;
  final dataBytes = (seconds * sampleRate).round() * channels * bytesPerSample;
  final b = ByteData(44 + dataBytes);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  b.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, format, Endian.little);
  b.setUint16(22, channels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  b.setUint16(32, channels * bytesPerSample, Endian.little);
  b.setUint16(34, bits, Endian.little);
  ascii(36, 'data');
  b.setUint32(40, dataBytes, Endian.little);
  return b.buffer.asUint8List();
}
