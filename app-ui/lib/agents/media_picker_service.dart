import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

/// One picked media asset with path, raw bytes, and optional sensor metadata.
class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.fileName,
    required this.bytes,
    required this.mediaType,
    this.sensorType = SensorType.audioAir,
    this.sensorNodeId,
    this.visualSource = VisualMediaSource.galleryImage,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
  final String mediaType; // 'audio', 'image', 'video'
  final SensorType sensorType;
  final String? sensorNodeId;
  final VisualMediaSource visualSource;

  bool get isAudio => mediaType == 'audio';
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}

/// Unified media picker service for audio files, photos, and video keyframes.
class MediaPickerService {
  MediaPickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Pick an audio file (.wav) from device storage with sensor provenance.
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'wave', 'mp3', 'm4a', 'aac'],
      );

      if (result.isEmpty) return null;
      final file = result.first;
      final path = file.path ?? '';
      final bytes = path.isNotEmpty ? await File(path).readAsBytes() : Uint8List(0);

      return PickedMedia(
        path: path,
        fileName: file.name,
        bytes: bytes,
        mediaType: 'audio',
        sensorType: sensorType,
        sensorNodeId: sensorNodeId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pick or take an image (camera or gallery).
  Future<PickedMedia?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile == null) return null;
      final bytes = await xFile.readAsBytes();

      return PickedMedia(
        path: xFile.path,
        fileName: xFile.name,
        bytes: bytes,
        mediaType: 'image',
        visualSource: source == ImageSource.camera
            ? VisualMediaSource.phoneCamera
            : VisualMediaSource.galleryImage,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pick a video file from device storage or camera.
  Future<PickedMedia?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final xFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (xFile == null) return null;
      final bytes = await xFile.readAsBytes();

      return PickedMedia(
        path: xFile.path,
        fileName: xFile.name,
        bytes: bytes,
        mediaType: 'video',
        visualSource: VisualMediaSource.galleryVideo,
      );
    } catch (_) {
      return null;
    }
  }
}
