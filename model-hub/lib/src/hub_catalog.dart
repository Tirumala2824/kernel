import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'catalog_builder.dart';
import 'consent.dart';
import 'gallery_allowlist.dart';
import 'hf_api.dart';
import 'http.dart';
import 'platform.dart';
import 'store.dart';

/// Bundled catalog metadata (no model files).
abstract interface class CatalogAssets {
  Future<String> kernelCatalog();
  Future<String> gallerySnapshot();

  /// Gallery allowlist version of the bundled snapshot, e.g. '1_0_20'.
  String get snapshotVersion;
}

/// Converts a Gallery versionName ('1.0.20', '1.0.20-beta') to the
/// allowlist file key ('1_0_20'). Null when it has no numeric prefix.
String? galleryVersionKey(String? versionName) {
  if (versionName == null) return null;
  final m = RegExp(r'^\s*(\d+(?:\.\d+)*)').firstMatch(versionName);
  return m?.group(1)!.replaceAll('.', '_');
}

/// ModelCatalog over three layers, merged with earlier layers winning:
/// 1. Kernel's bundled catalog (pinned, sha256, licence);
/// 2. AI Edge Gallery's allowlist for the installed Gallery version
///    (raw.githubusercontent.com, at most once a day with ETag; cached;
///    bundled snapshot as the last fallback), enriched with sha256, licence
///    and gating from the HF revision API (cached forever per revision);
/// 3. anonymous HF search of litert-community (at most once a day).
///
/// Network is used only with download consent, on Wi-Fi when the consent is
/// Wi-Fi only, and never while rate-limited. Never throws.
class HubModelCatalog implements ModelCatalog {
  HubModelCatalog({
    required this._platform,
    required this._store,
    required CatalogNetwork network,
    required this._consent,
    required this._assets,
    DateTime Function()? clock,
    this.ttl = const Duration(days: 1),
    this.retryAfterFailure = const Duration(hours: 1),
    this.maxSearchRepos = 20,
    this.maxRevisionFetchesPerRefresh = 30,
  }) : _net = network,
       _hf = HfApi(network),
       _clock = clock ?? DateTime.now;

  static const galleryBase =
      'https://raw.githubusercontent.com/google-ai-edge/gallery/refs/heads/main/model_allowlists/';

  final HubPlatform _platform;
  final HubStore _store;
  final CatalogNetwork _net;
  final HfApi _hf;
  final ConsentStore _consent;
  final CatalogAssets _assets;
  final DateTime Function() _clock;
  final Duration ttl;
  final Duration retryAfterFailure;
  final int maxSearchRepos;
  final int maxRevisionFetchesPerRefresh;

  KernelCatalog? _kernel;
  List<CatalogEntry>? _last;
  DateTime? _lastAt;
  bool _lastAllowNet = false;
  Future<List<CatalogEntry>>? _inflight;
  int _revisionBudget = 0;

  /// Preference per entry id from Kernel's catalog (loaded on first use).
  Map<String, int> get preference => _kernel?.preference ?? const {};

  @override
  Future<List<CatalogEntry>> entries({bool refresh = false}) {
    final running = _inflight;
    if (running != null) return running;
    final f = _entries(refresh).whenComplete(() => _inflight = null);
    return _inflight = f;
  }

  Future<List<CatalogEntry>> _entries(bool refresh) async {
    final last = _last;
    final at = _lastAt;
    if (!refresh && last != null && at != null) {
      final fresh = _clock().difference(at) < ttl;
      // Reload once network becomes allowed (e.g. consent just granted).
      final netChanged = !_lastAllowNet && await _networkAllowed();
      if (fresh && !netChanged) return last;
    }
    return _load(refresh);
  }

