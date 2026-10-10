import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'catalog_builder.dart';
import 'gallery_allowlist.dart';
import 'platform.dart';
import 'policy.dart';
import 'store.dart';

/// What the registry remembers per file, so a file is hashed and probed only
/// once per (path, size, mtime).
class _Record {
  _Record({
    required this.path,
    required this.size,
    required this.mtime,
    required this.sha256,
    required this.verifiedAt,
    required this.probeDone,
    this.probe,
  });

  final String path;
  final int size;
  final int mtime;
  final String sha256;
  final DateTime verifiedAt;

  /// False when the probe threw (retried on the next rescan).
  final bool probeDone;
  final ModelProbeResult? probe;

  Map<String, Object?> toJson() => {
    'path': path,
    'size': size,
    'mtime': mtime,
    'sha256': sha256,
    'verifiedAt': verifiedAt.toUtc().toIso8601String(),
    'probeDone': probeDone,
    if (probe case final p?)
      'probe': {
        'kind': p.kind.name,
        'inputModalities': p.inputModalities.toList(),
        'backends': p.backends,
        'maxContextTokens': p.maxContextTokens,
        'embeddingDim': p.embeddingDim,
        'socName': p.socName,
        'npuBrand': p.npuBrand,
      },
  };

  static _Record? fromJson(Object? j) {
    if (j is! Map) return null;
    final path = asString(j['path']);
    final size = asInt(j['size']);
    final mtime = asInt(j['mtime']);
    final sha = asString(j['sha256']);
    final at = DateTime.tryParse(asString(j['verifiedAt']) ?? '');
    if (path == null || size == null || mtime == null || !isSha256(sha)) {
      return null;
    }
    ModelProbeResult? probe;
    final p = j['probe'];
    if (p is Map) {
      probe = ModelProbeResult(
        kind:
            ProbedKind.values.asNameMap()[asString(p['kind'])] ??
            ProbedKind.unknown,
        inputModalities: asStringList(p['inputModalities']).toSet(),
        backends: asStringList(p['backends']),
        maxContextTokens: asInt(p['maxContextTokens']),
        embeddingDim: asInt(p['embeddingDim']),
        socName: asString(p['socName']),
        npuBrand: asString(p['npuBrand']),
      );
    }
    return _Record(
      path: path,
      size: size,
      mtime: mtime,
      sha256: sha!,
      verifiedAt: at ?? DateTime.fromMillisecondsSinceEpoch(0),
      probeDone: asBool(j['probeDone']) ?? true,
      probe: probe,
    );
  }
}

/// Capabilities a LiteRT-LM header reports.
Set<ModelCapability> capabilitiesFromProbe(ModelProbeResult r) {
  final m = r.inputModalities.map((s) => s.toLowerCase()).toSet();
  switch (r.kind) {
    case ProbedKind.llm:
      return {
        ModelCapability.textGen,
        if (m.contains('vision')) ModelCapability.imageIn,
        if (m.contains('audio')) ModelCapability.audioIn,
      };
    case ProbedKind.embedding:
      return {
        if (m.isEmpty || m.contains('text')) ModelCapability.embedText,
        if (m.contains('vision')) ModelCapability.embedImage,
        if (m.contains('audio')) ModelCapability.embedAudio,
      };
    case ProbedKind.unknown:
      return const {};
  }
}

bool _isEmbedCapability(ModelCapability c) =>
    c == ModelCapability.embedText ||
    c == ModelCapability.embedImage ||
    c == ModelCapability.embedAudio;

bool _isLlmCapability(ModelCapability c) =>
    c == ModelCapability.textGen ||
    c == ModelCapability.imageIn ||
    c == ModelCapability.audioIn;

