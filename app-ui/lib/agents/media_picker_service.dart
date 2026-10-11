import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

/// Session-only media. A native ownership token, never a path, permits deletion.
/// Photos carry bytes; WAVs reference a bounded app-private temporary import.
class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.fileName,
    required this.bytes,
    required this.mediaType,
    this.sensorType = SensorType.audioAir,
    this.sensorNodeId,
    this.visualSource = VisualMediaSource.galleryImage,
    this.ownershipToken,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
  final String mediaType; // 'audio' or 'image'
  final SensorType sensorType;
  final String? sensorNodeId;
  final VisualMediaSource visualSource;

  /// Opaque capability registered by native import, absent for external files.
  final String? ownershipToken;

  bool get isAudio => mediaType == 'audio';
  bool get isImage => mediaType == 'image';
}

/// Explicit photo or WAV selection; cancellation and failure stay distinct.
class MediaPickerService {
  MediaPickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  static const _mediaChannel = MethodChannel('com.kernel.sense_ai/chat_media');

  /// Idempotent: native code resolves only a registered token inside its own
  /// dedicated cache directory. Never delete [PickedMedia.path] in Dart.
  Future<void> release(PickedMedia? media) async {
    final token = media?.ownershipToken;
    if (token == null) return;
    await _releaseToken(token);
  }

  Future<void> _releaseToken(String token) async {
    try {
      await _mediaChannel.invokeMethod<void>('release', {'token': token});
    } on MissingPluginException {
      // Engine shutdown; the native owner and next safe startup also sweep.
    } on PlatformException {
      // Failed deletions remain registered natively for shutdown/startup retry.
    }
  }

  /// Android ACTION_OPEN_DOCUMENT selects one item. Native import enforces
  /// InsectWav.MAX_BYTES (6,000,000 bytes) before and during copying, including
  /// providers with unknown or dishonest lengths. No file_picker cache copy.
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) async {
    final result = await _mediaChannel.invokeMapMethod<String, dynamic>(
      'pickWav',
    );
    if (result == null) return null;
    final token = result['token'] as String?;
    try {
      final path = result['path'] as String?;
      final name = result['fileName'] as String?;
      if (path == null ||
          path.isEmpty ||
          token == null ||
          token.isEmpty ||
          name == null ||
          !RegExp(r'\.(wav|wave)$', caseSensitive: false).hasMatch(name)) {
        throw const FileSystemException(
          'Select a readable local WAV recording',
        );
      }
      return PickedMedia(
        path: path,
        fileName: name,
        bytes: Uint8List(0),
        mediaType: 'audio',
        sensorType: sensorType,
        sensorNodeId: sensorNodeId,
        ownershipToken: token,
      );
    } on Object {
      if (token != null) await _releaseToken(token);
      rethrow;
    }
  }

  /// Pick or take an image (camera or gallery).
  Future<PickedMedia?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    String? token;
    var readable = xFile;
    try {
      // Only the native owner can prove this is an ImagePicker cache copy.
      // Unknown/external paths stay read-only; do not infer ownership in Dart.
      Map<String, dynamic>? adopted;
      try {
        adopted = await _mediaChannel.invokeMapMethod<String, dynamic>(
          'adoptImagePickerCopy',
          {'path': xFile.path},
        );
      } on MissingPluginException {
        // Non-Android ImagePicker paths remain external/read-only.
      }
      if (adopted != null) {
        token = adopted['token'] as String;
        readable = XFile(adopted['path'] as String);
      }
      final length = await readable.length();
      if (length <= 0 || length > 12 * 1024 * 1024) {
        throw const FileSystemException(
          'Photo must be nonempty and at most 12 MB',
        );
      }
      final bytes = await readable.readAsBytes();
      if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
        throw const FileSystemException('Photo size changed while reading');
      }
      return PickedMedia(
        path: readable.path,
        fileName: xFile.name,
        bytes: bytes,
        mediaType: 'image',
        ownershipToken: token,
        visualSource: source == ImageSource.camera
            ? VisualMediaSource.phoneCamera
            : VisualMediaSource.galleryImage,
      );
    } on Object {
      if (token != null) await _releaseToken(token);
      rethrow;
    }
  }
}
