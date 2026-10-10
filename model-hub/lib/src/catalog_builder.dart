import 'dart:convert';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'gallery_allowlist.dart';

// Pure functions that turn catalog JSON into contracts CatalogEntry values:
// download URL rule, SoC override, NPU drop, capability inference, merge.

final _pinned = RegExp(r'^[0-9a-f]{40}$');
final _sha256 = RegExp(r'^[0-9a-f]{64}$');

bool isPinnedRevision(String revision) => _pinned.hasMatch(revision);

bool isSha256(String? s) => s != null && _sha256.hasMatch(s);

String entryIdOf(String repoId, String revision, String fileName) =>
    '$repoId@$revision/$fileName';

/// Gallery's rule: `url ?: https://huggingface.co/{modelId}/resolve/{commitHash}/{modelFile}?download=true`.
String hfResolveUrl(String repoId, String revision, String fileName) =>
    'https://huggingface.co/$repoId/resolve/$revision/$fileName?download=true';

bool isHuggingFaceUrl(String url) {
  final u = Uri.tryParse(url);
  return u != null && u.scheme == 'https' && u.host == 'huggingface.co';
}

ModelFormat formatOf(String fileName) {
  final f = fileName.toLowerCase();
  if (f.endsWith('.litertlm')) return ModelFormat.litertlm;
  if (f.endsWith('.tflite')) return ModelFormat.tflite;
  if (f.endsWith('.task')) return ModelFormat.mediapipeTask;
  return ModelFormat.unknown;
}

const _textGenTasks = {
  'llm_chat',
  'llm_prompt_lab',
  'llm_agent_chat',
  'llm_ask_image',
  'llm_ask_audio',
  'llm_tiny_garden',
  'llm_mobile_actions',
};

/// Kernel capabilities implied by a Gallery entry's task types and flags.
Set<ModelCapability> inferGalleryCapabilities(AllowedModel m) {
  final tasks = m.taskTypes.map((t) => t.toLowerCase()).toSet();
  final names = '${m.name} ${m.modelId} ${m.modelFile}'.toLowerCase();
  final caps = <ModelCapability>{};
  if (tasks.any(_textGenTasks.contains)) caps.add(ModelCapability.textGen);
  if (m.llmSupportImage || tasks.contains('llm_ask_image')) {
    caps.add(ModelCapability.imageIn);
  }
  if (m.llmSupportAudio || tasks.contains('llm_ask_audio')) {
    caps.add(ModelCapability.audioIn);
  }
  if (tasks.contains('smart_album') ||
      tasks.contains('video_moment_finder') ||
      names.contains('embedding')) {
    caps
      ..add(ModelCapability.embedText)
      ..add(ModelCapability.embedImage);
    caps.remove(ModelCapability.textGen);
  }
  if (tasks.contains('mp_scrapbook') ||
      tasks.any((t) => t.contains('segment'))) {
    caps.add(ModelCapability.segment);
  }
  if (tasks.any((t) => t.contains('image_classification'))) {
    caps.add(ModelCapability.imageClassify);
  }
  if (tasks.any((t) => t.contains('object_detection'))) {
    caps.add(ModelCapability.objectDetect);
  }
  if (tasks.any((t) => t.contains('audio_classification'))) {
    caps.add(ModelCapability.audioClassify);
  }
  return caps;
}

List<String> acceleratorsOf(Map<String, Object?> defaultConfig) {
  final a = defaultConfig['accelerators'];
  final s = a is String ? a : (a is List ? a.join(',') : '');
  return [
    for (final p in s.split(','))
      if (p.trim().isNotEmpty) p.trim().toLowerCase(),
  ];
}

/// True when the entry only runs on an NPU (vendor runtime libraries that
/// Kernel does not ship).
bool isNpuOnly(AllowedModel m) {
  final acc = acceleratorsOf(m.defaultConfig);
  if (acc.isNotEmpty && acc.every((a) => a == 'npu')) return true;
  return m.variantLabel?.trim().toLowerCase() == 'npu';
}

/// Converts the Gallery allowlist for a device with SoC [socKey]
/// (lower-case Build.SOC_MODEL, e.g. 'sm8850'):
/// - generic (GPU/CPU) entries are kept as published;
/// - `socToModelFiles[socKey]` adds an SoC variant that overrides file,
///   commit, url and size (`socVariant` set; never auto-planned);
/// - NPU-only entries without an SoC match are dropped;
/// - disabled entries are dropped.
/// Gallery publishes no sha256 or licence: those stay null / 'unknown'
/// (and `gated` true) until resolved from the HF revision API.
List<CatalogEntry> buildGalleryEntries(
  ModelAllowlist list, {
  String? socKey,
}) {
  final out = <CatalogEntry>[];
  for (final m in list.models) {
    if (m.disabled) continue;
    final soc = socKey == null ? null : m.socToModelFiles[socKey];
    if (!isNpuOnly(m)) {
      final e = _galleryEntry(
        m,
        fileName: m.modelFile,
        revision: m.commitHash,
        url: m.url,
        size: m.sizeInBytes,
      );
      if (e != null) out.add(e);
    }
    if (soc != null) {
      final overridesFile = soc.modelFile != null || soc.commitHash != null;
      final e = _galleryEntry(
        m,
        fileName: soc.modelFile ?? m.modelFile,
        revision: soc.commitHash ?? m.commitHash,
        url: soc.url ?? (overridesFile ? null : m.url),
        size: soc.sizeInBytes ?? m.sizeInBytes,
        socVariant: socKey,
      );
      if (e != null) out.add(e);
    }
  }
  return out;
}

