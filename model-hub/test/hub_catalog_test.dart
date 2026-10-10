import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';

import 'support/doubles.dart';

const galleryUrl =
    'https://raw.githubusercontent.com/google-ai-edge/gallery/refs/heads/main/model_allowlists/1_0_20.json';
const gemma3Rev = '42d538a932e8d5b12e6b3b455f5572560bd60b2c';

HubHttpResponse? hfAndGallery(Uri uri, Map<String, String> headers) {
  final url = uri.toString();
  if (url.startsWith('https://raw.githubusercontent.com/')) {
    if (url != galleryUrl) return null;
    if (headers['If-None-Match'] == '"g1"') {
      return HubHttpResponse(status: 304, headers: const {}, body: '');
    }
    return ok(readAsset('gallery_allowlist_1_0_20.json'), {'ETag': '"g1"'});
  }
  if (uri.host != 'huggingface.co') return null;
  final p = uri.path;
  if (p == '/api/models') {
    if (uri.queryParameters['cursor'] == 'p2') {
      return ok('[{"id":"litert-community/Extra","downloads":1}]');
    }
    final next = uri.replace(
      queryParameters: {...uri.queryParameters, 'cursor': 'p2'},
    );
    return ok(
      '[{"id":"litert-community/gemma-4-E2B-it-litert-lm","downloads":9},'
      '{"id":"litert-community/Qwen-test","downloads":5}]',
      {'Link': '<$next>; rel="next"'},
    );
  }
  if (p == '/api/models/litert-community/Gemma3-1B-IT/revision/$gemma3Rev') {
    return ok(
      revisionBody(
        id: 'litert-community/Gemma3-1B-IT',
        sha: gemma3Rev,
        files: {'gemma3-1b-it-int4.litertlm': (584417280, '1' * 64)},
      ),
    );
  }
  if (p.startsWith('/api/models/google/gemma-3n-E2B-it-litert-lm/revision/')) {
    return ok(
      revisionBody(
        id: 'google/gemma-3n-E2B-it-litert-lm',
        sha: p.split('/').last,
        gated: 'manual',
        license: 'gemma',
        files: {'gemma-3n-E2B-it-int4.litertlm': (3655827456, '2' * 64)},
      ),
    );
  }
  if (p == '/api/models/litert-community/Qwen-test/revision/main') {
    return ok(
      revisionBody(
        id: 'litert-community/Qwen-test',
        sha: '9' * 40,
        files: {
          'qwen.litertlm': (1000, '3' * 64),
          'qwen_qualcomm_sm8850.litertlm': (1200, '4' * 64),
        },
      ),
    );
  }
  if (p == '/api/models/litert-community/gemma-4-E2B-it-litert-lm/revision/main') {
    return ok(
      revisionBody(
        id: 'litert-community/gemma-4-E2B-it-litert-lm',
        sha: '7' * 40,
        files: {'gemma-4-E2B-it.litertlm': (2588147000, '5' * 64)},
      ),
    );
  }
  return null;
}

