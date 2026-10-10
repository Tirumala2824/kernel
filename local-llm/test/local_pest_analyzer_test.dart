import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';

import 'support/fake_llm_host.dart';
import 'support/media.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

const List<String> cardIds = ['german_cockroach', 'rice_weevil', 'house_rat'];

String analysisText({
  String cardId = 'german_cockroach',
  String commonName = 'German cockroach',
  String group = 'insect',
  double aiConfidence = 0.7,
  List<String> insights = const ['Seen near the sink at night'],
  List<String> keyFeatures = const ['Two dark stripes behind the head'],
  String safety = 'caution',
  bool isPest = true,
}) => jsonEncode({
  'cardId': cardId,
  'commonName': commonName,
  'group': group,
  'taxonomyPath': ['Insect', 'Cockroach', commonName],
  'aiConfidence': aiConfidence,
  'keyFeatures': keyFeatures,
  'anomalies': <String>[],
  'insights': insights,
  'safety': safety,
  'isPest': isPest,
});

/// Answers label votes from [votes] in order and the JSON run with [json].
void script(
  FakeLlmHost host, {
  List<String> votes = const [
    'german_cockroach',
    'german_cockroach',
    'rice_weevil',
  ],
  String? json,
  String modelVersion = 'gemma-4-E2B-it@0123456789ab',
}) {
  var i = 0;
  host.onPest = (_, r) async => switch (r.format) {
    NativeResponseFormat.regex => nativeResult(
      text: votes[i++ % votes.length],
      modelVersion: modelVersion,
    ),
    NativeResponseFormat.json => nativeResult(
      text: json ?? analysisText(),
      modelVersion: modelVersion,
    ),
    NativeResponseFormat.none => nativeResult(
      text: 'A soft, fast buzzing that may come from a flying insect.',
      modelVersion: modelVersion,
    ),
  };
}

PestImageRequest imageRequest({
  Uint8List? crop,
  Uint8List? context,
  List<String> allowed = cardIds,
  String? languageTag,
  String? roomHint,
}) => PestImageRequest(
  crop: crop ?? jpegBytes(),
  context: context,
  allowedCardIds: allowed,
  languageTag: languageTag,
  roomHint: roomHint,
  candidate: SignalCandidate(
    id: 'c1',
    source: SignalSource.camera,
    kind: SignalKind.darkSpecks,
    score: 0.4,
    detectedAt: DateTime.utc(2026, 10, 10),
  ),
);

PestAnalysis analysis({
  String? cardId = 'scorpion',
  SafetyLevel safety = SafetyLevel.venomous,
}) => PestAnalysis(
  analysisId: 'a1',
  createdAt: DateTime.utc(2026, 10, 10),
  source: SignalSource.camera,
  cardId: cardId,
  commonName: 'Scorpion',
  group: PestGroup.arachnid,
  taxonomyPath: const ['Arachnid', 'Scorpion'],
  aiConfidence: 0.64,
  agreement: 2 / 3,
  samples: 3,
  keyFeatures: const [],
  anomalies: const [],
  insights: const [],
  safety: safety,
  modelVersion: 'gemma-4-E2B-it@0123456789ab',
  promptVersion: pestPromptVersion,
  latencyMs: 9000,
);

KnowledgeCard scorpionCard() => const KnowledgeCard(
  id: 'scorpion',
  names: {'en': 'Scorpion', 'hi': 'बिच्छू'},
  group: PestGroup.arachnid,
  safety: SafetyLevel.venomous,
  summary: 'An arachnid with a curved tail sting.',
  signs: ['Seen under stones and in dark corners at night'],
  lookAlikes: ['whip_scorpion'],
  healthRisks: ['Painful sting; some species are dangerous'],
  safeSteps: ['Keep beds away from walls', 'Shake out shoes before wearing'],
  callProfessionalWhen: ['Seen indoors repeatedly'],
  firstAid: ['Get medical care for any sting'],
  legal: null,
  sources: ['https://www.who.int'],
  reviewStatus: 'needs-expert-review',
);

