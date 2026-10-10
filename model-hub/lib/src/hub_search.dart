import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'gallery_allowlist.dart';
import 'store.dart';

/// Words used in search documents for each capability.
const capabilityWords = <ModelCapability, String>{
  ModelCapability.textGen: 'text generation chat assistant',
  ModelCapability.imageIn: 'image input vision photo',
  ModelCapability.audioIn: 'audio input speech',
  ModelCapability.embedText: 'text embedding semantic search retrieval',
  ModelCapability.embedImage: 'image embedding visual search',
  ModelCapability.embedAudio: 'audio embedding sound search',
  ModelCapability.audioClassify: 'sound classification audio event detection',
  ModelCapability.imageClassify: 'image classification',
  ModelCapability.objectDetect: 'object detection',
  ModelCapability.segment: 'image segmentation object mask',
  ModelCapability.sensorClassify: 'sensor signal classification',
};

class SearchDoc {
  const SearchDoc({
    required this.key,
    required this.title,
    required this.text,
    this.entry,
    this.installed,
    this.snippet,
  });

  final String key;
  final String title;
  final String text;
  final CatalogEntry? entry;
  final InstalledModel? installed;
  final String? snippet;
}

/// title + description + capabilities, for catalog entries and installed
/// files that match no catalog entry.
List<SearchDoc> buildSearchDocs(
  List<CatalogEntry> catalog,
  List<InstalledModel> installed,
) {
  final installedById = {
    for (final m in installed)
      if (m.catalogEntryId != null) m.catalogEntryId!: m,
  };
  String caps(Set<ModelCapability> c) =>
      [for (final x in c) capabilityWords[x]!].join('; ');
  String? snippetOf(String? d) {
    if (d == null) return null;
    final plain = d.replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1');
    return plain.length <= 160 ? plain : '${plain.substring(0, 157)}...';
  }

  return [
    for (final e in catalog)
      SearchDoc(
        key: e.id,
        title: e.name,
        text:
            '${e.name}\n${snippetOf(e.description) ?? ''}\n'
            'Capabilities: ${caps(e.capabilities)}',
        entry: e,
        installed: installedById[e.id],
        snippet: snippetOf(e.description),
      ),
    for (final m in installed)
      if (m.catalogEntryId == null)
        SearchDoc(
          key: 'installed:${m.sha256}',
          title: m.path.split(RegExp(r'[\\/]')).last,
          text:
              '${m.path.split(RegExp(r'[\\/]')).last}\n'
              'On this phone (${m.kind.name}).\n'
              'Capabilities: ${caps(m.capabilities)}',
          installed: m,
        ),
  ];
}

/// FNV-1a 32-bit, hex: detects changed document text.
String textHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

List<String> tokens(String s) => tokenizeText(s);

/// Keyword fallback: share of query tokens found (title hits count double),
/// in [0, 1].
double keywordScore(List<String> query, SearchDoc doc) {
  if (query.isEmpty) return 0;
  final title = tokens(doc.title).toSet();
  final body = tokens(doc.text).toSet();
  var s = 0.0;
  for (final q in query) {
    final inTitle = title.any((t) => t.startsWith(q));
    final inBody = body.any((t) => t.startsWith(q));
    if (inTitle) {
      s += 1.0;
    } else if (inBody) {
      s += 0.5;
    }
  }
  return s / query.length;
}

/// ModelSearch with the injected [Embedder] (EmbeddingGemma on the phone):
/// documents are embedded as searchDocument (dim 256) and cached as
/// app-private JSON keyed by text hash and model version; queries are
/// embedded as searchQuery and ranked by cosine. Without an embedder (or
/// when it is unavailable) a keyword ranking is used.
class HubModelSearch implements ModelSearch {
  HubModelSearch({
    required this._store,
    required this._catalog,
    required this._installed,
    this._embedder,
    this.dim = 256,
  });

  static const _file = 'search_index.json';

  final HubStore _store;
  final Future<List<CatalogEntry>> Function() _catalog;
  final Future<List<InstalledModel>> Function() _installed;
  final Embedder? _embedder;
  final int dim;

  _Index? _index;

  Future<List<SearchDoc>> _docs() async {
    List<CatalogEntry> c;
    List<InstalledModel> i;
    try {
      c = await _catalog();
    } on Object {
      c = const [];
    }
    try {
      i = await _installed();
    } on Object {
      i = const [];
    }
    return buildSearchDocs(c, i);
  }

