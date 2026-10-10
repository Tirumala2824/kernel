import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/models/hub_providers.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

// Sizes add up to the ~3.1 GB the consent sheet must show.
final vision = testEntry(
  name: 'Gemma Vision',
  capabilities: {ModelCapability.imageIn, ModelCapability.textGen},
  sizeBytes: 2600000000,
);
final embedder = testEntry(
  name: 'EmbeddingGemma',
  capabilities: {ModelCapability.embedText},
  sizeBytes: 300000000,
  license: 'gemma',
  repoId: 'litert-community/embeddinggemma-300m',
);
final sounds = testEntry(
  name: 'YAMNet',
  capabilities: {ModelCapability.audioClassify},
  sizeBytes: 200000000,
  repoId: 'google/yamnet',
  host: 'storage.googleapis.com',
  source: ModelSource.kernelCatalog,
);

TestEnv hubEnv() {
  final env = TestEnv(role: Role.farmer);
  env.provisioner.catalog = [vision, embedder, sounds];
  env.modelCatalog.all = [vision, embedder, sounds];
  return env;
}

Future<void> openHub(WidgetTester tester, TestEnv env) =>
    pumpKernelApp(tester, env, location: Routes.models);

Finder textContaining(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').contains(part),
);

void main() {
  test('Pest ID needs image understanding, embeddings and a sound classifier',
      () {
    expect(pestIdCapabilities, {
      ModelCapability.imageIn,
      ModelCapability.embedText,
      ModelCapability.audioClassify,
    });
  });

  testWidgets('status card shows each need as installed or missing', (
    tester,
  ) async {
    final env = hubEnv();
    env.modelRegistry.installed = [
      testInstalled(
        path: '/data/models/vision.litertlm',
        capabilities: {ModelCapability.imageIn},
      ),
    ];
    await openHub(tester, env);

    Finder chip(ModelCapability c, String label) => find.descendant(
      of: find.byKey(Key('hub-need-${c.name}')),
      matching: find.text(label),
    );
    expect(chip(ModelCapability.imageIn, en.hubInstalledChip), findsOneWidget);
    expect(chip(ModelCapability.embedText, en.hubMissingChip), findsOneWidget);
    expect(
      chip(ModelCapability.audioClassify, en.hubMissingChip),
      findsOneWidget,
    );
    final card = find.byKey(const Key('hub-status'));
    for (final need in [en.hubNeedImage, en.hubNeedEmbeddings, en.hubNeedSound]) {
      expect(
        find.descendant(of: card, matching: find.text(need)),
        findsOneWidget,
      );
    }
    // Only what is still missing is planned: 300 MB + 200 MB.
    expect(
      find.text(en.hubDownloadSummary(2, en.unitMb('500'))),
      findsOneWidget,
    );
  });

  testWidgets('everything installed: no download offered', (tester) async {
    final env = hubEnv();
    env.modelRegistry.installed = [
      testInstalled(
        path: '/m/all.litertlm',
        capabilities: pestIdCapabilities,
      ),
    ];
    await openHub(tester, env);
    expect(find.byKey(const Key('hub-all-installed')), findsOneWidget);
    expect(find.byKey(const Key('hub-download')), findsNothing);
  });

  group('one-time consent', () {
    testWidgets('lists each model with size, licence, card and source', (
      tester,
    ) async {
      final env = hubEnv();
      await openHub(tester, env);
      await tapVisible(tester, find.byKey(const Key('hub-download')));

      final sheet = find.byKey(const Key('hub-consent-sheet'));
      expect(sheet, findsOneWidget);
      for (final e in [vision, embedder, sounds]) {
        final card = find.byKey(Key('hub-consent-entry-${e.id}'));
        expect(
          find.descendant(of: card, matching: find.text(e.name)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(en.hubConsentLicense(e.license)),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(
              en.hubConsentModelCard('huggingface.co/${e.repoId}'),
            ),
          ),
          findsOneWidget,
        );
      }
      expect(find.text(en.hubConsentSize(en.unitGb('2.6'))), findsOneWidget);
      expect(find.text(en.hubSourceHf), findsNWidgets(2));
      expect(find.text(en.hubSourceGoogle), findsOneWidget);
      expect(
        find.text(en.hubConsentTotal(en.unitGb('3.1'))),
        findsOneWidget,
      );
      final wifi = tester.widget<SwitchListTile>(
        find.byKey(const Key('hub-consent-wifi')),
      );
      expect(wifi.value, isTrue, reason: 'Wi-Fi only is on by default');
    });

    testWidgets('declining never calls ensure()', (tester) async {
      final env = hubEnv();
      await openHub(tester, env);
      await tapVisible(tester, find.byKey(const Key('hub-download')));
      await tapVisible(tester, find.byKey(const Key('hub-consent-decline')));

      expect(find.byKey(const Key('hub-consent-sheet')), findsNothing);
      expect(env.provisioner.consentWrites, isEmpty);
      expect(env.provisioner.ensureCalls, isEmpty);
      expect(find.byKey(const Key('hub-downloads')), findsNothing);

      // The empty installed list offers the same, consent-gated action.
      await tapVisible(
        tester,
        find.descendant(
          of: find.byKey(const Key('hub-installed-empty')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(find.byKey(const Key('hub-consent-sheet')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('hub-consent-decline')));
      expect(env.provisioner.ensureCalls, isEmpty);
    });

    testWidgets('agreeing stores consent with the Wi-Fi choice, then ensures', (
      tester,
    ) async {
      final env = hubEnv();
      await openHub(tester, env);
      await tapVisible(tester, find.byKey(const Key('hub-download')));
      await tapVisible(tester, find.byKey(const Key('hub-consent-wifi')));
      await tapVisible(tester, find.byKey(const Key('hub-consent-agree')));

      expect(env.provisioner.consentWrites, hasLength(1));
      expect(env.provisioner.consent.granted, isTrue);
      expect(env.provisioner.consent.wifiOnly, isFalse);
      expect(env.provisioner.ensureCalls, [pestIdCapabilities]);
      expect(find.byKey(const Key('hub-consent-given')), findsOneWidget);
    });

    testWidgets('with consent already given, no sheet is shown', (
      tester,
    ) async {
      final env = hubEnv();
      await env.provisioner.setConsent(const DownloadConsent(granted: true));
      await openHub(tester, env);
      await tapVisible(tester, find.byKey(const Key('hub-download')));

      expect(find.byKey(const Key('hub-consent-sheet')), findsNothing);
      expect(env.provisioner.ensureCalls, hasLength(1));

      // The Wi-Fi switch stays available after consent.
      await tapVisible(tester, find.byKey(const Key('hub-wifi-only')));
      expect(env.provisioner.consent.wifiOnly, isFalse);
      expect(env.provisioner.consent.granted, isTrue);
    });
  });

  testWidgets('shows every progress phase per entry, with cancel', (
    tester,
  ) async {
    final env = hubEnv();
    await env.provisioner.setConsent(const DownloadConsent(granted: true));
    await openHub(tester, env);
    await tapVisible(tester, find.byKey(const Key('hub-download')));

    Future<void> emit(ProvisionPhase phase, int done, {String? error}) async {
      env.provisioner.emit(
        ProvisionProgress(
          entryId: vision.id,
          phase: phase,
          bytesDone: done,
          totalBytes: vision.sizeBytes,
          error: error,
        ),
      );
      await tester.pumpAndSettle();
    }

    final phase = find.byKey(Key('hub-phase-${vision.id}'));
    String phaseText() => tester.widget<Text>(phase).data!;

    await emit(ProvisionPhase.queued, 0);
    expect(phaseText(), en.hubPhaseQueued);
    expect(
      find.descendant(
        of: find.byKey(Key('hub-progress-${vision.id}')),
        matching: find.text(vision.name),
      ),
      findsOneWidget,
    );

    await emit(ProvisionPhase.waitingForWifi, 0);
    expect(phaseText(), en.hubPhaseWifi);

    await emit(ProvisionPhase.waitingForSpace, 0);
    expect(phaseText(), en.hubPhaseSpace(en.unitGb('2.6')));
    expect(find.text(en.hubFreeSpace(en.unitMb('500'))), findsOneWidget);

    await emit(ProvisionPhase.downloading, 1300000000);
    expect(phaseText(), en.hubPhaseDownloading(en.unitGb('1.3'), en.unitGb('2.6')));

    await tapVisible(tester, find.byKey(Key('hub-cancel-${vision.id}')));
    expect(env.provisioner.cancelled, [vision.id]);

    await emit(ProvisionPhase.paused, 1300000000);
    expect(phaseText(), en.hubPhasePaused);

    await emit(ProvisionPhase.verifying, vision.sizeBytes);
    expect(phaseText(), en.hubPhaseVerifying);

    await emit(ProvisionPhase.failed, 0, error: 'sha256_mismatch');
    expect(phaseText(), en.hubPhaseFailed('sha256_mismatch'));
    expect(find.byKey(Key('hub-cancel-${vision.id}')), findsNothing);

    await emit(ProvisionPhase.installed, vision.sizeBytes);
    expect(phaseText(), en.hubInstalledChip);
    await env.provisioner.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('explains why Gallery files are downloaded again', (
    tester,
  ) async {
    expect(
      en.hubGalleryNote,
      "Kernel can't use files AI Edge Gallery already downloaded (Android "
      "keeps each app's files private), so it downloads the same models "
      'once.',
    );
    await openHub(tester, hubEnv());
    expect(find.byKey(const Key('hub-gallery-note')), findsOneWidget);
    expect(find.text(en.hubGalleryNote), findsOneWidget);
  });

  testWidgets('installed list: details, Gallery badge and remove', (
    tester,
  ) async {
    final env = hubEnv();
    const path = '/data/user/0/com.kernel.kernel_app/files/models/v.litertlm';
    env.modelRegistry.installed = [
      testInstalled(
        path: path,
        capabilities: {ModelCapability.imageIn, ModelCapability.textGen},
        sizeBytes: vision.sizeBytes,
        catalogEntryId: vision.id,
      ),
      testInstalled(
        path: '/m/local.tflite',
        capabilities: {ModelCapability.audioClassify},
        backends: const ['cpu'],
      ),
    ];
    await openHub(tester, env);

    final card = find.byKey(const Key('hub-installed-$path'));
    Finder inCard(String text) =>
        find.descendant(of: card, matching: textContaining(text));
    expect(inCard(vision.name), findsOneWidget);
    expect(inCard(path), findsOneWidget);
    expect(inCard(vision.id), findsOneWidget, reason: 'version');
    expect(inCard(en.unitGb('2.6')), findsOneWidget);
    expect(inCard(en.hubCapImageIn), findsWidgets);
    expect(inCard('GPU, CPU'), findsOneWidget);
    expect(find.byKey(const Key('hub-gallery-match-$path')), findsOneWidget);
    // A local file with no catalog match gets no badge.
    expect(
      find.byKey(const Key('hub-gallery-match-/m/local.tflite')),
      findsNothing,
    );
    expect(textContaining('local@'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('hub-remove-$path')));
    await tapVisible(tester, find.byKey(const Key('confirm-ok')));
    expect(env.provisioner.removed, [path]);
    expect(env.modelRegistry.rescans, 1);
    expect(card, findsNothing);
  });

  group('semantic search', () {
    testWidgets('searches models and pest info and shows scores', (
      tester,
    ) async {
      final env = hubEnv();
      env.modelSearch.hits = [
        ModelSearchHit(
          score: 0.82,
          title: 'EmbeddingGemma',
          entry: embedder,
          snippet: 'Text embeddings for search',
        ),
      ];
      env.knowledge.hits = [KnowledgeHit(card: testCard(), score: 0.64)];
      await openHub(tester, env);

      await tester.enterText(
        find.byKey(const Key('hub-search-field')),
        ' rice weevil ',
      );
      await tapVisible(tester, find.byKey(const Key('hub-search-go')));

      expect(env.modelSearch.queries, ['rice weevil']);
      expect(env.knowledge.queries, ['rice weevil']);
      final models = find.byKey(const Key('hub-search-models'));
      final cards = find.byKey(const Key('hub-search-cards'));
      expect(
        find.descendant(of: models, matching: find.text('EmbeddingGemma')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: models, matching: find.text(en.hubSearchScore('0.82'))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cards, matching: find.text('Rice weevil')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cards, matching: find.text(en.hubSearchScore('0.64'))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cards, matching: find.text(en.hubNeedsReview)),
        findsOneWidget,
      );
    });

    testWidgets('one failing source does not hide the other', (tester) async {
      final env = hubEnv();
      env.modelSearch.failWith = StateError('no embedder');
      env.knowledge.hits = [KnowledgeHit(card: testCard(), score: 0.5)];
      await openHub(tester, env);

      await tester.enterText(find.byKey(const Key('hub-search-field')), 'rat');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(textContaining('no embedder'), findsOneWidget);
      expect(find.text('Rice weevil'), findsOneWidget);
    });

    testWidgets('no hits says so', (tester) async {
      final env = hubEnv();
      await openHub(tester, env);
      await tester.enterText(find.byKey(const Key('hub-search-field')), 'zz');
      await tapVisible(tester, find.byKey(const Key('hub-search-go')));
      expect(find.text(en.hubSearchNoResults), findsNWidgets(2));
    });
  });
}
