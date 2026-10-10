// Model hub: automatic discovery, download and indexing of on-device models
// from the AI Edge Gallery catalog, Kernel's catalog and Hugging Face.
// Network is used ONLY to fetch catalogs and model files (guardrails §7);
// every model runs on the phone.

enum ModelCapability {
  textGen,
  imageIn,
  audioIn,
  embedText,
  embedImage,
  embedAudio,
  audioClassify,
  imageClassify,
  objectDetect,
  segment,
  sensorClassify,
}

enum ModelSource { galleryCatalog, kernelCatalog, huggingFaceSearch, local }

enum ModelFormat { litertlm, tflite, mediapipeTask, unknown }

/// One downloadable file, pinned to an immutable revision.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.repoId,
    required this.revision,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    required this.format,
    required this.capabilities,
    required this.license,
    required this.gated,
    required this.source,
    required this.downloadUrl,
    this.description,
    this.minDeviceMemoryGb,
    this.defaultConfig = const {},
    this.socVariant,
  });

  /// Stable key: `repoId@revision/fileName`.
  final String id;
  final String name;
  final String repoId;

  /// Full 40-character commit SHA, never a branch name.
  final String revision;
  final String fileName;
  final int sizeBytes;

  /// Expected LFS sha256; null only until resolved from the HF revision API.
  final String? sha256;
  final ModelFormat format;
  final Set<ModelCapability> capabilities;

  /// SPDX-like id from the repo, e.g. 'apache-2.0'.
  final String license;
  final bool gated;
  final ModelSource source;
  final String downloadUrl;
  final String? description;
  final int? minDeviceMemoryGb;

  /// Runtime hints from the catalog (accelerators, topK, maxTokens ...).
  final Map<String, Object?> defaultConfig;

  /// SoC the file was built for (e.g. 'sm8850'), null for generic files.
  final String? socVariant;
}

enum InstalledModelKind { llm, embedding, tflite, mediapipeTask, unknown }

/// A model file present in Kernel's own storage, probed on the device.
class InstalledModel {
  const InstalledModel({
    required this.path,
    required this.sizeBytes,
    required this.sha256,
    required this.kind,
    required this.capabilities,
    required this.backends,
    required this.verifiedAt,
    this.catalogEntryId,
    this.embeddingDim,
    this.maxContextTokens,
  });

  final String path;
  final int sizeBytes;
  final String sha256;
  final InstalledModelKind kind;
  final Set<ModelCapability> capabilities;

  /// e.g. ['gpu', 'cpu'] as reported by the model header.
  final List<String> backends;
  final DateTime verifiedAt;

  /// Set when size and sha256 match a catalog entry (e.g. Gallery's file).
  final String? catalogEntryId;
  final int? embeddingDim;
  final int? maxContextTokens;

  String get version => catalogEntryId ?? 'local@${sha256.substring(0, 12)}';
}

enum ProvisionPhase {
  queued,
  waitingForWifi,
  waitingForSpace,
  downloading,
  verifying,
  installed,
  paused,
  failed,
}

class ProvisionProgress {
  const ProvisionProgress({
    required this.entryId,
    required this.phase,
    required this.bytesDone,
    required this.totalBytes,
    this.error,
  });

  final String entryId;
  final ProvisionPhase phase;
  final int bytesDone;
  final int totalBytes;

  /// Technical reason when [phase] is failed (e.g. 'sha256_mismatch').
  final String? error;
}

/// The user's one-time download consent.
class DownloadConsent {
  const DownloadConsent({required this.granted, this.wifiOnly = true});

  final bool granted;
  final bool wifiOnly;
}

abstract interface class ModelCatalog {
  /// Merged, de-duplicated entries. Never throws: falls back to the cached
  /// or bundled snapshot when offline.
  Future<List<CatalogEntry>> entries({bool refresh = false});
}

abstract interface class ModelRegistry {
  Stream<List<InstalledModel>> watchInstalled();

  /// Re-scans storage and probes new files (no user input needed).
  Future<void> rescan();

  /// Best installed model for [capability] on this device, or null.
  Future<InstalledModel?> bestFor(ModelCapability capability);
}

abstract interface class ModelProvisioner {
  Stream<DownloadConsent> watchConsent();
  Future<void> setConsent(DownloadConsent consent);

  /// Entries that would be downloaded to satisfy [required]; empty when
  /// everything needed is already installed.
  Future<List<CatalogEntry>> plan(Set<ModelCapability> required);

  /// Downloads whatever [plan] returns (only with consent, only ungated,
  /// approved licences, sha256-verified). Emits progress per entry.
  Stream<ProvisionProgress> ensure(Set<ModelCapability> required);

  Future<void> cancel(String entryId);
  Future<void> remove(String path);
  Future<int> freeSpaceBytes();
}

class ModelSearchHit {
  const ModelSearchHit({
    required this.score,
    required this.title,
    this.entry,
    this.installed,
    this.snippet,
  });

  /// Cosine similarity in [-1, 1].
  final double score;
  final String title;
  final CatalogEntry? entry;
  final InstalledModel? installed;
  final String? snippet;
}

/// Semantic search over catalog entries and model cards (EmbeddingGemma).
abstract interface class ModelSearch {
  Future<List<ModelSearchHit>> search(String query, {int limit = 5});
  Future<void> reindex();
}