void main() {
  late ScriptedPlatform platform;
  late RecordingHttp http;
  late DateTime now;

  ModelHub hub({String? dir}) => ModelHub.withPlatform(
    platform: platform,
    http: http,
    probe: HeaderProbe(),
    assets: FileAssets(),
    storageDir: tempDir(),
    clock: () => now,
  );

  setUp(() {
    platform = ScriptedPlatform();
    http = RecordingHttp(hfAndGallery);
    now = DateTime(2026, 10, 10, 12);
  });

  test('without consent: zero network, Kernel + bundled Gallery snapshot', () async {
    final h = hub();
    final entries = await h.catalog.entries(refresh: true);
    expect(http.requests, isEmpty);
    expect(entries, hasLength(13));
    expect(entries.first.source, ModelSource.kernelCatalog);
  });

  test('with consent on Wi-Fi: daily Gallery fetch, HF enrichment and search', () async {
    final h = hub();
    await h.provisioner.setConsent(const DownloadConsent(granted: true));
    final entries = await h.catalog.entries();
    expect(http.uris.map((u) => u.toString()), contains(galleryUrl));
    expect(
      http.uris.where((u) => u.path == '/api/models'),
      hasLength(2),
      reason: 'search followed Link rel=next once',
    );

    final g3 = entries.firstWhere((e) => e.repoId == 'litert-community/Gemma3-1B-IT');
    expect(g3.sha256, '1' * 64);
    expect(g3.license, 'apache-2.0');
    expect(g3.gated, isFalse);
    expect(downloadBlockReason(g3), isNull);
    final g3n = entries.firstWhere((e) => e.repoId == 'google/gemma-3n-E2B-it-litert-lm');
    expect(downloadBlockReason(g3n), 'gated');

    final qwen = entries.where((e) => e.repoId == 'litert-community/Qwen-test');
    expect(qwen.single.fileName, 'qwen.litertlm', reason: 'NPU file dropped');
    expect(qwen.single.source, ModelSource.huggingFaceSearch);
    final gemma4 = entries.where((e) => e.repoId.endsWith('gemma-4-E2B-it-litert-lm'));
    expect(gemma4.single.id, gemmaId, reason: 'Kernel pin shadows search main');

    // Same day: no network at all.
    final before = http.requests.length;
    await h.catalog.entries();
    expect(http.requests.length, before);
    await h.catalog.entries(refresh: true);
    expect(
      http.uris.skip(before).where(
        (u) => u.toString() == galleryUrl || u.path == '/api/models',
      ),
      isEmpty,
      reason: 'at most once a day, even on refresh',
    );

    // Next day: conditional request with the stored ETag (304 keeps cache).
    now = now.add(const Duration(hours: 25));
    final next = await h.catalog.entries();
    final galleryCalls = http.requests.where((r) => r.$1.toString() == galleryUrl).toList();
    expect(galleryCalls, hasLength(2));
    expect(galleryCalls.last.$2['If-None-Match'], '"g1"');
    expect(next.where((e) => e.source == ModelSource.galleryCatalog), isNotEmpty);
  });

  test('Wi-Fi only consent on a metered network makes no requests', () async {
    platform.net = const NetworkStatus(connected: true, unmetered: false);
    final h = hub();
    await h.provisioner.setConsent(const DownloadConsent(granted: true));
    await h.catalog.entries(refresh: true);
    expect(http.requests, isEmpty);

    final h2 = hub();
    await h2.provisioner.setConsent(
      const DownloadConsent(granted: true, wifiOnly: false),
    );
    await h2.catalog.entries(refresh: true);
    expect(http.requests, isNotEmpty);
  });

  test('a 429 from HF backs off all further HF calls', () async {
    http.handler = (uri, headers) {
      if (uri.host == 'huggingface.co') {
        return HubHttpResponse(
          status: 429,
          headers: const {'RateLimit': '"api";r=0;t=120'},
          body: '',
        );
      }
      return hfAndGallery(uri, headers);
    };
    final h = hub();
    await h.provisioner.setConsent(const DownloadConsent(granted: true));
    final entries = await h.catalog.entries();
    expect(http.uris.where((u) => u.host == 'huggingface.co'), hasLength(1));
    expect(entries, isNotEmpty);
  });

  test('unknown Gallery version falls back to the snapshot version URL', () async {
    platform.deviceProfile = const DeviceProfile(
      totalRamBytes: 11500000000,
      sdkInt: 36,
      galleryVersionName: '1.0.99',
    );
    final h = hub();
    await h.provisioner.setConsent(const DownloadConsent(granted: true));
    await h.catalog.entries();
    List<Uri> raw() =>
        http.uris.where((u) => u.host == 'raw.githubusercontent.com').toList();
    expect(raw().map((u) => u.pathSegments.last), ['1_0_99.json', '1_0_20.json']);
    await h.catalog.entries(refresh: true);
    expect(raw(), hasLength(2), reason: 'the fallback also counts for the day');
  });

  test('network errors fall back to the bundled snapshot and never throw', () async {
    http.handler = (uri, headers) => throw StateError('offline');
    final h = hub();
    await h.provisioner.setConsent(const DownloadConsent(granted: true));
    final entries = await h.catalog.entries(refresh: true);
    expect(entries, hasLength(13));
  });

  test('IoHubHttp refuses hosts outside the catalog allow-list', () async {
    expect(IoHubHttp.allows(Uri.parse(galleryUrl)), isTrue);
    expect(IoHubHttp.allows(Uri.parse('https://huggingface.co/api/models')), isTrue);
    expect(IoHubHttp.allows(Uri.parse('http://huggingface.co/api/models')), isFalse);
    expect(IoHubHttp.allows(Uri.parse('https://example.com/x.json')), isFalse);
    expect(
      () => IoHubHttp().get(Uri.parse('https://example.com/x.json')),
      throwsA(isA<Exception>()),
    );
  });
}
