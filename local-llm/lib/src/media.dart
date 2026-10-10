// In-memory media checks for the Pest ID path. Pure Dart, header bytes
// only: nothing is decoded, written or logged.
import 'dart:typed_data';

/// Largest encoded image passed to the on-device model (matches Kotlin).
const int maxImageBytes = 8 * 1024 * 1024;

/// Longest clip passed to the on-device model (guardrails §8 amendment).
const int maxClipSeconds = 30;

bool isPng(Uint8List b) =>
    b.length >= 8 &&
    b[0] == 0x89 &&
    b[1] == 0x50 &&
    b[2] == 0x4E &&
    b[3] == 0x47 &&
    b[4] == 0x0D &&
    b[5] == 0x0A &&
    b[6] == 0x1A &&
    b[7] == 0x0A;

bool isJpeg(Uint8List b) =>
    b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

/// PNG or JPEG within [maxImageBytes].
bool isUsableImage(Uint8List? b) =>
    b != null && b.length <= maxImageBytes && (isPng(b) || isJpeg(b));

/// Format fields of a RIFF WAV header.
class WavInfo {
  const WavInfo({
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.audioFormat,
    required this.dataBytes,
  });

  final int channels;
  final int sampleRate;
  final int bitsPerSample;

  /// 1 = PCM.
  final int audioFormat;
  final int dataBytes;

  Duration get duration {
    final bytesPerSecond = sampleRate * channels * (bitsPerSample ~/ 8);
    if (bytesPerSecond <= 0) return Duration.zero;
    return Duration(microseconds: dataBytes * 1000000 ~/ bytesPerSecond);
  }
}

/// Parses the RIFF chunks up to `data`. Null when this is not a WAV file.
WavInfo? parseWav(Uint8List b) {
  if (b.length < 12) return null;
  if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
    return null;
  }
  final view = ByteData.sublistView(b);
  var offset = 12;
  int? channels, rate, bits, format;
  while (offset + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(offset, offset + 4));
    final size = view.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      if (size < 16 || body + 16 > b.length) return null;
      format = view.getUint16(body, Endian.little);
      channels = view.getUint16(body + 2, Endian.little);
      rate = view.getUint32(body + 4, Endian.little);
      bits = view.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (channels == null || rate == null || bits == null || format == null) {
        return null;
      }
      final available = b.length - body;
      return WavInfo(
        channels: channels,
        sampleRate: rate,
        bitsPerSample: bits,
        audioFormat: format,
        dataBytes: size < available ? size : available,
      );
    }
    // Chunks are padded to an even size.
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  return null;
}

/// RIFF WAV, PCM, mono, 16 kHz, 16-bit, non-empty and at most
/// [maxClipSeconds] long: the only clip format the Pest ID path accepts.
bool isUsableClip(Uint8List? b) {
  if (b == null) return false;
  final w = parseWav(b);
  return w != null &&
      w.audioFormat == 1 &&
      w.channels == 1 &&
      w.sampleRate == 16000 &&
      w.bitsPerSample == 16 &&
      w.dataBytes > 0 &&
      w.duration <= const Duration(seconds: maxClipSeconds);
}