  Future<CatalogEntry?> byId(String id) async {
    for (final e in await entries()) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<List<CatalogEntry>> _load(bool refresh) async {
    try {
      final kernel = _kernel ??= parseKernelCatalog(
        await _assets.kernelCatalog(),
      );
      final device = await _device();
      final allowNet = await _networkAllowed();
      _revisionBudget = maxRevisionFetchesPerRefresh;
      final revisions = await _RevisionCache.load(_store, _clock);

      final allowlist = await _galleryAllowlist(device, allowNet);
      var gallery = allowlist == null
          ? <CatalogEntry>[]
          : buildGalleryEntries(allowlist, socKey: device?.socKey);
      gallery = [
        for (final e in gallery)
          await _enrich(e, revisions, allowNet, retryFailed: refresh),
      ];
      final searched = await _searchEntries(revisions, allowNet);
      await revisions.save();
      _lastAt = _clock();
      _lastAllowNet = allowNet;
      return _last = mergeEntries([kernel.entries, gallery, searched]);
    } on Object {
      // Never throw: Kernel's bundled catalog is always available.
      return _last ??= (_kernel ?? KernelCatalog.empty).entries;
    }
  }

  Future<DeviceProfile?> _device() async {
    try {
      return await _platform.device();
    } on Object {
      return null;
    }
  }

  Future<bool> _networkAllowed() async {
    final consent = await _consent.current();
    if (!consent.granted) return false;
    try {
      final n = await _platform.network();
      if (!n.connected) return false;
      return !consent.wifiOnly || n.unmetered;
    } on Object {
      return false;
    }
  }

  bool _due(Map<String, Object?>? meta, String key) {
    final t = asInt(meta?[key]);
    if (t == null) return true;
    final next = DateTime.fromMillisecondsSinceEpoch(t);
    return !_clock().isBefore(next);
  }

  Future<ModelAllowlist?> _galleryAllowlist(
    DeviceProfile? device,
    bool allowNet,
  ) async {
    final version =
        galleryVersionKey(device?.galleryVersionName) ??
        _assets.snapshotVersion;
    var meta = await _store.readJson('gallery_meta.json');
    var cached = await _store.readText('gallery_allowlist.json');
    // 'for' is the version asked for (the installed Gallery's); 'version' is
    // the file actually served (the snapshot version after a 404).
    if (allowNet && (meta?['for'] != version || _due(meta, 'nextCheck'))) {
      final fetched = await _fetchAllowlist(version, meta, cached);
      if (fetched == null && version != _assets.snapshotVersion) {
        // e.g. 404 for a Gallery version without its own allowlist file.
        await _fetchAllowlist(_assets.snapshotVersion, meta, cached);
      }
      meta = await _store.readJson('gallery_meta.json');
      await _store.writeJson('gallery_meta.json', {...?meta, 'for': version});
      cached = await _store.readText('gallery_allowlist.json');
    }
    final fromCache = cached == null ? null : parseAllowlist(cached);
    if (fromCache != null && fromCache.models.isNotEmpty) return fromCache;
    return parseAllowlist(await _assets.gallerySnapshot());
  }

  /// Returns the stored body, or null when nothing usable was fetched.
  Future<String?> _fetchAllowlist(
    String version,
    Map<String, Object?>? meta,
    String? cached,
  ) async {
    final uri = Uri.parse('$galleryBase$version.json');
    final etag = meta?['version'] == version && cached != null
        ? asString(meta?['etag'])
        : null;
    final r = await _net.get(
      uri,
      headers: {'If-None-Match': ?etag},
    );
    final now = _clock();
    if (r != null && r.status == 304 && cached != null) {
      await _store.writeJson('gallery_meta.json', {
        ...?meta,
        'nextCheck': now.add(ttl).millisecondsSinceEpoch,
      });
      return cached;
    }
    if (r != null && r.status == 200) {
      final parsed = parseAllowlist(r.body);
      if (parsed != null && parsed.models.isNotEmpty) {
        await _store.writeText('gallery_allowlist.json', r.body);
        await _store.writeJson('gallery_meta.json', {
          'version': version,
          'etag': r.header('etag'),
          'nextCheck': now.add(ttl).millisecondsSinceEpoch,
        });
        return r.body;
      }
    }
    await _store.writeJson('gallery_meta.json', {
      ...?meta,
      'nextCheck': now.add(retryAfterFailure).millisecondsSinceEpoch,
    });
    return null;
  }

  Future<CatalogEntry> _enrich(
    CatalogEntry e,
    _RevisionCache revisions,
    bool allowNet, {
    required bool retryFailed,
  }) async {
    if (e.sha256 != null ||
        !isHuggingFaceUrl(e.downloadUrl) ||
        !isPinnedRevision(e.revision)) {
      return e;
    }
    var info = revisions.get(e.repoId, e.revision);
    if (info == null &&
        allowNet &&
        _revisionBudget > 0 &&
        (retryFailed || revisions.mayRetry(e.repoId, e.revision, ttl))) {
      _revisionBudget--;
      info = await _hf.revision(e.repoId, e.revision);
      if (info == null) {
        revisions.markFailed(e.repoId, e.revision);
      } else {
        revisions.put(info);
      }
    }
    return info == null ? e : applyRevisionInfo(e, info);
  }

  Future<List<CatalogEntry>> _searchEntries(
    _RevisionCache revisions,
    bool allowNet,
  ) async {
    var meta = await _store.readJson('hf_search.json');
    if (allowNet && _due(meta, 'nextCheck')) {
      final hits = await _hf.search();
      final now = _clock();
      if (hits == null) {
        meta = {
          ...?meta,
          'nextCheck': now.add(retryAfterFailure).millisecondsSinceEpoch,
        };
      } else {
        final repos = <Map<String, Object?>>[];
        for (final h in hits.take(maxSearchRepos)) {
          if (_revisionBudget <= 0) break;
          _revisionBudget--;
          final info = await _hf.revision(h.id, 'main');
          if (info == null) continue;
          revisions.put(info);
          repos.add({'id': info.repoId, 'sha': info.sha});
        }
        meta = {
          'nextCheck': now.add(ttl).millisecondsSinceEpoch,
          'repos': repos,
        };
      }
      await _store.writeJson('hf_search.json', meta);
    }
    final out = <CatalogEntry>[];
    final repos = meta?['repos'];
    if (repos is List) {
      for (final r in repos) {
        if (r is! Map) continue;
        final id = asString(r['id']);
        final sha = asString(r['sha']);
        if (id == null || sha == null) continue;
        final info = revisions.get(id, sha);
        if (info != null) out.addAll(entriesFromRevision(info));
      }
    }
    return out;
  }
}

/// HF revision facts per `repo@sha` (immutable, cached forever) plus the
/// time of the last failed lookup (retried after the TTL).
class _RevisionCache {
  _RevisionCache(this._store, this._clock, this._infos, this._failed);

