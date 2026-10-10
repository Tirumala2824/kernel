// Test-only model hub, model search and knowledge-card doubles.

import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';

const testRevision = '0123456789abcdef0123456789abcdef01234567';

CatalogEntry testEntry({
  required String name,
  required Set<ModelCapability> capabilities,
  int sizeBytes = 1000000000,
  String license = 'apache-2.0',
  String repoId = 'litert-community/test-model',
  String host = 'huggingface.co',
  ModelSource source = ModelSource.galleryCatalog,
  String? fileName,
}) {
  final file = fileName ?? '${name.toLowerCase().replaceAll(' ', '-')}.bin';
  return CatalogEntry(
    id: '$repoId@$testRevision/$file',
    name: name,
    repoId: repoId,
    revision: testRevision,
    fileName: file,
    sizeBytes: sizeBytes,
    sha256: 'ab' * 32,
    format: ModelFormat.litertlm,
    capabilities: capabilities,
    license: license,
    gated: false,
    source: source,
    downloadUrl: 'https://$host/$repoId/resolve/$testRevision/$file',
  );
}

InstalledModel testInstalled({
  required String path,
  required Set<ModelCapability> capabilities,
  int sizeBytes = 1000000000,
  String? catalogEntryId,
  List<String> backends = const ['gpu', 'cpu'],
}) => InstalledModel(
  path: path,
  sizeBytes: sizeBytes,
  sha256: 'cd' * 32,
  kind: InstalledModelKind.llm,
  capabilities: capabilities,
  backends: backends,
  verifiedAt: DateTime(2026, 10, 1),
  catalogEntryId: catalogEntryId,
);

class ScriptedModelCatalog implements ModelCatalog {
  List<CatalogEntry> all = [];

  @override
  Future<List<CatalogEntry>> entries({bool refresh = false}) async => all;
}

class InMemoryModelRegistry implements ModelRegistry {
  final _changes = Changes();
  List<InstalledModel> _installed = [];
  int rescans = 0;

  List<InstalledModel> get installed => _installed;
  set installed(List<InstalledModel> value) {
    _installed = value;
    _changes.notify();
  }

  @override
  Stream<List<InstalledModel>> watchInstalled() =>
      _changes.watch(() => List.unmodifiable(_installed));

  @override
  Future<void> rescan() async => rescans++;

  @override
  Future<InstalledModel?> bestFor(ModelCapability capability) async =>
      _installed.where((m) => m.capabilities.contains(capability)).firstOrNull;
}

/// Plans from [catalog] whatever the registry is missing; `ensure` returns
/// a stream the test drives with [emit]. Throws if ensure runs without
/// consent, so a test fails loudly if the UI ever skips the consent.
class ScriptedModelProvisioner implements ModelProvisioner {
  ScriptedModelProvisioner(this.registry);

  final InMemoryModelRegistry registry;
  final _changes = Changes();
  DownloadConsent _consent = const DownloadConsent(granted: false);
  List<CatalogEntry> catalog = [];
  final consentWrites = <DownloadConsent>[];
  final ensureCalls = <Set<ModelCapability>>[];
  final cancelled = <String>[];
  final removed = <String>[];
  int freeBytes = 500000000;
  StreamController<ProvisionProgress>? _progress;

  DownloadConsent get consent => _consent;

  @override
  Stream<DownloadConsent> watchConsent() => _changes.watch(() => _consent);

  @override
  Future<void> setConsent(DownloadConsent consent) async {
    consentWrites.add(consent);
    _consent = consent;
    _changes.notify();
  }

  @override
  Future<List<CatalogEntry>> plan(Set<ModelCapability> required) async {
    final have = {for (final m in registry.installed) ...m.capabilities};
    final missing = required.difference(have);
    return [
      for (final e in catalog)
        if (e.capabilities.any(missing.contains)) e,
    ];
  }

  @override
  Stream<ProvisionProgress> ensure(Set<ModelCapability> required) {
    if (!_consent.granted) {
      throw StateError('ensure() called without download consent');
    }
    ensureCalls.add(required);
    final controller = StreamController<ProvisionProgress>();
    _progress = controller;
    return controller.stream;
  }

  void emit(ProvisionProgress progress) => _progress!.add(progress);

  Future<void> finish() => _progress!.close();

  @override
  Future<void> cancel(String entryId) async => cancelled.add(entryId);

  @override
  Future<void> remove(String path) async {
    removed.add(path);
    registry.installed = [
      for (final m in registry.installed)
        if (m.path != path) m,
    ];
  }

  @override
  Future<int> freeSpaceBytes() async => freeBytes;
}

class ScriptedModelSearch implements ModelSearch {
  List<ModelSearchHit> hits = [];
  Object? failWith;
  final queries = <String>[];

  @override
  Future<List<ModelSearchHit>> search(String query, {int limit = 5}) async {
    queries.add(query);
    final error = failWith;
    if (error != null) throw error;
    return hits;
  }

  @override
  Future<void> reindex() async {}
}

KnowledgeCard hubTestCard({
  String id = 'rice-weevil',
  String name = 'Rice weevil',
  String summary = 'Small brown beetle with a snout.',
  String reviewStatus = 'needs-expert-review',
}) => KnowledgeCard(
  id: id,
  names: {'en': name},
  group: PestGroup.values.first,
  safety: SafetyLevel.values.first,
  summary: summary,
  signs: const [],
  lookAlikes: const [],
  healthRisks: const [],
  safeSteps: const [],
  callProfessionalWhen: const [],
  firstAid: const [],
  legal: null,
  sources: const ['test'],
  reviewStatus: reviewStatus,
);

/// Knowledge double for both the hub search tests (scripted [hits]) and the
/// Pest ID tests (a [cards] list with keyword search, best first).
class ScriptedKnowledgeService implements KnowledgeService {
  List<KnowledgeHit> hits = [];
  List<KnowledgeCard> cards = [];
  final queries = <String>[];

  List<KnowledgeCard> get _all => [
    ...cards,
    for (final h in hits)
      if (!cards.any((c) => c.id == h.card.id)) h.card,
  ];

  @override
  Future<List<KnowledgeCard>> all() async => _all;

  @override
  Future<KnowledgeCard?> get(String id) async =>
      _all.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<KnowledgeHit>> search(String query, {int limit = 3}) async {
    queries.add(query);
    if (hits.isNotEmpty) return hits;
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
    final found = <KnowledgeHit>[];
    for (final card in cards) {
      final text = [
        ...card.names.values,
        card.id,
        ...card.signs,
      ].join(" ").toLowerCase();
      final score = words.where(text.contains).length;
      if (score > 0) found.add(KnowledgeHit(card: card, score: score / 10));
    }
    found.sort((a, b) => b.score.compareTo(a.score));
    return found.take(limit).toList();
  }
}
