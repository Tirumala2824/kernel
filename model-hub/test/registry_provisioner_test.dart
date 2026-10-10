import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:model_hub/model_hub.dart';

import 'support/doubles.dart';

const models = '/ext/files/models';
const legacy = '/ext/files/llm';

void main() {
  late ScriptedPlatform platform;
  late HeaderProbe probe;
  late RecordingHttp http;

  ModelHub hub({Embedder? embedder}) => ModelHub.withPlatform(
    platform: platform,
    http: http,
    probe: probe,
    embedder: embedder,
    assets: FileAssets(),
    storageDir: tempDir(),
  );

  setUp(() {
    platform = ScriptedPlatform()
      ..hubPaths = const HubPaths(
        filesDir: '/data/files',
        modelsDir: models,
        legacyLlmDir: legacy,
      );
    probe = HeaderProbe();
    http = RecordingHttp();
  });

  group('registry', () {
    test('recognises a Gallery copy in the legacy dir by size + sha256', () async {
      const galleryCopy = '$legacy/gemma-4-E2B-it.litertlm';
      platform.addFile(galleryCopy, gemmaSize, gemmaSha);
      probe.results[galleryCopy] = const ModelProbeResult(
        kind: ProbedKind.llm,
        inputModalities: {'text', 'vision', 'audio'},
        backends: ['gpu', 'cpu'],
        maxContextTokens: 32000,
      );
      final h = hub();
      await h.registry.rescan();
      final m = (await h.registry.watchInstalled().first).single;
      expect(m.catalogEntryId, gemmaId);
      expect(m.version, gemmaId);
      expect(m.kind, InstalledModelKind.llm);
      expect(m.capabilities, {
        ModelCapability.textGen,
        ModelCapability.imageIn,
        ModelCapability.audioIn,
      });
      expect(m.backends, ['gpu', 'cpu']);
      expect(m.maxContextTokens, 32000);
    });

    test('tflite files take catalog capabilities; unknown files stay local', () async {
      const y = '$models/mediapipe__yamnet/4d8b4a53282dc83ef04e3e7dbc4fbc98082e34e4/yamnet.tflite';
      const other = '$models/x__y/${'a'}/other.litertlm';
      platform
        ..addFile(y, yamnetSize, yamnetSha)
        ..addFile(other, 10, 'b' * 64);
      final h = hub();
      await h.registry.rescan();
      final list = await h.registry.watchInstalled().first;
      final yam = list.firstWhere((m) => m.path == y);
      expect(yam.kind, InstalledModelKind.tflite);
      expect(yam.capabilities, {ModelCapability.audioClassify});
      expect(yam.catalogEntryId, yamnetId);
      final o = list.firstWhere((m) => m.path == other);
      expect(o.catalogEntryId, isNull);
      expect(o.version, 'local@bbbbbbbbbbbb');
      expect(o.kind, InstalledModelKind.unknown, reason: 'probe returned null');
      expect(probe.calls, [other], reason: 'only .litertlm files are probed');
    });

    test('files are hashed and probed once per (path, size, mtime)', () async {
      const p = '$models/a/b/e.litertlm';
      platform.addFile(p, embedSize, embedSha);
      probe.results[p] = const ModelProbeResult(
        kind: ProbedKind.embedding,
        inputModalities: {'text', 'vision'},
        backends: ['gpu'],
        embeddingDim: 768,
      );
      final h = hub();
      await h.registry.rescan();
      await h.registry.rescan();
      expect(platform.shaCalls, [p]);
      expect(probe.calls, [p]);
      platform.files
        ..clear()
        ..add(const ModelFileInfo(path: p, sizeBytes: embedSize, modifiedMs: 2000));
      await h.registry.rescan();
      expect(platform.shaCalls, [p, p], reason: 'mtime changed');
      final m = (await h.registry.watchInstalled().first).single;
      expect(m.capabilities, {ModelCapability.embedText, ModelCapability.embedImage});
      expect(m.embeddingDim, 768);
    });

    test('bestFor: capability, kind, catalog preference and device RAM', () async {
      const e1 = '$models/k/e.litertlm';
      const e2 = '$legacy/other-embedder.litertlm';
      const llm = '$legacy/gemma-4-E2B-it.litertlm';
      platform
        ..addFile(e1, embedSize, embedSha)
        ..addFile(e2, 999, 'c' * 64)
        ..addFile(llm, gemmaSize, gemmaSha);
      const emb = ModelProbeResult(
        kind: ProbedKind.embedding,
        inputModalities: {'text'},
        backends: ['gpu'],
      );
      probe.results[e1] = emb;
      probe.results[e2] = emb;
      probe.results[llm] = const ModelProbeResult(
        kind: ProbedKind.llm,
        inputModalities: {'text'},
        backends: ['gpu'],
      );
      final h = hub();
      expect((await h.registry.bestFor(ModelCapability.embedText))!.path, e1,
          reason: 'Kernel catalog preference beats an unknown local file');
      expect(await h.pathFor(ModelCapability.textGen), llm);
      expect(await h.registry.bestFor(ModelCapability.segment), isNull);

      // Gemma 4 E2B needs 8 GB: not offered on a 4 GB phone.
      platform.deviceProfile = const DeviceProfile(totalRamBytes: 3800000000, sdkInt: 34);
      expect(await h.registry.bestFor(ModelCapability.textGen), isNull);
    });
  });

  group('provisioner', () {
    test('consent defaults to off and Wi-Fi only; persists changes', () async {
      final h = hub();
      final seen = <DownloadConsent>[];
      final sub = h.provisioner.watchConsent().listen(seen.add);
      await pumpEventQueue();
      await h.provisioner.setConsent(
        const DownloadConsent(granted: true, wifiOnly: false),
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first.granted, isFalse);
      expect(seen.first.wifiOnly, isTrue);
      expect(seen.last.granted, isTrue);
      expect(seen.last.wifiOnly, isFalse);
    });

    test('ensure without consent schedules nothing', () async {
      final h = hub();
      final events = await h.provisioner
          .ensure({ModelCapability.audioClassify})
          .toList();
      expect(events.single.phase, ProvisionPhase.failed);
      expect(events.single.error, 'consent_required');
      expect(platform.enqueued, isEmpty);
    });

    test('ensure enqueues the pinned plan, forwards progress, then rescans', () async {
      final h = hub();
      await h.provisioner.setConsent(const DownloadConsent(granted: true));
      expect(
        (await h.provisioner.plan({ModelCapability.audioClassify})).map((e) => e.id),
        [yamnetId],
      );
      platform.onEnqueue = (r) {
        scheduleMicrotask(() {
          platform.progressCtl
            ..add(ProvisionProgress(
              entryId: r.entry.id,
              phase: ProvisionPhase.downloading,
              bytesDone: 100,
              totalBytes: r.entry.sizeBytes,
            ))
            ..add(const ProvisionProgress(
              entryId: 'someone-else',
              phase: ProvisionPhase.installed,
              bytesDone: 1,
              totalBytes: 1,
            ));
          platform.addFile(
            '$models/mediapipe__yamnet/${r.entry.revision}/yamnet.tflite',
            yamnetSize,
            yamnetSha,
          );
          platform.progressCtl.add(ProvisionProgress(
            entryId: r.entry.id,
            phase: ProvisionPhase.installed,
            bytesDone: r.entry.sizeBytes,
            totalBytes: r.entry.sizeBytes,
          ));
        });
        return ProvisionProgress(
          entryId: r.entry.id,
          phase: ProvisionPhase.queued,
          bytesDone: 0,
          totalBytes: r.entry.sizeBytes,
        );
      };
      final events = await h.provisioner
          .ensure({ModelCapability.audioClassify})
          .toList();
      final r = platform.enqueued.single;
      expect(r.entry.id, yamnetId);
      expect(r.sha256, yamnetSha);
      expect(r.wifiOnly, isTrue);
      expect(r.entry.downloadUrl,
          'https://storage.googleapis.com/mediapipe-models/audio_classifier/yamnet/float32/1/yamnet.tflite');
      expect(
        events.map((e) => e.phase),
        containsAllInOrder([ProvisionPhase.downloading, ProvisionPhase.installed]),
      );
      expect(events.last.phase, ProvisionPhase.installed);
      expect(events.every((e) => e.entryId == yamnetId), isTrue);
      // The new file is registered and nothing is left to plan.
      expect(await h.pathFor(ModelCapability.audioClassify), contains('yamnet.tflite'));
      expect(await h.provisioner.plan({ModelCapability.audioClassify}), isEmpty);
    });

    test('a failed native state ends the stream with its reason', () async {
      final h = hub();
      await h.provisioner.setConsent(const DownloadConsent(granted: true));
      platform.onEnqueue = (r) => ProvisionProgress(
        entryId: r.entry.id,
        phase: ProvisionPhase.waitingForSpace,
        bytesDone: 0,
        totalBytes: r.entry.sizeBytes,
        error: 'insufficient_space',
      );
      final events = await h.provisioner
          .ensure({ModelCapability.embedText})
          .toList();
      expect(events.single.error, 'insufficient_space');
      expect(events.single.entryId, embedId);
    });

    test('cancel, remove and free space go to the native side', () async {
      const p = '$models/a/b/e.litertlm';
      platform.addFile(p, embedSize, embedSha);
      final h = hub();
      await h.registry.rescan();
      await h.provisioner.cancel(embedId);
      await h.provisioner.remove(p);
      expect(platform.cancelled, [embedId]);
      expect(platform.removed, [p]);
      expect(await h.registry.watchInstalled().first, isEmpty);
      expect(await h.provisioner.freeSpaceBytes(), platform.free);
    });
  });
}
