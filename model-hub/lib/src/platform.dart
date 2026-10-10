import 'package:kernel_contracts/kernel_contracts.dart';

/// Device facts used to pick models. Nothing here leaves the phone.
class DeviceProfile {
  const DeviceProfile({
    required this.totalRamBytes,
    required this.sdkInt,
    this.socModel,
    this.socManufacturer,
    this.galleryVersionName,
  });

  final int totalRamBytes;
  final int sdkInt;

  /// Build.SOC_MODEL, e.g. 'SM8850' (iQOO 15). Null when unknown.
  final String? socModel;
  final String? socManufacturer;

  /// Installed AI Edge Gallery versionName, null when not installed.
  final String? galleryVersionName;

  /// Lower-case SoC key as used by Gallery's socToModelFiles.
  String? get socKey => socModel?.trim().toLowerCase();

  /// RAM in GB, rounded to the nearest GB (12 GB phones report ~11.2 GiB).
  double get ramGb => totalRamBytes / 1e9;
}

class NetworkStatus {
  const NetworkStatus({required this.connected, required this.unmetered});

  final bool connected;
  final bool unmetered;
}

class HubPaths {
  const HubPaths({required this.filesDir, this.modelsDir, this.legacyLlmDir});

  final String filesDir;
  final String? modelsDir;
  final String? legacyLlmDir;
}

class ModelFileInfo {
  const ModelFileInfo({
    required this.path,
    required this.sizeBytes,
    required this.modifiedMs,
  });

  final String path;
  final int sizeBytes;
  final int modifiedMs;
}

/// A policy-checked, pinned file to install.
class DownloadRequest {
  const DownloadRequest({
    required this.entry,
    required this.sha256,
    required this.wifiOnly,
  });

  final CatalogEntry entry;
  final String sha256;
  final bool wifiOnly;
}

/// Native side of the hub (Kotlin via pigeon on Android). Tests provide
/// their own implementation under test/.
abstract interface class HubPlatform {
  Future<DeviceProfile> device();
  Future<NetworkStatus> network();
  Future<HubPaths> paths();
  Future<List<ModelFileInfo>> listModelFiles();

  /// Cached by (path, size, mtime) natively; hashed once in the background.
  Future<String?> sha256Of(String path);
  Future<int> freeSpaceBytes();
  Future<ProvisionProgress> enqueue(DownloadRequest request);
  Future<void> cancel(String entryId);
  Future<bool> remove(String path);
  Future<List<ProvisionProgress>> activeDownloads();

  /// Download progress of every entry (broadcast).
  Stream<ProvisionProgress> progress();
}
