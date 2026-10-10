import 'dart:convert';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'catalog_builder.dart';
import 'gallery_allowlist.dart';
import 'http.dart';

// Anonymous Hugging Face Hub API (no token, no account):
// - GET /api/models?author=litert-community&filter=litert-lm&sort=downloads&direction=-1&limit=N
//   paged through the `Link: <...>; rel="next"` header
// - GET /api/models/{id}/revision/{rev}?blobs=true
//   full commit sha, gated, tags (license:*), siblings with size + lfs.sha256

class HfFile {
  const HfFile({required this.name, required this.size, this.sha256});

  final String name;
  final int size;
  final String? sha256;

  Map<String, Object?> toJson() => {'n': name, 's': size, 'h': sha256};

  static HfFile? fromJson(Object? j) {
    if (j is! Map) return null;
    final n = asString(j['n']);
    final s = asInt(j['s']);
    if (n == null || s == null) return null;
    return HfFile(name: n, size: s, sha256: asString(j['h']));
  }
}

class HfRevisionInfo {
  const HfRevisionInfo({
    required this.repoId,
    required this.sha,
    required this.gated,
    required this.files,
    this.license,
    this.tags = const [],
    this.pipelineTag,
  });

  final String repoId;

  /// Full 40-character commit sha of the revision.
  final String sha;
  final bool gated;
  final String? license;
  final Map<String, HfFile> files;
  final List<String> tags;
  final String? pipelineTag;

  Map<String, Object?> toJson() => {
    'repoId': repoId,
    'sha': sha,
    'gated': gated,
    'license': license,
    'tags': tags,
    'pipelineTag': pipelineTag,
    'files': [for (final f in files.values) f.toJson()],
  };

  static HfRevisionInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final repo = asString(j['repoId']);
    final sha = asString(j['sha']);
    if (repo == null || sha == null || !isPinnedRevision(sha)) return null;
    final files = <String, HfFile>{};
    final list = j['files'];
    if (list is List) {
      for (final f in list) {
        final h = HfFile.fromJson(f);
        if (h != null) files[h.name] = h;
      }
    }
    return HfRevisionInfo(
      repoId: repo,
      sha: sha,
      gated: asBool(j['gated']) ?? true,
      license: asString(j['license']),
      tags: asStringList(j['tags']),
      pipelineTag: asString(j['pipelineTag']),
      files: files,
    );
  }
}

/// Parses the revision API body. Gated is true unless the API says `false`
/// ("auto" and "manual" both require accepting terms).
HfRevisionInfo? parseRevisionInfo(String repoId, String body) {
  Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (j is! Map) return null;
  final sha = asString(j['sha']);
  if (sha == null || !isPinnedRevision(sha)) return null;
  final tags = asStringList(j['tags']);
  final files = <String, HfFile>{};
  final siblings = j['siblings'];
  if (siblings is List) {
    for (final s in siblings) {
      if (s is! Map) continue;
      final name = asString(s['rfilename']);
      final lfs = s['lfs'];
      final size = asInt(s['size']) ?? (lfs is Map ? asInt(lfs['size']) : null);
      if (name == null || size == null) continue;
      final sha256 = lfs is Map
          ? asString(lfs['sha256'] ?? lfs['oid'])?.toLowerCase()
          : null;
      files[name] = HfFile(
        name: name,
        size: size,
        sha256: isSha256(sha256) ? sha256 : null,
      );
    }
  }
  return HfRevisionInfo(
    repoId: asString(j['id']) ?? repoId,
    sha: sha,
    gated: j['gated'] != false,
    license: licenseFrom(tags, j['cardData']),
    tags: tags,
    pipelineTag: asString(j['pipeline_tag']),
    files: files,
  );
}

String? licenseFrom(List<String> tags, Object? cardData) {
  for (final t in tags) {
    if (t.toLowerCase().startsWith('license:')) {
      return t.substring('license:'.length).trim().toLowerCase();
    }
  }
  if (cardData is Map) {
    final l = cardData['license'];
    if (l is String) return l.trim().toLowerCase();
    if (l is List && l.isNotEmpty && l.first is String) {
      return (l.first as String).trim().toLowerCase();
    }
  }
  return null;
}

class HfSearchHit {
  const HfSearchHit({
    required this.id,
    required this.tags,
    required this.downloads,
    this.pipelineTag,
  });

  final String id;
  final List<String> tags;
  final int downloads;
  final String? pipelineTag;
}

