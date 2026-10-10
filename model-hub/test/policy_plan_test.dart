import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';

import 'support/doubles.dart';

CatalogEntry entry(
  String name, {
  Set<ModelCapability> caps = const {ModelCapability.textGen},
  String license = 'apache-2.0',
  bool gated = false,
  String? sha,
  String? revision,
  int size = 1000,
  int? minRam,
  String? soc,
  String url = '',
  ModelSource source = ModelSource.kernelCatalog,
}) {
  final rev = revision ?? 'a' * 40;
  final file = '$name.litertlm';
  return CatalogEntry(
    id: entryIdOf('o/$name', rev, file),
    name: name,
    repoId: 'o/$name',
    revision: rev,
    fileName: file,
    sizeBytes: size,
    sha256: sha ?? (name.hashCode.toRadixString(16).padLeft(8, '0') * 8),
    format: ModelFormat.litertlm,
    capabilities: caps,
    license: license,
    gated: gated,
    source: source,
    downloadUrl: url.isEmpty ? hfResolveUrl('o/$name', rev, file) : url,
    minDeviceMemoryGb: minRam,
    socVariant: soc,
  );
}

InstalledModel installed(CatalogEntry e) => InstalledModel(
  path: '/m/${e.fileName}',
  sizeBytes: e.sizeBytes,
  sha256: e.sha256!,
  kind: InstalledModelKind.llm,
  capabilities: e.capabilities,
  backends: const ['gpu'],
  verifiedAt: DateTime(2026),
  catalogEntryId: e.id,
);

void main() {
  group('download policy', () {
    test('only ungated, approved licence, pinned, sha256-known entries', () {
      expect(downloadBlockReason(entry('ok')), isNull);
      expect(downloadBlockReason(entry('mit', license: 'MIT')), isNull);
      expect(downloadBlockReason(entry('bsd', license: 'bsd-3-clause')), isNull);
      expect(downloadBlockReason(entry('g', gated: true)), 'gated');
      expect(downloadBlockReason(entry('l', license: 'gemma')), 'license_not_approved');
      expect(downloadBlockReason(entry('u', license: 'unknown')), 'license_not_approved');
      expect(downloadBlockReason(entry('s', sha: 'abc')), 'sha256_unknown');
      expect(downloadBlockReason(entry('r', revision: 'main')), 'revision_not_pinned');
      expect(
        downloadBlockReason(entry('h', url: 'https://example.com/x.litertlm')),
        'host_not_allowed',
      );
      expect(
        downloadBlockReason(entry('p', url: 'http://huggingface.co/x.litertlm')),
        'host_not_allowed',
      );
      expect(downloadBlockReason(entry('z', size: 0)), 'size_unknown');
      expect(downloadBlockReason(entry('n', soc: 'sm8850')), 'npu_build');
      expect(approvedLicenses, {'apache-2.0', 'mit', 'bsd-3-clause'});
    });
  });

  group('plan', () {
    final kernel = parseKernelCatalog(readAsset('kernel_catalog.json'));
    final gallery = buildGalleryEntries(
      parseAllowlist(readAsset('gallery_allowlist_1_0_20.json'))!,
      socKey: 'sm8850',
    );
    final catalog = mergeEntries([kernel.entries, gallery]);
    List<String> planIds(
      Set<ModelCapability> req, {
      List<InstalledModel> have = const [],
      int? ram = 11500000000,
    }) => [
      for (final e in planDownloads(
        required: req,
        catalog: catalog,
        installed: have,
        preference: kernel.preference,
        totalRamBytes: ram,
      ))
        e.id,
    ];

    test('text + embeddings on an empty phone: Gemma 4 E2B and EmbeddingGemma', () {
      expect(
        planIds({ModelCapability.textGen, ModelCapability.embedText}).toSet(),
        {gemmaId, embedId},
      );
    });

    test('one multimodal entry covers text, image and audio input', () {
      expect(
        planIds({
          ModelCapability.textGen,
          ModelCapability.imageIn,
          ModelCapability.audioIn,
        }),
        [gemmaId],
      );
    });

    test('installed capabilities are not planned again', () {
      final g = kernel.entries.firstWhere((e) => e.id == gemmaId);
      expect(
        planIds(
          {ModelCapability.textGen, ModelCapability.embedText},
          have: [installed(g)],
        ),
        [embedId],
      );
      expect(planIds({ModelCapability.textGen}, have: [installed(g)]), isEmpty);
    });

    test('sound classifier plans YAMNet; unverified licence plans nothing', () {
      expect(planIds({ModelCapability.audioClassify}), [yamnetId]);
      expect(planIds({ModelCapability.segment}), isEmpty);
      expect(planIds({ModelCapability.sensorClassify}), isEmpty);
    });

    test('device memory gate', () {
      // A 4 GB phone cannot take Gemma 4 E2B (min 8 GB).
      expect(planIds({ModelCapability.textGen}, ram: 3800000000), isEmpty);
      expect(planIds({ModelCapability.embedText}, ram: 3800000000), [embedId]);
    });

    test('minimal set: fewest entries, then preference, then bytes', () {
      final a = entry('a', caps: {ModelCapability.textGen, ModelCapability.imageIn});
      final b = entry('b', caps: {ModelCapability.audioIn});
      final c = entry('c', caps: {
        ModelCapability.textGen,
        ModelCapability.imageIn,
        ModelCapability.audioIn,
      }, size: 5000);
      final npu = entry('npu', caps: c.capabilities, soc: 'sm8850', size: 10);
      final gated = entry('gated', caps: c.capabilities, gated: true, size: 10);
      final req = {
        ModelCapability.textGen,
        ModelCapability.imageIn,
        ModelCapability.audioIn,
      };
      final plan = planDownloads(
        required: req,
        catalog: [a, b, c, npu, gated],
        installed: const [],
        preference: const {},
      );
      expect(plan.map((e) => e.name), ['c']);
      final small = entry('c2', caps: c.capabilities, size: 10);
      final plan2 = planDownloads(
        required: req,
        catalog: [c, small],
        installed: const [],
        preference: const {},
      );
      expect(plan2.map((e) => e.name), ['c2'], reason: 'fewer bytes on a tie');
      final plan3 = planDownloads(
        required: req,
        catalog: [c, small],
        installed: const [],
        preference: {c.id: 100},
      );
      expect(plan3.map((e) => e.name), ['c'], reason: 'preference first');
    });

    test('fitsMemory tolerance', () {
      expect(fitsMemoryForTest(8, 7500000000), isTrue);
      expect(fitsMemoryForTest(12, 11300000000), isTrue);
      expect(fitsMemoryForTest(8, 5600000000), isFalse);
      expect(fitsMemoryForTest(null, 1), isTrue);
    });
  });
}

bool fitsMemoryForTest(int? min, int ram) {
  final e = entry('m', minRam: min);
  return planDownloads(
    required: {ModelCapability.textGen},
    catalog: [e],
    installed: const [],
    preference: const {},
    totalRamBytes: ram,
  ).isNotEmpty;
}
