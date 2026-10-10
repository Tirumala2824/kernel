import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/src/hf_api.dart';

import 'support/doubles.dart';

void main() {
  const sha = '86b903a293f96d042bb92e1b7af333d94114458f';

  test('revision API: sha, gated, licence tag and LFS sha256', () {
    final info = parseRevisionInfo(
      'litert-community/embeddinggemma-2-740m-litert-lm',
      revisionBody(
        id: 'litert-community/embeddinggemma-2-740m-litert-lm',
        sha: sha,
        files: {
          '.gitattributes': (1586, null),
          'embeddinggemma-2-740m.litertlm': (embedSize, embedSha),
        },
      ),
    )!;
    expect(info.sha, sha);
    expect(info.gated, isFalse);
    expect(info.license, 'apache-2.0');
    expect(info.files['embeddinggemma-2-740m.litertlm']!.sha256, embedSha);
    expect(info.files['.gitattributes']!.sha256, isNull);
    // Round trip through the cache format.
    final back = HfRevisionInfo.fromJson(info.toJson())!;
    expect(back.files['embeddinggemma-2-740m.litertlm']!.size, embedSize);
  });

  test('gated "manual"/"auto" count as gated; a branch name is not a pin', () {
    for (final g in ['manual', 'auto']) {
      final info = parseRevisionInfo(
        'google/x',
        revisionBody(id: 'google/x', sha: 'b' * 40, gated: g, license: 'gemma', files: {}),
      )!;
      expect(info.gated, isTrue);
      expect(info.license, 'gemma');
    }
    expect(
      parseRevisionInfo('o/x', revisionBody(id: 'o/x', sha: 'main', files: {})),
      isNull,
    );
    expect(parseRevisionInfo('o/x', '[]'), isNull);
  });

  test('Link rel=next paging, only on huggingface.co', () {
    const header =
        '<https://huggingface.co/api/models?author=litert-community&filter=litert-lm'
        '&sort=downloads&direction=-1&limit=3&cursor=eyIk%3D>; rel="next"';
    expect(nextLink(header)!.queryParameters['cursor'], 'eyIk=');
    expect(nextLink('<https://evil.example/api>; rel="next"'), isNull);
    expect(nextLink('<https://huggingface.co/a>; rel="prev"'), isNull);
    expect(nextLink(null), isNull);
  });

  test('search results parse; private repos are skipped', () {
    final hits = parseSearch(
      '[{"id":"litert-community/a","downloads":5,"tags":["license:mit"]},'
      '{"id":"litert-community/b","private":true},{"x":1}]',
    )!;
    expect(hits.map((h) => h.id), ['litert-community/a']);
    expect(parseSearch('{}'), isNull);
  });

  test('search entries keep generic files and drop NPU and web builds', () {
    final info = parseRevisionInfo(
      'litert-community/embeddinggemma-2-740m-litert-lm',
      revisionBody(
        id: 'litert-community/embeddinggemma-2-740m-litert-lm',
        sha: 'c' * 40,
        files: {
          'embeddinggemma-2-740m.litertlm': (embedSize, embedSha),
          'embeddinggemma-2-740m_Qualcomm_SM8850.litertlm': (559448064, 'd' * 64),
          'embeddinggemma-2-740m_MediaTek_MT6993.litertlm': (864681984, 'e' * 64),
          'embeddinggemma-2-740m_Google_Tensor_G5.litertlm': (657656500, 'f' * 64),
          'README.md': (100, null),
        },
      ),
    )!;
    final entries = entriesFromRevision(info);
    expect(entries.single.fileName, 'embeddinggemma-2-740m.litertlm');
    expect(entries.single.capabilities, {ModelCapability.embedText});
    expect(entries.single.source, ModelSource.huggingFaceSearch);
    expect(entries.single.revision, 'c' * 40);
    expect(isSocSpecificFile('gemma-4-E2B-it_qualcomm_sm8750.litertlm'), isTrue);
    expect(isSocSpecificFile('gemma-4-E2B-it-web.task'), isTrue);
    expect(isSocSpecificFile('multi-input-model.litertlm'), isFalse);
  });

  test('revision facts fill a Gallery entry pinned to that revision', () {
    final e = CatalogEntry(
      id: 'x',
      name: 'x',
      repoId: 'litert-community/embeddinggemma-2-740m-litert-lm',
      revision: sha,
      fileName: 'embeddinggemma-2-740m.litertlm',
      sizeBytes: embedSize,
      sha256: null,
      format: ModelFormat.litertlm,
      capabilities: const {ModelCapability.embedText},
      license: 'unknown',
      gated: true,
      source: ModelSource.galleryCatalog,
      downloadUrl: 'https://huggingface.co/x',
    );
    final info = parseRevisionInfo(
      e.repoId,
      revisionBody(
        id: e.repoId,
        sha: sha,
        files: {'embeddinggemma-2-740m.litertlm': (embedSize, embedSha)},
      ),
    )!;
    final out = applyRevisionInfo(e, info);
    expect(out.sha256, embedSha);
    expect(out.license, 'apache-2.0');
    expect(out.gated, isFalse);
    expect(out.source, ModelSource.galleryCatalog);
  });
}
