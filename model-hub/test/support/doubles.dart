// Test doubles for model_hub (test/ only). No network: HTTP answers are
// scripted per URL and every request is recorded.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';

class FileAssets implements CatalogAssets {
  @override
  String get snapshotVersion => '1_0_20';

  @override
  Future<String> kernelCatalog() =>
      File('assets/kernel_catalog.json').readAsString();

  @override
  Future<String> gallerySnapshot() =>
      File('assets/gallery_allowlist_1_0_20.json').readAsString();
}

String readAsset(String name) => File('assets/$name').readAsStringSync();

class ScriptedPlatform implements HubPlatform {
  DeviceProfile deviceProfile = const DeviceProfile(
    totalRamBytes: 11500000000,
    sdkInt: 36,
    socModel: 'SM8850',
    socManufacturer: 'QTI',
    galleryVersionName: '1.0.20',
  );
  NetworkStatus net = const NetworkStatus(connected: true, unmetered: true);
  HubPaths hubPaths = const HubPaths(filesDir: '/data/files');
  final files = <ModelFileInfo>[];
  final shas = <String, String>{};
  final shaCalls = <String>[];
  int listCalls = 0;
  int free = 100000000000;
  final enqueued = <DownloadRequest>[];
  final cancelled = <String>[];
  final removed = <String>[];
  ProvisionProgress Function(DownloadRequest r)? onEnqueue;
  final progressCtl = StreamController<ProvisionProgress>.broadcast();

  void addFile(String path, int size, String sha, {int mtime = 1000}) {
    files.add(ModelFileInfo(path: path, sizeBytes: size, modifiedMs: mtime));
    shas[path] = sha;
  }

  @override
  Future<DeviceProfile> device() async => deviceProfile;

  @override
  Future<NetworkStatus> network() async => net;

  @override
  Future<HubPaths> paths() async => hubPaths;

  @override
  Future<List<ModelFileInfo>> listModelFiles() async {
    listCalls++;
    return List.of(files);
  }

  @override
  Future<String?> sha256Of(String path) async {
    shaCalls.add(path);
    return shas[path];
  }

  @override
  Future<int> freeSpaceBytes() async => free;

  @override
  Future<ProvisionProgress> enqueue(DownloadRequest request) async {
    enqueued.add(request);
    return onEnqueue?.call(request) ??
        ProvisionProgress(
          entryId: request.entry.id,
          phase: ProvisionPhase.queued,
          bytesDone: 0,
          totalBytes: request.entry.sizeBytes,
        );
  }

  @override
  Future<void> cancel(String entryId) async => cancelled.add(entryId);

  @override
  Future<bool> remove(String path) async {
    removed.add(path);
    files.removeWhere((f) => f.path == path);
    return true;
  }

  @override
  Future<List<ProvisionProgress>> activeDownloads() async => const [];

  @override
  Stream<ProvisionProgress> progress() => progressCtl.stream;
}

typedef HttpHandler =
    HubHttpResponse? Function(Uri uri, Map<String, String> headers);

/// Scripted catalog transport; unknown URLs answer 404.
class RecordingHttp implements HubHttp {
  RecordingHttp([this.handler]);

  HttpHandler? handler;
  final requests = <(Uri, Map<String, String>)>[];

  List<Uri> get uris => [for (final r in requests) r.$1];

  @override
  Future<HubHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    requests.add((uri, headers));
    return handler?.call(uri, headers) ??
        HubHttpResponse(status: 404, headers: const {}, body: '');
  }
}

HubHttpResponse ok(String body, [Map<String, String> headers = const {}]) =>
    HubHttpResponse(status: 200, headers: headers, body: body);

/// Returns header results per path and counts calls.
class HeaderProbe implements ModelProbe {
  final results = <String, ModelProbeResult?>{};
  final calls = <String>[];

  @override
  Future<ModelProbeResult?> probe(String absolutePath) async {
    calls.add(absolutePath);
    return results[absolutePath];
  }
}

/// Deterministic bag-of-words embedder: tokens hashed into [dim] buckets,
/// L2-normalised. Good enough to check ranking, caching and fallbacks.
class BagOfWordsEmbedder implements Embedder {
  String version = 'bow-1';
  bool available = true;
  final calls = <(String, EmbeddingTask)>[];

  int get documentCalls =>
      calls.where((c) => c.$2 == EmbeddingTask.searchDocument).length;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> modelVersion() async => available ? version : null;

  @override
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  }) async {
    if (!available) return null;
    calls.add((text, task));
    final v = Float32List(dim);
    for (final t in text.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
      if (t.length < 3) continue;
      final stem = t.length > 5 ? t.substring(0, 5) : t;
      var h = 0x811c9dc5;
      for (final c in stem.codeUnits) {
        h = ((h ^ c) * 0x01000193) & 0xffffffff;
      }
      v[h % dim] += 1;
    }
    var n = 0.0;
    for (final x in v) {
      n += x * x;
    }
    if (n == 0) return null;
    final inv = 1 / math.sqrt(n);
    for (var i = 0; i < dim; i++) {
      v[i] = v[i] * inv;
    }
    return EmbeddingVector(values: v, modelVersion: version);
  }


  @override
  Future<EmbeddingVector?> embedImage(
    Uint8List encodedImage, {
    int dim = 256,
  }) async => null;

  @override
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256}) async =>
      null;
}

/// HF revision API body shaped like the real response.
String revisionBody({
  required String id,
  required String sha,
  Object gated = false,
  String license = 'apache-2.0',
  required Map<String, (int, String?)> files,
}) {
  final siblings = [
    for (final f in files.entries)
      '{"rfilename":"${f.key}","size":${f.value.$1}'
          '${f.value.$2 == null ? '' : ',"lfs":{"sha256":"${f.value.$2}","size":${f.value.$1},"pointerSize":134}'}}',
  ].join(',');
  final g = gated is String ? '"$gated"' : '$gated';
  return '{"_id":"x","id":"$id","private":false,"gated":$g,"disabled":false,'
      '"sha":"$sha","tags":["litert-lm","license:$license","region:us"],'
      '"cardData":{"license":"$license"},"siblings":[$siblings]}';
}

Directory tempDir() => Directory.systemTemp.createTempSync('model_hub_test');

const gemmaId =
    'litert-community/gemma-4-E2B-it-litert-lm@6e5c4f1e395deb959c494953478fa5cec4b8008f/gemma-4-E2B-it.litertlm';
const gemmaSha =
    '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c';
const gemmaSize = 2588147712;
const embedId =
    'litert-community/embeddinggemma-2-740m-litert-lm@86b903a293f96d042bb92e1b7af333d94114458f/embeddinggemma-2-740m.litertlm';
const embedSha =
    'e7a8a2204b91e0f96e92960e84a09a89212e1633dcb7575a9bf3378b4df77f4c';
const embedSize = 484622336;
const yamnetId =
    'mediapipe/yamnet@4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e4/yamnet.tflite';
const yamnetSha =
    '4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e44ed798e16c3a0cdd4c584faf';
const yamnetSize = 4126810;
