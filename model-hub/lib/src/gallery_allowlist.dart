import 'dart:convert';

// Lenient parser for AI Edge Gallery's model_allowlists/<version>.json.
// Unknown keys are ignored, wrong types fall back to null, and an entry
// without name/modelId/modelFile is skipped. Never throws.

class SocModelFile {
  const SocModelFile({
    this.modelFile,
    this.url,
    this.commitHash,
    this.sizeInBytes,
  });

  final String? modelFile;
  final String? url;
  final String? commitHash;
  final int? sizeInBytes;
}

class AllowedModel {
  const AllowedModel({
    required this.name,
    required this.modelId,
    required this.modelFile,
    this.commitHash,
    this.description,
    this.sizeInBytes,
    this.defaultConfig = const {},
    this.taskTypes = const [],
    this.disabled = false,
    this.llmSupportImage = false,
    this.llmSupportAudio = false,
    this.capabilities = const [],
    this.minDeviceMemoryInGb,
    this.socToModelFiles = const {},
    this.url,
    this.parentModelName,
    this.variantLabel,
    this.updatableModelFiles = const [],
    this.raw = const {},
  });

  final String name;
  final String modelId;
  final String modelFile;
  final String? commitHash;
  final String? description;
  final int? sizeInBytes;
  final Map<String, Object?> defaultConfig;
  final List<String> taskTypes;
  final bool disabled;
  final bool llmSupportImage;
  final bool llmSupportAudio;

  /// Gallery capability tags (e.g. 'llm_thinking'), not Kernel's.
  final List<String> capabilities;
  final int? minDeviceMemoryInGb;

  /// Keyed by lower-case SoC model, e.g. 'sm8850'.
  final Map<String, SocModelFile> socToModelFiles;
  final String? url;
  final String? parentModelName;
  final String? variantLabel;
  final List<Map<String, Object?>> updatableModelFiles;

  /// The whole JSON object, for catalogs that extend this shape.
  final Map<String, Object?> raw;
}

class ModelAllowlist {
  const ModelAllowlist({
    required this.models,
    this.aicoreRequirements,
    this.flags,
  });

  final List<AllowedModel> models;
  final Map<String, Object?>? aicoreRequirements;
  final Map<String, Object?>? flags;
}

/// Null when [json] is not an object with a `models` list.
ModelAllowlist? parseAllowlist(String json) {
  Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (root is! Map) return null;
  final models = root['models'];
  if (models is! List) return null;
  return ModelAllowlist(
    models: [
      for (final m in models)
        if (m is Map) ?parseAllowedModel(m.cast<String, Object?>()),
    ],
    aicoreRequirements: asMap(root['aicoreRequirements']),
    flags: asMap(root['flags']),
  );
}

AllowedModel? parseAllowedModel(Map<String, Object?> m) {
  final name = asString(m['name']);
  final modelId = asString(m['modelId']);
  final modelFile = asString(m['modelFile']);
  if (name == null || modelId == null || modelFile == null) return null;
  final soc = <String, SocModelFile>{};
  final rawSoc = m['socToModelFiles'];
  if (rawSoc is Map) {
    rawSoc.forEach((k, v) {
      if (k is String && v is Map) {
        soc[k.trim().toLowerCase()] = SocModelFile(
          modelFile: asString(v['modelFile']),
          url: asString(v['url']),
          commitHash: asString(v['commitHash']),
          sizeInBytes: asInt(v['sizeInBytes']),
        );
      }
    });
  }
  final updatable = m['updatableModelFiles'];
  return AllowedModel(
    name: name,
    modelId: modelId,
    modelFile: modelFile,
    commitHash: asString(m['commitHash']),
    description: asString(m['description']),
    sizeInBytes: asInt(m['sizeInBytes']),
    defaultConfig: asMap(m['defaultConfig']) ?? const {},
    taskTypes: asStringList(m['taskTypes']),
    disabled: asBool(m['disabled']) ?? false,
    llmSupportImage: asBool(m['llmSupportImage']) ?? false,
    llmSupportAudio: asBool(m['llmSupportAudio']) ?? false,
    capabilities: asStringList(m['capabilities']),
    minDeviceMemoryInGb: asInt(m['minDeviceMemoryInGb']),
    socToModelFiles: soc,
    url: asString(m['url']),
    parentModelName: asString(m['parentModelName']),
    variantLabel: asString(m['variantLabel']),
    updatableModelFiles: [
      if (updatable is List)
        for (final u in updatable)
          if (u is Map) u.cast<String, Object?>(),
    ],
    raw: m,
  );
}

String? asString(Object? v) {
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  if (v is num) return v.toString();
  return null;
}

int? asInt(Object? v) {
  if (v is int) return v;
  if (v is double && v.isFinite) return v.round();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

bool? asBool(Object? v) {
  if (v is bool) return v;
  if (v is String) {
    final t = v.trim().toLowerCase();
    if (t == 'true') return true;
    if (t == 'false') return false;
  }
  return null;
}

Map<String, Object?>? asMap(Object? v) =>
    v is Map ? v.map((k, val) => MapEntry('$k', val)) : null;

List<String> asStringList(Object? v) => [
  if (v is List)
    for (final e in v) ?asString(e),
];