CatalogEntry? _galleryEntry(
  AllowedModel m, {
  required String fileName,
  required String? revision,
  required String? url,
  required int? size,
  String? socVariant,
}) {
  final rev = revision ?? '';
  final downloadUrl = url ?? hfResolveUrl(m.modelId, rev, fileName);
  final hf = isHuggingFaceUrl(downloadUrl);
  final label = socVariant != null
      ? ' (NPU ${socVariant.toUpperCase()})'
      : (m.variantLabel != null ? ' (${m.variantLabel})' : '');
  return CatalogEntry(
    id: entryIdOf(m.modelId, rev, fileName),
    name: '${m.name}$label',
    repoId: m.modelId,
    revision: rev,
    fileName: fileName,
    sizeBytes: size ?? 0,
    sha256: null,
    format: formatOf(fileName),
    capabilities: inferGalleryCapabilities(m),
    license: 'unknown',
    gated: hf,
    source: ModelSource.galleryCatalog,
    downloadUrl: downloadUrl,
    description: m.description,
    minDeviceMemoryGb: m.minDeviceMemoryInGb,
    defaultConfig: m.defaultConfig,
    socVariant: socVariant,
  );
}

class KernelCatalog {
  const KernelCatalog({required this.entries, required this.preference});

  final List<CatalogEntry> entries;

  /// Catalog preference per entry id (higher wins in bestFor / plan).
  final Map<String, int> preference;

  static const empty = KernelCatalog(entries: [], preference: {});
}

/// Kernel's own catalog: Gallery entry shape plus sha256, license, gated,
/// Kernel `capabilities` (ModelCapability names) and `preference`.
KernelCatalog parseKernelCatalog(String json) {
  Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException {
    return KernelCatalog.empty;
  }
  if (root is! Map || root['models'] is! List) return KernelCatalog.empty;
  final entries = <CatalogEntry>[];
  final pref = <String, int>{};
  for (final raw in root['models'] as List) {
    if (raw is! Map) continue;
    final m = parseAllowedModel(raw.cast<String, Object?>());
    if (m == null || m.disabled) continue;
    final rev = m.commitHash ?? '';
    final caps = {
      for (final c in asStringList(m.raw['capabilities']))
        ?ModelCapability.values.asNameMap()[c],
    };
    final sha = asString(m.raw['sha256'])?.toLowerCase();
    final e = CatalogEntry(
      id: entryIdOf(m.modelId, rev, m.modelFile),
      name: m.name,
      repoId: m.modelId,
      revision: rev,
      fileName: m.modelFile,
      sizeBytes: m.sizeInBytes ?? 0,
      sha256: isSha256(sha) ? sha : null,
      format: formatOf(m.modelFile),
      capabilities: caps.isEmpty ? inferGalleryCapabilities(m) : caps,
      license: asString(m.raw['license'])?.toLowerCase() ?? 'unknown',
      // Fail closed: an entry that does not say it is ungated is gated.
      gated: asBool(m.raw['gated']) ?? true,
      source: ModelSource.kernelCatalog,
      downloadUrl: m.url ?? hfResolveUrl(m.modelId, rev, m.modelFile),
      description: m.description,
      minDeviceMemoryGb: m.minDeviceMemoryInGb,
      defaultConfig: m.defaultConfig,
    );
    entries.add(e);
    pref[e.id] = asInt(m.raw['preference']) ?? 50;
  }
  return KernelCatalog(entries: entries, preference: pref);
}

/// Copy with selected fields replaced (CatalogEntry has no copyWith).
CatalogEntry withEntry(
  CatalogEntry e, {
  int? sizeBytes,
  String? sha256,
  String? license,
  bool? gated,
}) => CatalogEntry(
  id: e.id,
  name: e.name,
  repoId: e.repoId,
  revision: e.revision,
  fileName: e.fileName,
  sizeBytes: sizeBytes ?? e.sizeBytes,
  sha256: sha256 ?? e.sha256,
  format: e.format,
  capabilities: e.capabilities,
  license: license ?? e.license,
  gated: gated ?? e.gated,
  source: e.source,
  downloadUrl: e.downloadUrl,
  description: e.description,
  minDeviceMemoryGb: e.minDeviceMemoryGb,
  defaultConfig: e.defaultConfig,
  socVariant: e.socVariant,
);

/// Merges catalog layers; earlier layers win (Kernel, then Gallery, then HF
/// search). Duplicates are detected by id, by (repo, file, SoC) and by
/// sha256, so a curated pin shadows a newer `main` found by search.
List<CatalogEntry> mergeEntries(List<List<CatalogEntry>> layers) {
  final out = <CatalogEntry>[];
  final ids = <String>{};
  final files = <String>{};
  final hashes = <String>{};
  for (final layer in layers) {
    for (final e in layer) {
      final fileKey =
          '${e.repoId.toLowerCase()}|${e.fileName.toLowerCase()}|${e.socVariant ?? ''}';
      final sha = e.sha256;
      if (ids.contains(e.id) ||
          files.contains(fileKey) ||
          (sha != null && hashes.contains(sha))) {
        continue;
      }
      ids.add(e.id);
      files.add(fileKey);
      if (sha != null) hashes.add(sha);
      out.add(e);
    }
  }
  return out;
}
