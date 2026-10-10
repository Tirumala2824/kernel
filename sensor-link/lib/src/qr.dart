import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

/// Thrown for a malformed node QR label. [reason] is one of: empty, prefix,
/// version, fields, address, keyEncoding, keyLength, type.
class SensorQrFormatException extends FormatException {
  SensorQrFormatException(this.reason) : super('invalid sensor QR label: $reason');
  final String reason;
}

/// Parsed `kernel:sensor:v1:<AA:BB:CC:DD:EE:FF>:<base64url key>:<type>`
/// (docs/sensor-protocol.md section 7). Mirrors QrLabel.kt.
///
/// The Dart side only validates the label: the key is handed to Kotlin once,
/// imported into Android Keystore there and never stored by Dart.
class SensorQrLabel {
  const SensorQrLabel._(this.address, this.keyLength, this.type);

  final String address;
  final int keyLength;
  final SensorType type;

  static const _types = {
    'us_air': SensorType.usAir,
    'contact_piezo': SensorType.contactPiezo,
    'contact_accel': SensorType.contactAccel,
    'audio_air': SensorType.audioAir,
  };
  static final _hex2 = RegExp(r'^[0-9A-Fa-f]{2}$');

  static SensorQrLabel parse(String payload) => _parse(payload).$1;

  /// Parses and also returns the decoded key bytes (tests and fingerprinting only).
  static (SensorQrLabel, Uint8List) parseWithKey(String payload) => _parse(payload);

  static (SensorQrLabel, Uint8List) _parse(String payload) {
    if (payload.isEmpty) throw SensorQrFormatException('empty');
    final parts = payload.split(':');
    if (parts.length < 3 || parts[0] != 'kernel' || parts[1] != 'sensor') {
      throw SensorQrFormatException('prefix');
    }
    if (parts[2] != 'v1') throw SensorQrFormatException('version');
    if (parts.length != 11) throw SensorQrFormatException('fields');
    final octets = parts.sublist(3, 9);
    if (!octets.every(_hex2.hasMatch)) throw SensorQrFormatException('address');
    final address = octets.map((o) => o.toUpperCase()).join(':');
    final key = base64UrlDecodeStrict(parts[9]);
    if (key == null) throw SensorQrFormatException('keyEncoding');
    if (key.length != 32) throw SensorQrFormatException('keyLength');
    final type = _types[parts[10]];
    if (type == null) throw SensorQrFormatException('type');
    return (SensorQrLabel._(address, key.length, type), key);
  }
}

/// RFC 4648 section 5 base64url with optional padding; rejects non-canonical input.
Uint8List? base64UrlDecodeStrict(String text) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  var s = text;
  while (s.endsWith('=')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.length % 4 == 1) return null;
  final out = BytesBuilder(copy: false);
  var acc = 0;
  var bits = 0;
  for (final ch in s.split('')) {
    final v = alphabet.indexOf(ch);
    if (v < 0) return null;
    acc = ((acc << 6) | v) & 0xFFFFFF;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.addByte((acc >> bits) & 0xFF);
    }
  }
  if (bits > 0 && (acc & ((1 << bits) - 1)) != 0) return null;
  return out.toBytes();
}