List<HfSearchHit>? parseSearch(String body) {
  Object? j;
  try {
    j = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (j is! List) return null;
  return [
    for (final m in j)
      if (m is Map && asString(m['id']) != null && m['private'] != true)
        HfSearchHit(
          id: asString(m['id'])!,
          tags: asStringList(m['tags']),
          downloads: asInt(m['downloads']) ?? 0,
          pipelineTag: asString(m['pipeline_tag']),
        ),
  ];
}

/// The `rel="next"` target of a Link header, only on huggingface.co.
Uri? nextLink(String? header) {
  if (header == null) return null;
  for (final part in header.split(',')) {
    final m = RegExp(r'<([^>]+)>\s*;\s*rel="?next"?').firstMatch(part.trim());
    if (m == null) continue;
    final u = Uri.tryParse(m.group(1)!);
    if (u != null && u.scheme == 'https' && u.host == 'huggingface.co') {
      return u;
    }
  }
  return null;
}

final _npuFile = RegExp(
  r'(qualcomm|mediatek|google_tensor|tensor_g\d|intel_|_sm\d{4}|_mt\d{4}|_qcs\d+|[-_.]npu|[-_]web\.)',
  caseSensitive: false,
);

/// SoC-specific (NPU) or web builds. Kernel uses the generic GPU/CPU files:
/// NPU builds need vendor runtime libraries that are not shipped.
bool isSocSpecificFile(String fileName) => _npuFile.hasMatch(fileName);

/// Catalog entries for one pinned HF revision found by search: generic
/// `.litertlm` files only.
List<CatalogEntry> entriesFromRevision(HfRevisionInfo info) {
  final out = <CatalogEntry>[];
  final repo = info.repoId;
  final tagText = '${info.tags.join(' ')} ${info.pipelineTag ?? ''} $repo'
      .toLowerCase();
  for (final f in info.files.values) {
    if (formatOf(f.name) != ModelFormat.litertlm) continue;
    if (isSocSpecificFile(f.name)) continue;
    final caps = <ModelCapability>{};
    if (tagText.contains('embedding') ||
        f.name.toLowerCase().contains('embedding')) {
      caps.add(ModelCapability.embedText);
    } else {
      caps.add(ModelCapability.textGen);
      if (tagText.contains('image-text-to-text') ||
          tagText.contains('any-to-any')) {
        caps.add(ModelCapability.imageIn);
      }
    }
    out.add(
      CatalogEntry(
        id: entryIdOf(repo, info.sha, f.name),
        name: '${repo.split('/').last} · ${f.name}',
        repoId: repo,
        revision: info.sha,
        fileName: f.name,
        sizeBytes: f.size,
        sha256: f.sha256,
        format: ModelFormat.litertlm,
        capabilities: caps,
        license: info.license ?? 'unknown',
        gated: info.gated,
        source: ModelSource.huggingFaceSearch,
        downloadUrl: hfResolveUrl(repo, info.sha, f.name),
        description: 'Found on Hugging Face ($repo). Capabilities are '
            'inferred from tags until the file is probed on the phone.',
      ),
    );
  }
  return out;
}

/// Applies the HF revision facts (sha256, size, licence, gated) to an entry
/// pinned to that revision. Unchanged when the file is not in the revision.
CatalogEntry applyRevisionInfo(CatalogEntry e, HfRevisionInfo info) {
  final f = info.files[e.fileName];
  if (f == null) return e;
  return withEntry(
    e,
    sizeBytes: f.size,
    sha256: f.sha256,
    license: info.license ?? 'unknown',
    gated: info.gated,
  );
}

class HfApi {
  HfApi(this._net);

  static const host = 'huggingface.co';
  final CatalogNetwork _net;

  static Uri searchUri({int limit = 50}) => Uri.https(host, '/api/models', {
    'author': 'litert-community',
    'filter': 'litert-lm',
    'sort': 'downloads',
    'direction': '-1',
    'limit': '$limit',
  });

  static Uri revisionUri(String repoId, String revision) => Uri(
    scheme: 'https',
    host: host,
    pathSegments: ['api', 'models', ...repoId.split('/'), 'revision', revision],
    queryParameters: {'blobs': 'true'},
  );

  /// Null when the network refused or failed; follows rel=next up to
  /// [maxPages].
  Future<List<HfSearchHit>?> search({int limit = 50, int maxPages = 2}) async {
    final hits = <HfSearchHit>[];
    Uri? next = searchUri(limit: limit);
    var pages = 0;
    while (next != null && pages < maxPages) {
      final r = await _net.get(next);
      if (r == null || r.status != 200) return pages == 0 ? null : hits;
      final page = parseSearch(r.body);
      if (page == null) return pages == 0 ? null : hits;
      hits.addAll(page);
      pages++;
      next = nextLink(r.header('link'));
    }
    return hits;
  }

  Future<HfRevisionInfo?> revision(String repoId, String revision) async {
    final r = await _net.get(revisionUri(repoId, revision));
    if (r == null || r.status != 200) return null;
    return parseRevisionInfo(repoId, r.body);
  }
}
