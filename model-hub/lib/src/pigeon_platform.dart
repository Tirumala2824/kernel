import 'package:kernel_contracts/kernel_contracts.dart';

import 'hub_api.g.dart';
import 'platform.dart';

/// [HubPlatform] over the pigeon bridge to the Kotlin side.
class PigeonHubPlatform implements HubPlatform {
  PigeonHubPlatform({ModelHubHostApi? api}) : _api = api ?? ModelHubHostApi();

  final ModelHubHostApi _api;
  Stream<ProvisionProgress>? _progress;

  @override
  Future<DeviceProfile> device() async {
    final d = await _api.deviceInfo();
    return DeviceProfile(
      totalRamBytes: d.totalRamBytes,
      sdkInt: d.sdkInt,
      socModel: d.socModel,
      socManufacturer: d.socManufacturer,
      galleryVersionName: d.galleryVersionName,
    );
  }

  @override
  Future<NetworkStatus> network() async {
    final n = await _api.networkState();
    return NetworkStatus(connected: n.connected, unmetered: n.unmetered);
  }

  @override
  Future<HubPaths> paths() async {
    final p = await _api.paths();
    return HubPaths(
      filesDir: p.filesDir,
      modelsDir: p.modelsDir,
      legacyLlmDir: p.legacyLlmDir,
    );
  }

  @override
  Future<List<ModelFileInfo>> listModelFiles() async {
    final files = await _api.listModelFiles();
    return [
      for (final f in files)
        ModelFileInfo(
          path: f.path,
          sizeBytes: f.sizeBytes,
          modifiedMs: f.modifiedMs,
        ),
    ];
  }

  @override
  Future<String?> sha256Of(String path) => _api.sha256Of(path);

  @override
  Future<int> freeSpaceBytes() => _api.freeSpaceBytes();

  @override
  Future<ProvisionProgress> enqueue(DownloadRequest request) async {
    final e = request.entry;
    final p = await _api.enqueue(
      NativeDownloadRequest(
        entryId: e.id,
        title: e.name,
        url: e.downloadUrl,
        repoId: e.repoId,
        revision: e.revision,
        fileName: e.fileName,
        sha256: request.sha256,
        sizeBytes: e.sizeBytes,
        wifiOnly: request.wifiOnly,
      ),
    );
    return _map(p);
  }

  @override
  Future<void> cancel(String entryId) => _api.cancel(entryId);

  @override
  Future<bool> remove(String path) => _api.remove(path);

  @override
  Future<List<ProvisionProgress>> activeDownloads() async =>
      [for (final p in await _api.activeDownloads()) _map(p)];

  @override
  Stream<ProvisionProgress> progress() =>
      _progress ??= provisionProgress().map(_map).asBroadcastStream();

  static ProvisionProgress _map(NativeProvisionProgress p) => ProvisionProgress(
    entryId: p.entryId,
    phase: switch (p.phase) {
      NativeProvisionPhase.queued => ProvisionPhase.queued,
      NativeProvisionPhase.waitingForWifi => ProvisionPhase.waitingForWifi,
      NativeProvisionPhase.waitingForSpace => ProvisionPhase.waitingForSpace,
      NativeProvisionPhase.downloading => ProvisionPhase.downloading,
      NativeProvisionPhase.verifying => ProvisionPhase.verifying,
      NativeProvisionPhase.installed => ProvisionPhase.installed,
      NativeProvisionPhase.paused => ProvisionPhase.paused,
      NativeProvisionPhase.failed => ProvisionPhase.failed,
    },
    bytesDone: p.bytesDone,
    totalBytes: p.totalBytes,
    error: p.error,
  );
}
