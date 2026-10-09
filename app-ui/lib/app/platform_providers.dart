import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Camera, for QR sack labels and inspection photos.
  Future<PermissionAccess> cameraStatus();
  Future<PermissionAccess> requestCamera();
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
  Future<PermissionAccess> cameraStatus() async =>
      _map(await Permission.camera.status);

  @override
  Future<PermissionAccess> requestCamera() async =>
      _map(await Permission.camera.request());

  @override
  Future<bool> openSettings() => openAppSettings();
}

final devicePermissionsProvider = Provider<DevicePermissions>(
  (ref) => const PermissionHandlerDevicePermissions(),
  name: 'devicePermissionsProvider',
);

// ---------------------------------------------------------------------------
// Sharing exported files (already written to app-private storage). The
// user picks the destination in the system share sheet; the app itself
// never uploads anything.

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
// Spoken scan prompts (off by default). Uses the phone's own text-to-speech
// engine with an installed, offline voice only; if none is installed the
// prompt is skipped silently rather than reaching for a network voice.

abstract interface class VoicePrompter {
  /// Speaks [text] in [languageTag] and completes when speech has finished.
  Future<void> speak(String text, {required String languageTag});
  Future<void> stop();
}

class SystemTtsVoicePrompter implements VoicePrompter {
  SystemTtsVoicePrompter();

  final FlutterTts _tts = FlutterTts();
  String? _configuredFor;
  bool _usable = false;

  Future<void> _configure(String languageTag) async {
    if (_configuredFor == languageTag) return;
    _configuredFor = languageTag;
    _usable = false;
    try {
      await _tts.awaitSpeakCompletion(true);
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final lang = languageTag.toLowerCase();
      // Installed voices for this language that synthesise on the phone.
      final offline = voices
          .whereType<Map<Object?, Object?>>()
          .where((v) {
            final locale = '${v['locale']}'.toLowerCase();
            return (locale == lang || locale.startsWith('$lang-')) &&
                '${v['network_required']}' == '0' &&
                !'${v['features']}'.split('\t').contains('notInstalled');
          })
          .toList();
      if (offline.isEmpty) return;
      // Prefer an Indian variant (en-IN, hi-IN, ...) when one is installed.
      final voice =
          offline
              .where((v) => '${v['locale']}'.toUpperCase().endsWith('-IN'))
              .firstOrNull ??
          offline.first;
      await _tts.setVoice({
        'name': '${voice['name']}',
        'locale': '${voice['locale']}',
      });
      await _tts.setSpeechRate(0.45);
      _usable = true;
    } on Object catch (error) {
      debugPrint('Kernel: voice prompts unavailable: $error');
    }
  }

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    await _configure(languageTag);
    if (!_usable) return;
    try {
      await _tts.speak(text);
    } on Object catch (error) {
      debugPrint('Kernel: voice prompt failed: $error');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // Nothing to stop.
    }
  }
}

final voicePrompterProvider = Provider<VoicePrompter>(
  (ref) => SystemTtsVoicePrompter(),
  name: 'voicePrompterProvider',
);

// ---------------------------------------------------------------------------
// Inspection evidence photos, copied into app-private documents storage
// under inspection_photos/. Never uploaded.

enum PhotoSource { camera, gallery }

abstract interface class PhotoStore {
  /// Lets the user take or pick a photo and returns its app-private path,
  /// or null when cancelled.
  Future<String?> capture(PhotoSource source);

  /// Deletes a photo that was captured but not saved with an inspection.
  Future<void> discard(String path);
}

class ImagePickerPhotoStore implements PhotoStore {
  ImagePickerPhotoStore();

  final ImagePicker _picker = ImagePicker();
  int _sequence = 0;

  @override
  Future<String?> capture(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/inspection_photos');
    await dir.create(recursive: true);
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final dest = '${dir.path}/photo_${stamp}_${_sequence++}.jpg';
    await File(picked.path).copy(dest);
    // Remove the picker's temporary copy from the cache.
    try {
      await File(picked.path).delete();
    } on Object {
      // The picker may already have cleaned it up.
    }
    return dest;
  }

  @override
  Future<void> discard(String path) async {
    try {
      await File(path).delete();
    } on Object {
      // Already gone.
    }
  }
}

final photoStoreProvider = Provider<PhotoStore>(
  (ref) => ImagePickerPhotoStore(),
  name: 'photoStoreProvider',
);

/// Builds an evidence photo thumbnail. Tests replace it so no file IO runs.
typedef PhotoImageBuilder = ImageProvider Function(String path);

final photoImageProvider = Provider<PhotoImageBuilder>(
  (ref) =>
      (path) => ResizeImage(FileImage(File(path)), width: 360),
  name: 'photoImageProvider',
);

// ---------------------------------------------------------------------------
// QR scanning. The live camera view is behind a builder so tests can
// deliver payloads without a camera.

typedef QrScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onPayload);

final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) =>
      (context, onPayload) => MobileScannerQrView(onPayload: onPayload),
  name: 'qrScannerBuilderProvider',
);

/// Camera preview that reports QR payloads (bundled ML Kit model).
class MobileScannerQrView extends StatefulWidget {
  const MobileScannerQrView({super.key, required this.onPayload});

  final ValueChanged<String> onPayload;

  @override
  State<MobileScannerQrView> createState() => _MobileScannerQrViewState();
}

class _MobileScannerQrViewState extends State<MobileScannerQrView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final code in capture.barcodes) {
          final raw = code.rawValue;
          if (raw != null) {
            widget.onPayload(raw);
            return;
          }
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// App version for the diagnostics device-log row.

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } on Object {
    return 'unknown';
  }
}, name: 'appVersionProvider');
