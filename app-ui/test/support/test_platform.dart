// Test-only doubles for the app-shell platform services.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kernel_app/app/platform_providers.dart';

class ScriptedPermissions implements DevicePermissions {
  ScriptedPermissions({
    this.microphone = PermissionAccess.granted,
    this.camera = PermissionAccess.granted,
    this.afterRequest,
  });

  PermissionAccess microphone;
  PermissionAccess camera;

  /// Result of a mic request; defaults to the current [microphone] status.
  PermissionAccess? afterRequest;
  int micRequests = 0;
  int cameraRequests = 0;
  int notificationRequests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionAccess> microphoneStatus() async => microphone;

  @override
  Future<PermissionAccess> requestMicrophone() async {
    micRequests++;
    microphone = afterRequest ?? microphone;
    return microphone;
  }

  @override
  Future<PermissionAccess> requestNotifications() async {
    notificationRequests++;
    return PermissionAccess.granted;
  }

  @override
  Future<PermissionAccess> cameraStatus() async => camera;

  @override
  Future<PermissionAccess> requestCamera() async {
    cameraRequests++;
    return camera;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class RecordingSharer implements ReportSharer {
  final shared = <String>[];

  @override
  Future<void> shareFile(String path, {required String subject}) async {
    shared.add(path);
  }
}

class RecordingVoicePrompter implements VoicePrompter {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stops++;
}

/// Returns fixed app-private paths instead of opening the camera.
class ScriptedPhotoStore implements PhotoStore {
  final captured = <PhotoSource>[];
  final discarded = <String>[];
  int _n = 0;

  @override
  Future<String?> capture(PhotoSource source) async {
    captured.add(source);
    return '/data/user/0/com.kernel.kernel_app/app_flutter/'
        'inspection_photos/photo_${++_n}.jpg';
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

/// Stands in for the camera preview: one button per scripted payload.
class ScriptedQrScanner {
  ScriptedQrScanner({this.payloads = const []});

  List<String> payloads;

  Widget build(BuildContext context, ValueChanged<String> onPayload) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, payload) in payloads.indexed)
        TextButton(
          key: Key('qr-payload-$i'),
          onPressed: () => onPayload(payload),
          child: Text('payload $i'),
        ),
    ],
  );
}

/// 1x1 transparent PNG so photo thumbnails never touch the file system.
final transparentPixel = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);