/// ModelRegistry over Kernel's model storage (models/ plus the legacy llm/
/// directory). New files are hashed (natively, cached) and probed through
/// the injected [ModelProbe]; a file whose size and sha256 match a catalog
/// entry (e.g. an adb copy of Gallery's file) gets that entry's id.
class HubModelRegistry implements ModelRegistry {
  HubModelRegistry({
    required this._platform,
    required this._probe,
    required this._store,
    required this._catalog,
    required this._preference,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _file = 'registry.json';

  final HubPlatform _platform;
  final ModelProbe _probe;
  final HubStore _store;
  final Future<List<CatalogEntry>> Function() _catalog;
  final Map<String, int> Function() _preference;
  final DateTime Function() _clock;
  final _changes = StreamController<List<InstalledModel>>.broadcast();

  List<InstalledModel>? _current;
  Map<String, CatalogEntry> _byId = const {};
  bool _scanned = false;
  Future<void>? _scanning;

  @override
  Stream<List<InstalledModel>> watchInstalled() {
    late final StreamController<List<InstalledModel>> out;
    StreamSubscription<List<InstalledModel>>? sub;
    out = StreamController<List<InstalledModel>>(
      onListen: () async {
        sub = _changes.stream.listen(out.add);
        final cur = _current ?? await _loadPersisted();
        if (cur != null && !out.isClosed) out.add(cur);
        if (!_scanned) unawaited(rescan());
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  /// The installed list, scanning once per session first.
  Future<List<InstalledModel>> installed() async {
    if (!_scanned) await rescan();
    return _current ?? const [];
  }

  @override
  Future<void> rescan() =>
      _scanning ??= _rescan().whenComplete(() => _scanning = null);

  @override
  Future<InstalledModel?> bestFor(ModelCapability capability) async {
    final all = await installed();
    int? ram;
    try {
      ram = (await _platform.device()).totalRamBytes;
    } on Object {
      ram = null;
    }
    final pref = _preference();
    final candidates = [
      for (final m in all)
        if (m.capabilities.contains(capability) &&
            fitsMemory(_byId[m.catalogEntryId]?.minDeviceMemoryGb, ram))
          m,
    ];
    if (candidates.isEmpty) return null;
    int kindScore(InstalledModel m) {
      if (_isEmbedCapability(capability)) {
        return m.kind == InstalledModelKind.embedding ? 1 : 0;
      }
      if (_isLlmCapability(capability)) {
        return m.kind == InstalledModelKind.llm ? 1 : 0;
      }
      return 0;
    }

    int prefOf(InstalledModel m) {
      final e = _byId[m.catalogEntryId];
      return e == null ? 0 : preferenceOf(e, pref);
    }

    bool generic(InstalledModel m) => _byId[m.catalogEntryId]?.socVariant == null;

    candidates.sort((a, b) {
      final g = (generic(b) ? 1 : 0) - (generic(a) ? 1 : 0);
      if (g != 0) return g;
      final k = kindScore(b) - kindScore(a);
      if (k != 0) return k;
      final p = prefOf(b) - prefOf(a);
      if (p != 0) return p;
      final s = a.sizeBytes.compareTo(b.sizeBytes);
      if (s != 0) return s;
      return a.path.compareTo(b.path);
    });
    return candidates.first;
  }

  Future<List<InstalledModel>?> _loadPersisted() async {
    final records = await _records();
    if (records.isEmpty) return null;
    final catalog = await _safeCatalog();
    return _current ??= _toModels(records, catalog);
  }

  Future<List<_Record>> _records() async {
    final j = await _store.readJson(_file);
    final list = j?['files'];
    return [
      if (list is List)
        for (final r in list) ?_Record.fromJson(r),
    ];
  }

  Future<List<CatalogEntry>> _safeCatalog() async {
    try {
      return await _catalog();
    } on Object {
      return const [];
    }
  }

  Future<void> _rescan() async {
    List<ModelFileInfo> files;
    try {
      files = await _platform.listModelFiles();
    } on Object {
      return;
    }
    final prior = {for (final r in await _records()) r.path: r};
    final catalog = await _safeCatalog();
    final records = <_Record>[];
    for (final f in files) {
      var r = prior[f.path];
      final unchanged =
          r != null && r.size == f.sizeBytes && r.mtime == f.modifiedMs;
      if (!unchanged) {
        String? sha;
        try {
          sha = await _platform.sha256Of(f.path);
        } on Object {
          sha = null;
        }
        if (!isSha256(sha)) continue;
        r = await _probed(
          _Record(
            path: f.path,
            size: f.sizeBytes,
            mtime: f.modifiedMs,
            sha256: sha!,
            verifiedAt: _clock(),
            probeDone: false,
          ),
        );
      } else if (!r.probeDone) {
        r = await _probed(r);
      }
      records.add(r);
    }
    await _store.writeJson(_file, {
      'files': [for (final r in records) r.toJson()],
    });
    final models = _toModels(records, catalog);
    _current = models;
    _scanned = true;
    _changes.add(models);
  }

  Future<_Record> _probed(_Record r) async {
    if (formatOf(r.path) != ModelFormat.litertlm) {
      return _Record(
        path: r.path,
        size: r.size,
        mtime: r.mtime,
        sha256: r.sha256,
        verifiedAt: r.verifiedAt,
        probeDone: true,
      );
    }
    try {
      final p = await _probe.probe(r.path);
      return _Record(
        path: r.path,
        size: r.size,
        mtime: r.mtime,
        sha256: r.sha256,
        verifiedAt: r.verifiedAt,
        probeDone: true,
        probe: p,
      );
    } on Object {
      return r;
    }
  }

  List<InstalledModel> _toModels(
    List<_Record> records,
    List<CatalogEntry> catalog,
  ) {
    _byId = {for (final e in catalog) e.id: e};
    final bySha = <String, CatalogEntry>{};
    for (final e in catalog) {
      final sha = e.sha256;
      if (sha != null) bySha.putIfAbsent('$sha|${e.sizeBytes}', () => e);
    }
    return [
      for (final r in records) _toModel(r, bySha['${r.sha256}|${r.size}']),
    ];
  }

  InstalledModel _toModel(_Record r, CatalogEntry? match) {
    final format = formatOf(r.path);
    final p = r.probe;
    InstalledModelKind kind;
    Set<ModelCapability> caps;
    var backends = acceleratorsOf(match?.defaultConfig ?? const {});
    if (p != null && p.kind != ProbedKind.unknown) {
      kind = p.kind == ProbedKind.llm
          ? InstalledModelKind.llm
          : InstalledModelKind.embedding;
      caps = capabilitiesFromProbe(p);
      if (p.backends.isNotEmpty) backends = p.backends;
    } else {
      caps = match?.capabilities ?? const {};
      kind = switch (format) {
        ModelFormat.tflite => InstalledModelKind.tflite,
        ModelFormat.mediapipeTask => InstalledModelKind.mediapipeTask,
        ModelFormat.litertlm when caps.contains(ModelCapability.textGen) =>
          InstalledModelKind.llm,
        ModelFormat.litertlm when caps.any(_isEmbedCapability) =>
          InstalledModelKind.embedding,
        _ => InstalledModelKind.unknown,
      };
    }
    return InstalledModel(
      path: r.path,
      sizeBytes: r.size,
      sha256: r.sha256,
      kind: kind,
      capabilities: caps,
      backends: backends,
      verifiedAt: r.verifiedAt,
      catalogEntryId: match?.id,
      embeddingDim: p?.embeddingDim,
      maxContextTokens: p?.maxContextTokens,
    );
  }

  Future<void> close() => _changes.close();
}