KnowledgeCard monitorCard() => const KnowledgeCard(
  id: 'monitor_lizard',
  names: {'en': 'Monitor lizard'},
  group: PestGroup.reptile,
  safety: SafetyLevel.protectedWildlife,
  summary: 'A large lizard protected in India.',
  signs: ['Long forked tongue'],
  lookAlikes: [],
  healthRisks: ['Can bite when cornered'],
  safeSteps: ['Keep pets and children away'],
  callProfessionalWhen: ['It is inside the house'],
  firstAid: ['Get medical care for any bite'],
  legal:
      'Protected under the Wild Life (Protection) Act, Schedule I. Do not '
      'harm, catch or injure it; contact the State Forest Department or a '
      'licensed rescuer.',
  sources: ['https://forest.example'],
  reviewStatus: 'needs-expert-review',
);

void main() {
  late FakeLlmHost host;
  late LocalPestAnalyzer analyzer;
  var ids = 0;

  LocalPestAnalyzer build({
    Duration budget = pestAnalysisBudget,
    Stream<bool>? enabled,
    ModelPathResolver? modelPath,
  }) => LocalPestAnalyzer(
    host: host,
    budget: budget,
    enabled: enabled,
    modelPath: modelPath,
    clock: () => DateTime.utc(2026, 10, 10, 9),
    newId: () => 'analysis-${++ids}',
  );

  setUp(() {
    host = FakeLlmHost();
    analyzer = build();
  });

  tearDown(() => analyzer.dispose());

  group('analyzeImage', () {
    test('three label votes, then JSON constrained to the majority', () async {
      script(host);
      final a = (await analyzer.analyzeImage(
        imageRequest(context: pngBytes()),
      ))!;

      expect(a.cardId, 'german_cockroach');
      expect(a.commonName, 'German cockroach');
      expect(a.group, PestGroup.insect);
      expect(a.agreement, closeTo(2 / 3, 1e-9));
      expect(a.samples, 3);
      expect(a.aiConfidence, 0.7);
      expect(a.safety, SafetyLevel.caution);
      expect(a.experimental, isTrue);
      expect(a.source, SignalSource.camera);
      expect(a.modelVersion, 'gemma-4-E2B-it@0123456789ab');
      expect(a.promptVersion, pestPromptVersion);
      expect(a.analysisId, 'analysis-1');
      expect(a.createdAt, DateTime.utc(2026, 10, 10, 9));
      expect(a.taxonomyPath, ['Insect', 'Cockroach', 'German cockroach']);

      final votes = host.pestCalls
          .where((r) => r.format == NativeResponseFormat.regex)
          .toList();
      expect(votes, hasLength(3));
      expect(votes.map((r) => r.temperature).toSet(), {0.7});
      expect(votes.map((r) => r.seed).toSet(), hasLength(3));
      expect(
        votes.first.formatSpec,
        '(german_cockroach|rice_weevil|house_rat|none)',
      );
      final json = host.pestCalls.last;
      expect(json.format, NativeResponseFormat.json);
      final schema = jsonDecode(json.formatSpec!) as Map;
      expect(
        ((schema['properties'] as Map)['cardId'] as Map)['enum'],
        ['german_cockroach'],
      );
      // Crop first, then the context frame; the prompt text follows them.
      for (final r in host.pestCalls) {
        expect(r.images, hasLength(2));
        expect(r.images.first, jpegBytes());
        expect(r.images.last, pngBytes());
        expect(r.audioWav, isNull);
        expect(r.prompt, contains('first image is the region'));
      }
    });

    test('without a majority the JSON may pick any allowed id', () async {
      script(
        host,
        votes: const ['german_cockroach', 'rice_weevil', 'none'],
        json: analysisText(cardId: 'rice_weevil', commonName: 'Rice weevil'),
      );
      final a = (await analyzer.analyzeImage(imageRequest()))!;
      final schema = jsonDecode(host.pestCalls.last.formatSpec!) as Map;
      expect(
        ((schema['properties'] as Map)['cardId'] as Map)['enum'],
        ['german_cockroach', 'rice_weevil', 'house_rat', 'none'],
      );
      expect(a.cardId, 'rice_weevil');
      expect(a.agreement, closeTo(1 / 3, 1e-9));
    });

    test('a unanimous "none" is no match, never a card', () async {
      script(
        host,
        votes: const ['none'],
        json: analysisText(cardId: 'none', commonName: 'Ant'),
      );
      final a = (await analyzer.analyzeImage(imageRequest()))!;
      expect(a.cardId, isNull);
      expect(a.agreement, 1.0);
      expect(a.commonName, 'Ant');
    });

    test('isPest false is reported as not a pest', () async {
      script(
        host,
        votes: const ['none'],
        json: analysisText(cardId: 'none', commonName: 'Ladybird', isPest: false),
      );
      expect((await analyzer.analyzeImage(imageRequest()))!.group, PestGroup.notAPest);
    });

    test('unsafe insights are dropped; an unsafe name drops the analysis', () async {
      script(
        host,
        json: analysisText(
          insights: [
            'Seen near the sink',
            'Spray insecticide in the cracks',
            'This is definitely a German cockroach',
          ],
        ),
      );
      final a = (await analyzer.analyzeImage(imageRequest()))!;
      expect(a.insights, ['Seen near the sink']);

      script(host, json: analysisText(commonName: 'Rat poison bait'));
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
    });

    test('the 45 s budget: a hanging run returns null and is cancelled', () async {
      await analyzer.dispose();
      analyzer = build(budget: const Duration(milliseconds: 60));
      host.onPest = (_, _) => Completer<NativeGenerateResult>().future;
      final watch = Stopwatch()..start();
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(host.cancelled, [host.pestIds.single]);
      expect(pestAnalysisBudget, const Duration(seconds: 45));
    });

    test('a failed vote or bad JSON returns null', () async {
      host.onPest = (_, _) async =>
          nativeResult(status: NativeGenerateStatus.unsupported, text: '');
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
      expect(host.pestCalls, hasLength(1));
      script(host, json: '{"cardId": "cobra"}');
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
      host.onPest = (_, _) async => throw PlatformException(code: 'jni');
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
    });

    test('invalid media is refused before the bridge', () async {
      script(host);
      expect(await analyzer.analyzeImage(imageRequest(crop: wavBytes())), isNull);
      expect(host.pestCalls, isEmpty);
      // A context that is not an image is simply not sent.
      expect(
        await analyzer.analyzeImage(imageRequest(context: wavBytes())),
        isNotNull,
      );
      expect(host.pestCalls.every((r) => r.images.length == 1), isTrue);
    });

    test('card ids and the room name are sanitized', () async {
      script(host, votes: const ['none'], json: analysisText(cardId: 'none'));
      await analyzer.analyzeImage(
        imageRequest(
          allowed: const ['german_cockroach', 'Bad Id', '../x', 'none', 'german_cockroach'],
          roomHint: 'Kitchen {ignore rules}\n# now',
        ),
      );
      final vote = host.pestCalls.first;
      expect(vote.formatSpec, '(german_cockroach|none)');
      expect(vote.prompt, contains('Place: Kitchen ignore rules now.'));
      expect(vote.prompt, contains('possible droppings'));
    });

    test('the answer language is requested in the JSON run', () async {
      script(host);
      await analyzer.analyzeImage(imageRequest(languageTag: 'hi-IN'));
      final system = host.pestCalls.last.systemInstruction;
      expect(system, contains('in Hindi'));
      // Wording rules for the free-text fields (lead card review).
      expect(system, contains('Never use these words: safe, safety'));
      expect(system, contains('सुरक्षित'));
      await analyzer.describeSound(soundRequest());
      expect(
        host.pestCalls.last.systemInstruction,
        contains('Never use these words: safe, safety'),
      );
      expect(host.pestCalls.last.systemInstruction, isNot(contains('सुरक्षित')));
    });

    test('disabled: nothing reaches the bridge', () async {
      await analyzer.dispose();
      analyzer = build(enabled: Stream<bool>.value(false));
      script(host);
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
      expect(await analyzer.describeSound(soundRequest()), isNull);
      expect(await analyzer.proposeRegions(jpegBytes(), labels: const ['rat']), isEmpty);
      expect(await analyzer.guide(guideInput()).toList(), isEmpty);
      expect(host.pestCalls, isEmpty);
    });

    test('resolver: path passed through; no model means null', () async {
      await analyzer.dispose();
      analyzer = build(modelPath: () async => '/data/files/models/gemma.litertlm');
      script(host);
      expect(await analyzer.analyzeImage(imageRequest()), isNotNull);
      expect(
        host.pestCalls.map((r) => r.modelPath).toSet(),
        {'/data/files/models/gemma.litertlm'},
      );
      await analyzer.dispose();
      host.pestCalls.clear();
      analyzer = build(modelPath: () async => null);
      expect(await analyzer.analyzeImage(imageRequest()), isNull);
      expect(host.pestCalls, isEmpty);
    });
  });

  group('describeSound', () {
    test('experimental description with cleaned classifier labels', () async {
      script(host);
      final s = (await analyzer.describeSound(soundRequest()))!;
      expect(s.description, contains('may come from a flying insect'));
      expect(s.groupHint, PestGroup.insect);
      expect(s.preFilter.first.label, 'Insect');
      expect(s.modelVersion, 'gemma-4-E2B-it@0123456789ab');
      final r = host.pestCalls.single;
      expect(r.audioWav, isNotNull);
      expect(r.images, isEmpty);
      expect(r.format, NativeResponseFormat.none);
      expect(r.prompt, contains('Insect (about 62 percent)'));
    });

    test('guard rejection, bad clips and failures give null', () async {
      host.onPest = (_, _) async =>
          nativeResult(text: 'It is definitely a mosquito; spray it.');
      expect(await analyzer.describeSound(soundRequest()), isNull);
      host.pestCalls.clear();
      expect(await analyzer.describeSound(soundRequest(wav: wavBytes(seconds: 31))), isNull);
      expect(await analyzer.describeSound(soundRequest(wav: wavBytes(sampleRate: 48000))), isNull);
      expect(host.pestCalls, isEmpty);
      host.onPest = (_, _) async =>
          nativeResult(status: NativeGenerateStatus.unsupported, text: '');
      expect(await analyzer.describeSound(soundRequest()), isNull);
    });
  });

  group('proposeRegions', () {
    test('box_2d output becomes normalised boxes', () async {
      host.onPest = (_, _) async => nativeResult(
        text: '[{"box_2d": [100, 200, 300, 600], "label": "rat"}]',
      );
      final boxes = await analyzer.proposeRegions(
        jpegBytes(),
        labels: const ['rat', 'rat', 'cockroach'],
      );
      expect(boxes, hasLength(1));
      expect(boxes.single.left, closeTo(0.2, 1e-9));
      expect(boxes.single.top, closeTo(0.1, 1e-9));
      expect(boxes.single.width, closeTo(0.4, 1e-9));
      expect(boxes.single.height, closeTo(0.2, 1e-9));
      final r = host.pestCalls.single;
      expect(r.format, NativeResponseFormat.json);
      expect(r.images, [jpegBytes()]);
      expect(r.prompt, contains('box_2d'));
      expect(r.prompt, contains('rat, cockroach'));
    });

    test('empty on any failure', () async {
      host.onPest = (_, _) async => nativeResult(text: 'I cannot see');
      expect(await analyzer.proposeRegions(jpegBytes(), labels: const ['rat']), isEmpty);
      host.onPest = (_, _) async => throw PlatformException(code: 'x');
      expect(await analyzer.proposeRegions(jpegBytes(), labels: const ['rat']), isEmpty);
      expect(await analyzer.proposeRegions(wavBytes(), labels: const ['rat']), isEmpty);
      expect(await analyzer.proposeRegions(jpegBytes(), labels: const []), isEmpty);
    });
  });

  group('guide', () {
    test('text only, grounded in the given cards, one guarded event', () async {
      host.onPest = (_, _) async => nativeResult(
        text:
            'This may be a scorpion; the label is AI-estimated. Stay well '
            'back, keep beds away from walls and shake out shoes. If bitten '
            'or stung: get medical care.',
      );
      final texts = await analyzer
          .guide(guideInput(question: 'What should I do?'))
          .toList();
      expect(texts, hasLength(1));
      final t = texts.single;
      expect(t.complete, isTrue);
      expect(t.experimental, isTrue);
      expect(t.languageTag, 'en');
      expect(t.modelVersion, 'gemma-4-E2B-it@0123456789ab');

      final r = host.pestCalls.single;
      expect(r.images, isEmpty);
      expect(r.audioWav, isNull);
      expect(r.format, NativeResponseFormat.none);
      expect(r.prompt, contains('Shake out shoes before wearing'));
      expect(r.prompt, contains('- If bitten or stung: Get medical care for any sting'));
      expect(r.prompt, contains('- Steps to take: Keep beds away from walls'));
      expect(r.prompt, contains('- Required wording: Stay well back.'));
      expect(r.prompt, contains('User question: What should I do?'));
      expect(r.prompt, contains('Agreement between independent runs: 2 of 3'));
      // Never rendered: sources, the safety enum, reviewStatus.
      expect(r.prompt, isNot(contains('https://')));
      expect(r.prompt, isNot(contains('venomous')));
      expect(r.prompt, isNot(contains('Safety level')));
      expect(r.prompt, isNot(contains('review')));
      expect(r.prompt, isNot(contains('First aid')));
      expect(r.systemInstruction, contains('Use ONLY the card facts'));
      expect(r.systemInstruction, contains('rodenticide'));
      expect(
        r.systemInstruction,
        contains(
          'Never use these words: safe, safety, treatment, medicine, '
          'first aid, poison, venom',
        ),
      );
      expect(r.systemInstruction, contains('"stay well back"'));
      expect(r.systemInstruction, contains('Never write "kill"'));
    });

    test('a more serious analysis level adds its required wording', () async {
      host.onPest = (_, _) async => nativeResult(text: 'Stay well back.');
      await analyzer
          .guide(
            PestGuideInput(
              analysis: analysis(
                cardId: 'monitor_lizard',
                safety: SafetyLevel.protectedWildlife,
              ),
              cards: [scorpionCard()],
            ),
          )
          .toList();
      expect(
        host.pestCalls.single.prompt,
        contains(
          '- Required wording: Do not harm, catch or injure it; contact the '
          'State Forest Department or a licensed rescuer.',
        ),
      );
    });

    test('legal text of protected wildlife is passed and may be echoed', () async {
      host.onPest = (_, _) async => nativeResult(
        text:
            'This may be a monitor lizard, which is protected. Do not harm, '
            'catch or injure it; contact the State Forest Department or a '
            'licensed rescuer.',
      );
      final texts = await analyzer
          .guide(
            PestGuideInput(
              analysis: analysis(
                cardId: 'monitor_lizard',
                safety: SafetyLevel.protectedWildlife,
              ),
              cards: [monitorCard()],
            ),
          )
          .toList();
      expect(texts, hasLength(1));
      expect(host.pestCalls.single.prompt, contains('Schedule I'));
    });

    test('poison, certainty or safety claims give an empty stream', () async {
      for (final bad in [
        'Put rat poison near the hole.',
        'Use bromadiolone blocks.',
        'Yeh chuha maar dawa se chala jayega.',
        'चूहा मार गोली रखें।',
        'This is definitely a scorpion.',
        'This scorpion is harmless.',
        'Do not kill it.',
        'Keep a safe distance.',
      ]) {
        host.onPest = (_, _) async => nativeResult(text: bad);
        expect(await analyzer.guide(guideInput()).toList(), isEmpty, reason: bad);
      }
    });

    test('answers in the requested language', () async {
      host.onPest = (_, _) async =>
          nativeResult(text: 'यह शायद बिच्छू हो सकता है। दूर रहें।');
      final t = await analyzer.guide(guideInput(languageTag: 'hi')).single;
      expect(t.languageTag, 'hi');
      expect(host.pestCalls.single.systemInstruction, contains('Answer only in Hindi'));
      expect(host.pestCalls.single.prompt, contains('बिच्छू'));
    });

    test('no cards, no model or a bridge error: nothing generated', () async {
      expect(
        await analyzer
            .guide(PestGuideInput(analysis: analysis(), cards: const []))
            .toList(),
        isEmpty,
      );
      expect(host.pestCalls, isEmpty);
      host.onPest = (_, _) async => throw PlatformException(code: 'x');
      expect(await analyzer.guide(guideInput()).toList(), isEmpty);
    });
  });

  group('status', () {
    test('optedOut, noModel, ready and busy', () async {
      final enabled = StreamController<bool>.broadcast();
      await analyzer.dispose();
      analyzer = build(enabled: enabled.stream);
      final statuses = <AdviceStatus>[];
      analyzer.watchStatus().listen(statuses.add);
      enabled.add(false);
      await settle();
      expect(statuses.last, AdviceStatus.optedOut);

      enabled.add(true);
      await settle();
      expect(statuses.last, AdviceStatus.ready);

      final gate = Completer<NativeGenerateResult>();
      host.onPest = (_, _) => gate.future;
      final running = analyzer.describeSound(soundRequest());
      await settle();
      await settle();
      expect(statuses.last, AdviceStatus.busy);
      gate.complete(nativeResult(text: 'A short buzz that may be an insect.'));
      await running;
      await settle();
      expect(statuses.last, AdviceStatus.ready);

      host.push(nativeStatus(modelPresent: false));
      await settle();
      expect(statuses.last, AdviceStatus.noModel);
      await enabled.close();
    });

    test('another engine loading reads as busy; its failure is not ours', () async {
      final statuses = <AdviceStatus>[];
      analyzer.watchStatus().listen(statuses.add);
      await settle();
      host.push(
        nativeStatus(
          state: NativeEngineState.loading,
          slot: NativeRuntimeSlot.embedder,
        ),
      );
      await settle();
      expect(statuses.last, AdviceStatus.busy);
      host.push(
        nativeStatus(
          state: NativeEngineState.failed,
          slot: NativeRuntimeSlot.embedder,
        ),
      );
      await settle();
      expect(statuses.last, AdviceStatus.ready);
      host.push(
        nativeStatus(
          state: NativeEngineState.failed,
          slot: NativeRuntimeSlot.pestId,
        ),
      );
      await settle();
      expect(statuses.last, AdviceStatus.failed);
    });

    test('resolver without a model reads as noModel', () async {
      await analyzer.dispose();
      analyzer = build(modelPath: () async => null);
      expect(
        await analyzer.watchStatus().firstWhere((s) => s == AdviceStatus.noModel),
        AdviceStatus.noModel,
      );
    });
  });
}

PestSoundRequest soundRequest({Uint8List? wav}) => PestSoundRequest(
  wav: wav ?? wavBytes(seconds: 2),
  preFilter: const [
    ScoredLabel(label: 'Speech', score: 0.05),
    ScoredLabel(label: 'Insect', score: 0.62),
  ],
  allowedCardIds: cardIds,
);

PestGuideInput guideInput({String? question, String? languageTag}) =>
    PestGuideInput(
      analysis: analysis(),
      cards: [scorpionCard()],
      question: question,
      languageTag: languageTag,
    );
