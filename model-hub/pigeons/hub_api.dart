// Pigeon definition for the model-hub Dart <-> Kotlin bridge.
//
// Regenerate after any change (from model-hub/):
//   dart run pigeon --input pigeons/hub_api.dart
//
// This bridge is internal to model-hub. The app only sees the contracts
// types (CatalogEntry, InstalledModel, ProvisionProgress, ...) through
// ModelHub.
//
// Network (guardrails §7): only the Kotlin downloader opens connections, and
// only to the pinned model file URL it is given (https, allow-listed hosts).
// No captured data (audio, images, prompts) ever crosses this bridge.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'model_hub',
    dartOut: 'lib/src/hub_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/kernel/model_hub/HubApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.kernel.model_hub',
      errorClassName: 'HubApiError',
    ),
  ),
)
/// Device facts used to pick models. Nothing here leaves the phone.
class NativeDeviceInfo {
  NativeDeviceInfo({
    required this.totalRamBytes,
    required this.sdkInt,
    this.socModel,
    this.socManufacturer,
    this.galleryVersionName,
  });

  int totalRamBytes;
  int sdkInt;

  /// Build.SOC_MODEL (API 31+), e.g. "SM8850". Null when unknown.
  String? socModel;
  String? socManufacturer;

  /// versionName of com.google.ai.edge.gallery, null when not installed.
  String? galleryVersionName;
}

class NativeNetworkState {
  NativeNetworkState({required this.connected, required this.unmetered});

  bool connected;
  bool unmetered;
}

class NativePaths {
  NativePaths({required this.filesDir, this.modelsDir, this.legacyLlmDir});

  /// App-private internal storage (catalog cache, consent, search index).
  String filesDir;

  /// getExternalFilesDir(null)/models, null when external storage is absent.
  String? modelsDir;

  /// getExternalFilesDir("llm"), scanned read-only for earlier imports.
  String? legacyLlmDir;
}

class NativeModelFile {
  NativeModelFile({
    required this.path,
    required this.sizeBytes,
    required this.modifiedMs,
  });

  String path;
  int sizeBytes;
  int modifiedMs;
}

/// One pinned file to install. Kotlin builds the target path itself from
/// repoId/revision/fileName and validates every segment.
class NativeDownloadRequest {
  NativeDownloadRequest({
    required this.entryId,
    required this.title,
    required this.url,
    required this.repoId,
    required this.revision,
    required this.fileName,
    required this.sha256,
    required this.sizeBytes,
    required this.wifiOnly,
  });

  String entryId;
  String title;
  String url;
  String repoId;
  String revision;
  String fileName;
  String sha256;
  int sizeBytes;
  bool wifiOnly;
}

enum NativeProvisionPhase {
  queued,
  waitingForWifi,
  waitingForSpace,
  downloading,
  verifying,
  installed,
  paused,
  failed,
}

class NativeProvisionProgress {
  NativeProvisionProgress({
    required this.entryId,
    required this.phase,
    required this.bytesDone,
    required this.totalBytes,
    this.error,
    this.path,
  });

  String entryId;
  NativeProvisionPhase phase;
  int bytesDone;
  int totalBytes;

  /// Technical reason (e.g. 'sha256_mismatch'); never file content.
  String? error;

  /// Final path once installed.
  String? path;
}

@HostApi()
abstract class ModelHubHostApi {
  NativeDeviceInfo deviceInfo();

  NativeNetworkState networkState();

  NativePaths paths();

  /// Model files under modelsDir and legacyLlmDir (.litertlm, .tflite,
  /// .task), excluding partial downloads.
  @async
  List<NativeModelFile> listModelFiles();

  /// sha256 of a model file, computed once on a background thread and cached
  /// by (path, size, mtime). Null when the file is outside model storage.
  @async
  String? sha256Of(String path);

  /// StorageManager.getAllocatableBytes for the models volume.
  @async
  int freeSpaceBytes();

  /// Schedules one unique job per entry (KEEP). Returns the current state.
  @async
  NativeProvisionProgress enqueue(NativeDownloadRequest request);

  void cancel(String entryId);

  /// Deletes a model file inside model storage. False when refused.
  @async
  bool remove(String path);

  /// Latest state of every queued, running or recently finished download.
  List<NativeProvisionProgress> activeDownloads();
}

@EventChannelApi()
abstract class ModelHubEvents {
  /// Download progress, throttled to about 4 events per second per entry.
  NativeProvisionProgress provisionProgress();
}