  static const _file = 'hf_revisions.json';
  final HubStore _store;
  final DateTime Function() _clock;
  final Map<String, HfRevisionInfo> _infos;
  final Map<String, int> _failed;
  bool _dirty = false;

  static Future<_RevisionCache> load(
    HubStore store,
    DateTime Function() clock,
  ) async {
    final j = await store.readJson(_file);
    final infos = <String, HfRevisionInfo>{};
    final failed = <String, int>{};
    final raw = j?['revisions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final info = HfRevisionInfo.fromJson(v);
        if (k is String && info != null) infos[k] = info;
      });
    }
    final f = j?['failed'];
    if (f is Map) {
      f.forEach((k, v) {
        final t = asInt(v);
        if (k is String && t != null) failed[k] = t;
      });
    }
    return _RevisionCache(store, clock, infos, failed);
  }

  HfRevisionInfo? get(String repo, String sha) => _infos['$repo@$sha'];

  void put(HfRevisionInfo info) {
    _infos['${info.repoId}@${info.sha}'] = info;
    _failed.remove('${info.repoId}@${info.sha}');
    _dirty = true;
  }

  void markFailed(String repo, String rev) {
    _failed['$repo@$rev'] = _clock().millisecondsSinceEpoch;
    _dirty = true;
  }

  bool mayRetry(String repo, String rev, Duration ttl) {
    final t = _failed['$repo@$rev'];
    if (t == null) return true;
    return _clock().difference(DateTime.fromMillisecondsSinceEpoch(t)) >= ttl;
  }

  Future<void> save() async {
    if (!_dirty) return;
    _dirty = false;
    await _store.writeJson(_file, {
      'revisions': {for (final e in _infos.entries) e.key: e.value.toJson()},
      'failed': _failed,
    });
  }
}
