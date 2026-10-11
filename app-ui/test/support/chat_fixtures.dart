import 'dart:typed_data';

import 'package:kernel_app/agents/media_picker_service.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

KnowledgeCard chatCard({
  String id = 'test-weevil',
  Set<SafetyLevel> extraSafety = const {},
}) => KnowledgeCard(
  id: id,
  names: const {'en': 'Test weevil'},
  group: PestGroup.insect,
  safety: SafetyLevel.caution,
  extraSafety: extraSafety,
  summary: 'Test-only storage information.',
  signs: const [],
  lookAlikes: const [],
  healthRisks: const [],
  safeSteps: const ['Keep stored grain dry.'],
  callProfessionalWhen: const ['Ask a professional if unsure.'],
  firstAid: const [],
  legal: null,
  sources: const ['https://example.org/test-only'],
  reviewStatus: 'needs-expert-review',
);

PestAnalysis chatAnalysis({
  String? cardId = 'test-weevil',
  SafetyLevel safety = SafetyLevel.caution,
}) => PestAnalysis(
  analysisId: 'test-analysis',
  createdAt: DateTime.utc(2026),
  source: SignalSource.camera,
  cardId: cardId,
  commonName: 'Test weevil',
  group: PestGroup.insect,
  taxonomyPath: const ['Insect'],
  aiConfidence: 0.6,
  agreement: 1,
  samples: 1,
  keyFeatures: const [],
  anomalies: const [],
  insights: const [],
  safety: safety,
  modelVersion: 'test-model',
  promptVersion: 'test-prompt',
  latencyMs: 1,
);

PickedMedia chatAudio({String name = 'grain.wav'}) => PickedMedia(
  path: '/test/$name',
  fileName: name,
  bytes: Uint8List(0),
  mediaType: 'audio',
);
PickedMedia chatPhoto() => PickedMedia(
  path: '/test/photo.png',
  fileName: 'photo.png',
  bytes: Uint8List.fromList([1, 2, 3]),
  mediaType: 'image',
);

class ChatKnowledge implements KnowledgeService {
  final queries = <String>[];
  List<KnowledgeCard> cards = [chatCard()];
  List<KnowledgeCard>? searchCards;
  final lookups = <String>[];
  bool fail = false;
  Duration delay = Duration.zero;
  @override
  Future<List<KnowledgeCard>> all() async {
    await Future<void>.delayed(delay);
    return cards;
  }

  @override
  Future<KnowledgeCard?> get(String id) async {
    lookups.add(id);
    return cards.where((card) => card.id == id).firstOrNull;
  }

  @override
  Future<List<KnowledgeHit>> search(String query, {int limit = 3}) async {
    queries.add(query);
    await Future<void>.delayed(delay);
    if (fail) throw StateError('test knowledge failure');
    return [
      for (final card in (searchCards ?? cards).take(limit))
        KnowledgeHit(card: card, score: 1),
    ];
  }
}

class ChatAnalyzer implements PestAnalyzer {
  PestAnalysis? result = chatAnalysis();
  bool fail = false;
  Duration delay = Duration.zero;
  final images = <PestImageRequest>[];
  final guides = <PestGuideInput>[];
  List<AdviceText> guideOutput = const [];
  Stream<AdviceText>? guideStream;
  @override
  Stream<AdviceStatus> watchStatus() => Stream.value(AdviceStatus.ready);
  @override
  Future<PestAnalysis?> analyzeImage(PestImageRequest request) async {
    images.add(request);
    await Future<void>.delayed(delay);
    if (fail) throw StateError('test image failure');
    return result;
  }

  @override
  Stream<AdviceText> guide(PestGuideInput input) {
    guides.add(input);
    return guideStream ?? Stream.fromIterable(guideOutput);
  }

  @override
  Future<SoundAnalysis?> describeSound(PestSoundRequest request) async => null;
  @override
  Future<List<NormalizedBox>> proposeRegions(
    Uint8List image, {
    required List<String> labels,
  }) async => const [];
}

class ChatSoundClassifier implements InsectSoundClassifier {
  bool fail = false;
  Duration delay = Duration.zero;
  final paths = <String>[];
  InsectSoundResult result = const InsectSoundResult(
    status: InsectSoundStatus.evaluated,
    level: InsectIdentificationLevel.genus,
    label: 'Test genus',
    topLabels: [ScoredLabel(label: 'Test genus species', score: 0.4)],
    modelVersion: 'test-model',
    modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
  );
  @override
  Future<InsectSoundResult> classifyWavFile(String path) async {
    paths.add(path);
    await Future<void>.delayed(delay);
    if (fail) throw StateError('test sound failure');
    return result;
  }
}