  @override
  Future<List<ModelSearchHit>> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.isEmpty || limit <= 0) return const [];
    final docs = await _docs();
    final semantic = await _semantic(q, docs, limit);
    if (semantic != null) return semantic;
    return _keyword(q, docs, limit);
  }

  @override
  Future<void> reindex() async {
    _index = null;
    await _store.delete(_file);
    await _ensureIndex(await _docs());
  }

  Future<List<ModelSearchHit>?> _semantic(
    String q,
    List<SearchDoc> docs,
    int limit,
  ) async {
    final e = _embedder;
    if (e == null) return null;
    try {
      if (!await e.isAvailable()) return null;
      final index = await _ensureIndex(docs);
      if (index == null) return null;
      final qv = await e.embedText(
        q,
        task: EmbeddingTask.searchQuery,
        dim: dim,
      );
      if (qv == null || qv.dim != dim || qv.modelVersion != index.version) {
        return null;
      }
      final scored = <(double, SearchDoc)>[];
      for (final d in docs) {
        final v = index.vectors[d.key];
        if (v == null || v.hash != textHash(d.text)) continue;
        scored.add((qv.cosine(v.vector), d));
      }
      if (scored.isEmpty) return null;
      scored.sort((a, b) => b.$1.compareTo(a.$1));
      return [
        for (final (s, d) in scored.take(limit))
          ModelSearchHit(
            score: s.clamp(-1.0, 1.0),
            title: d.title,
            entry: d.entry,
            installed: d.installed,
            snippet: d.snippet,
          ),
      ];
    } on Object {
      return null;
    }
  }

  List<ModelSearchHit> _keyword(String q, List<SearchDoc> docs, int limit) {
    final qt = tokens(q);
    final scored = <(double, SearchDoc)>[
      for (final d in docs)
        if (keywordScore(qt, d) case final s when s > 0) (s, d),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return [
      for (final (s, d) in scored.take(limit))
        ModelSearchHit(
          score: s,
          title: d.title,
          entry: d.entry,
          installed: d.installed,
          snippet: d.snippet,
        ),
    ];
  }

  /// Embeds documents that are new or changed; null when nothing could be
  /// embedded.
  Future<_Index?> _ensureIndex(List<SearchDoc> docs) async {
    final e = _embedder;
    if (e == null) return null;
    final version = await e.modelVersion();
    if (version == null) return null;
    var index = _index ?? await _load();
    if (index == null || index.version != version || index.dim != dim) {
      index = _Index(version: version, dim: dim, vectors: {});
    }
    var changed = false;
    for (final d in docs) {
      final h = textHash(d.text);
      if (index.vectors[d.key]?.hash == h) continue;
      final v = await e.embedText(
        d.text,
        task: EmbeddingTask.searchDocument,
        dim: dim,
      );
      if (v == null || v.dim != dim || v.modelVersion != version) continue;
      index.vectors[d.key] = _Vec(h, v);
      changed = true;
    }
    final live = {for (final d in docs) d.key};
    final before = index.vectors.length;
    index.vectors.removeWhere((k, _) => !live.contains(k));
    changed |= index.vectors.length != before;
    _index = index;
    if (changed) await _store.writeJson(_file, index.toJson());
    return index.vectors.isEmpty ? null : index;
  }

  Future<_Index?> _load() async {
    final j = await _store.readJson(_file);
    if (j == null) return null;
    return _Index.fromJson(j);
  }
}

class _Vec {
  _Vec(this.hash, this.vector);

  final String hash;
  final EmbeddingVector vector;
}

class _Index {
  _Index({required this.version, required this.dim, required this.vectors});

  final String version;
  final int dim;
  final Map<String, _Vec> vectors;

  Map<String, Object?> toJson() => {
    'modelVersion': version,
    'dim': dim,
    'docs': {
      for (final e in vectors.entries)
        e.key: {'h': e.value.hash, 'v': e.value.vector.values.toList()},
    },
  };

  static _Index? fromJson(Map<String, Object?> j) {
    final version = asString(j['modelVersion']);
    final dim = asInt(j['dim']);
    final docs = j['docs'];
    if (version == null || dim == null || docs is! Map) return null;
    final out = <String, _Vec>{};
    docs.forEach((k, v) {
      if (k is! String || v is! Map) return;
      final h = asString(v['h']);
      final list = v['v'];
      if (h == null || list is! List || list.length != dim) return;
      final f = Float32List(dim);
      for (var i = 0; i < dim; i++) {
        final x = list[i];
        if (x is! num || !x.isFinite) return;
        f[i] = x.toDouble();
      }
      out[k] = _Vec(h, EmbeddingVector(values: f, modelVersion: version));
    });
    return _Index(version: version, dim: dim, vectors: out);
  }
}

