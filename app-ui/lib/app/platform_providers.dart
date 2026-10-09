import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

// App-shell platform services (not domain contracts). Each sits behind a
// small interface so widget tests can bind test doubles under test/.

// ---------------------------------------------------------------------------
// Connectivity (informational only; no core flow needs the network).

final connectivityResultsProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = Connectivity();
  try {
    yield await connectivity.checkConnectivity();
  } on Object {
    // Unknown state: the indicator simply stays hidden.
  }
  yield* connectivity.onConnectivityChanged.handleError((Object _) {});
}, name: 'connectivityResultsProvider');

/// True when the device has no network, null while unknown.
final isOfflineProvider = Provider<bool?>((ref) {
  final results = ref.watch(connectivityResultsProvider).value;
  if (results == null) return null;
  return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
}, name: 'isOfflineProvider');

// ---------------------------------------------------------------------------
// Runtime permissions.

enum PermissionAccess { granted, denied, permanentlyDenied, restricted }

abstract interface class DevicePermissions {
  Future<PermissionAccess> microphoneStatus();
  Future<PermissionAccess> requestMicrophone();

  /// Android 13+ notification permission for on-device reminders.
  Future<PermissionAccess> requestNotifications();
  Future<bool> openSettings();
}

class PermissionHandlerDevicePermissions implements DevicePermissions {
  const PermissionHandlerDevicePermissions();

  static PermissionAccess _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return PermissionAccess.granted;
    }
    if (status.isPermanentlyDenied) return PermissionAccess.permanentlyDenied;
    if (status.isRestricted) return PermissionAccess.restricted;
    return PermissionAccess.denied;
  }

  @override
  Future<PermissionAccess> microphoneStatus() async =>
      _map(await Permission.microphone.status);

  @override
  Future<PermissionAccess> requestMicrophone() async =>
      _map(await Permission.microphone.request());

  @override
  Future<PermissionAccess> requestNotifications() async =>
      _map(await Permission.notification.request());

  @override
  Future<bool> openSettings() => openAppSettings();
}

final devicePermissionsProvider = Provider<DevicePermissions>(
  (ref) => const PermissionHandlerDevicePermissions(),
  name: 'devicePermissionsProvider',
);

// ---------------------------------------------------------------------------
// Sharing exported reports (the file is already in app-private storage).

abstract interface class ReportSharer {
  Future<void> shareFile(String path, {required String subject});
}

class SharePlusReportSharer implements ReportSharer {
  const SharePlusReportSharer();

  @override
  Future<void> shareFile(String path, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject, title: subject),
    );
  }
}

final reportSharerProvider = Provider<ReportSharer>(
  (ref) => const SharePlusReportSharer(),
  name: 'reportSharerProvider',
);

// ---------------------------------------------------------------------------
// Scan feedback hooks (haptics now; sound/TTS can be added later).

abstract interface class ScanFeedback {
  Future<void> captureStarted();
  Future<void> captureFinished(ScanQuality quality);
}

class HapticScanFeedback implements ScanFeedback {
  const HapticScanFeedback();

  @override
  Future<void> captureStarted() => HapticFeedback.mediumImpact();

  @override
  Future<void> captureFinished(ScanQuality quality) =>
      quality == ScanQuality.pass
      ? HapticFeedback.lightImpact()
      : HapticFeedback.heavyImpact();
}

final scanFeedbackProvider = Provider<ScanFeedback>(
  (ref) => const HapticScanFeedback(),
  name: 'scanFeedbackProvider',
);
