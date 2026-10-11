import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/agents.dart';
import 'package:kernel_app/features/chat/kernel_chat_screen.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_engine.dart';

void main() {
  group('AcousticDiagnosticAgent', () {
    test(
      'reports the proxy activity without inventing an insect species',
      () async {
        final engine = ScriptedScanEngine(
          next: (_) => _outcome(
            classification: Classification.infested,
            experimental: true,
            modelVersion: 'kernel-proxy-0.1',
            confidence: 0.88,
          ),
        );

        final report = await AcousticDiagnosticAgent(scanEngine: engine)
            .execute(
              const AcousticTask(
                itemId: 'item-1',
                filePath: '/path/to/recording.wav',
                sensorType: SensorType.contactPiezo,
              ),
            );

        expect(report.isPass, isTrue);
        expect(report.activityLabel, contains('non-grain audio proxy'));
        expect(report.activityLabel, contains('no pest was identified'));
        expect(report.modelScore, 0.88);
        expect(report.experimental, isTrue);
        expect(report.asqi.compositeScore, 0.94);
      },
    );

    test(
      'does not infer activity when the scan engine returns notEvaluated',
      () async {
        final engine = ScriptedScanEngine(
          next: (_) => _outcome(
            classification: Classification.notEvaluated,
            modelVersion: noModelVersion,
            confidence: null,
          ),
        );

        final report = await AcousticDiagnosticAgent(scanEngine: engine)
            .execute(
              const AcousticTask(
                itemId: 'item-1',
                filePath: '/path/to/recording.wav',
              ),
            );

        expect(report.activityLabel, contains('no compatible on-device model'));
        expect(report.modelScore, isNull);
      },
    );

    test('preserves a quality-gate retry and its reason', () async {
      final engine = ScriptedScanEngine(
        next: (_) => _outcome(
          quality: ScanQuality.retry,
          reasons: [QualityReason.highNoise],
          classification: Classification.notEvaluated,
          modelVersion: noModelVersion,
          confidence: null,
          score: 0.35,
        ),
      );

      final report = await AcousticDiagnosticAgent(scanEngine: engine).execute(
        const AcousticTask(itemId: 'item-1', filePath: '/path/to/noisy.wav'),
      );

      expect(report.isPass, isFalse);
      expect(report.retryReason, QualityReason.highNoise);
      expect(report.modelScore, isNull);
      expect(report.asqi.score, 0.35);
    });
  });

  group('VisualDiagnosticAgent', () {
    test(
      'invalid bytes receive no synthetic quality metrics or pest candidate',
      () async {
        final report = await VisualDiagnosticAgent().execute(
          VisualTask(
            bytes: Uint8List.fromList(
              List.generate(2000, (i) => (i * 7) % 256),
            ),
          ),
        );

        expect(report.vqi.compositeScore, isNull);
        expect(report.analysis, isNull);
      },
    );
  });

  group('EvidenceFusionAgent', () {
    test('keeps audio proxy activity separate from pest identification and confidence', () async {
      final acoustic = AcousticEvidenceReport(
        activityLabel: 'Elevated activity was flagged by an experimental non-grain audio proxy; no pest was identified.',
        modelScore: 0.90,
        asqi: const AudioSignalQualityIndex(
          score: 0.94,
          sampleRate: 16000,
          durationSeconds: 2,
          sensorType: SensorType.contactPiezo,
        ),
        modelVersion: 'kernel-proxy-0.1',
        experimental: true,
        isPass: true,
      );

      final verdict = await EvidenceFusionAgent().execute(
        FusionTask(acousticReport: acoustic),
      );

      expect(verdict.activityLabel, contains('no pest was identified'));
      expect(verdict.aiEstimatedConfidence, isNull);
      expect(verdict.agreement, isNull);
      expect(verdict.qualityScore, 0.94);
      expect(verdict.experimental, isTrue);
    });

    test(
      'preserves the model estimate and independent-run agreement unchanged',
      () async {
        final report = VisualEvidenceReport(
          vqi: const VisualQualityIndex(
            laplacianSharpness: 140,
            meanLuminance: 120,
            cropWidth: 1024,
            cropHeight: 1024,
          ),
          analysis: PestAnalysis(
            analysisId: 'analysis-1',
            createdAt: DateTime.utc(2026, 10, 10),
            source: SignalSource.camera,
            cardId: 'bed_bug',
            commonName: 'Bed bug',
            group: PestGroup.insect,
            taxonomyPath: const ['Insect', 'Bed bug'],
            aiConfidence: 0.73,
            agreement: 0.67,
            samples: 3,
            keyFeatures: const ['flattened oval body'],
            anomalies: const [],
            insights: const [],
            safety: SafetyLevel.caution,
            modelVersion: 'gemma-local-test',
            promptVersion: 'p1',
            latencyMs: 400,
            experimental: true,
          ),
        );

        final verdict = await EvidenceFusionAgent().execute(
          FusionTask(visualReport: report),
        );

        expect(verdict.activityLabel, 'Bed bug');
        expect(verdict.aiEstimatedConfidence, 0.73);
        expect(verdict.agreement, 0.67);
        expect(verdict.qualityScore, isNotNull);
        expect(verdict.experimental, isTrue);
      },
    );

    test(
      'does not display classification confidence after an audio quality retry',
      () async {
        final verdict = await EvidenceFusionAgent().execute(
          const FusionTask(
            acousticReport: AcousticEvidenceReport(
              activityLabel:
                  'Audio was not evaluated; a new recording is needed.',
              modelScore: null,
              asqi: AudioSignalQualityIndex(
                score: 0.35,
                sampleRate: 16000,
                durationSeconds: 2,
                sensorType: SensorType.audioAir,
              ),
              modelVersion: noModelVersion,
              experimental: true,
              isPass: false,
              retryReason: QualityReason.highNoise,
            ),
          ),
        );

        expect(verdict.aiEstimatedConfidence, isNull);
        expect(verdict.qualityBadge, QualityBadge.noisy);
        expect(verdict.userAdvice, contains('Background noise was high'));
      },
    );
  });

  group('AgronomySafetyAgent', () {
    test('returns no unsourced treatment steps when no card matches', () async {
      final verdict = await EvidenceFusionAgent().execute(const FusionTask());
      final guidance = await AgronomySafetyAgent().execute(
        AgronomySafetyTask(verdict: verdict),
      );

      expect(guidance.cardId, 'unavailable');
      expect(guidance.safeSteps, isEmpty);
      expect(guidance.legalNote, isNull);
      expect(
        guidance.summary,
        contains('No matching reviewed local knowledge card'),
      );
    });

    test(
      'answers text questions from a sourced local knowledge card',
      () async {
        final card = KnowledgeCard(
          id: 'bed_bug',
          names: const {'en': 'Bed bug'},
          group: PestGroup.insect,
          safety: SafetyLevel.caution,
          summary: 'A reviewed bed bug card summary.',
          signs: const ['small dark spots'],
          lookAlikes: const [],
          healthRisks: const [],
          safeSteps: const ['Wash and dry fabric using its care instructions.'],
          callProfessionalWhen: const ['The infestation persists.'],
          firstAid: const [],
          legal: null,
          sources: const ['Local extension reference, reviewed 2026'],
          reviewStatus: 'reviewed',
        );
        final agent = AgronomySafetyAgent(
          knowledgeService: _MemoryKnowledgeService([card]),
        );

        final answer = await agent.answerQuestion(
          'How do I deal with bed bugs?',
        );

        expect(answer.cardId, 'bed_bug');
        expect(answer.summary, card.summary);
        expect(answer.safeSteps, card.safeSteps);
        expect(answer.sources, card.sources);
      },
    );
  });

  group('OrchestratorAgent', () {
    test(
      'coordinates a real item scan without presenting the proxy as species ID',
      () async {
        final engine = ScriptedScanEngine(
          next: (_) => _outcome(
            classification: Classification.infested,
            experimental: true,
            modelVersion: 'kernel-proxy-0.1',
            confidence: 0.86,
          ),
        );
        final orchestrator = OrchestratorAgent(
          acousticAgent: AcousticDiagnosticAgent(scanEngine: engine),
          visualAgent: VisualDiagnosticAgent(),
          sensorAgent: SensorTelemetryAgent(),
          fusionAgent: EvidenceFusionAgent(),
          safetyAgent: AgronomySafetyAgent(),
        );

        final response = await orchestrator.execute(
          const OrchestratorTask(
            userMessage: 'Screen this recording',
            itemId: 'item-1',
            isLiveCapture: true,
          ),
        );

        expect(response.responseText, contains('On-device screening result'));
        expect(response.responseText, contains('non-grain audio proxy'));
        expect(
          response.responseText,
          contains('not a calibrated grain-pest probability'),
        );
        expect(response.responseText, isNot(contains('Sitophilus')));
        expect(response.verdict.aiEstimatedConfidence, isNull);
        expect(response.guidance.safeSteps, isEmpty);
      },
    );

    test('does not invent a grain item ID for an audio request', () async {
      var scanCalled = false;
      final engine = ScriptedScanEngine(
        next: (_) {
          scanCalled = true;
          return _outcome();
        },
      );
      final orchestrator = OrchestratorAgent(
        acousticAgent: AcousticDiagnosticAgent(scanEngine: engine),
        visualAgent: VisualDiagnosticAgent(),
        sensorAgent: SensorTelemetryAgent(),
        fusionAgent: EvidenceFusionAgent(),
        safetyAgent: AgronomySafetyAgent(),
      );

      final response = await orchestrator.execute(
        const OrchestratorTask(userMessage: '', isLiveCapture: true),
      );

      expect(scanCalled, isFalse);
      expect(
        response.responseText,
        contains('Link the capture to an existing saved grain item'),
      );
      expect(response.acousticReport, isNull);
    });
  });

  group('KernelChatScreen UI', () {
    testWidgets('renders the conversation interface with honest capabilities', (
      tester,
    ) async {
      final env = TestEnv();
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: const MaterialApp(home: KernelChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kernel Agent Chat'), findsOneWidget);
      expect(find.textContaining('Welcome to Kernel'), findsOneWidget);
      expect(
        find.textContaining('Experimental models may not be validated'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.audio_file), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}

ScanOutcome _outcome({
  ScanQuality quality = ScanQuality.pass,
  List<QualityReason> reasons = const [],
  Classification classification = Classification.infested,
  bool experimental = true,
  String modelVersion = 'kernel-proxy-0.1',
  double? confidence = 0.88,
  double? score = 0.94,
}) => ScanOutcome(
  scanId: 'scan-test',
  itemId: 'item-1',
  capturedAt: DateTime.utc(2026, 10, 10),
  quality: quality,
  qualityReasons: reasons,
  classification: classification,
  confidence: confidence,
  experimental: experimental,
  modelVersion: modelVersion,
  latencyMs: 42,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
  asqiScore: score,
);

class _MemoryKnowledgeService implements KnowledgeService {
  _MemoryKnowledgeService(this.cards);
  final List<KnowledgeCard> cards;

  @override
  Future<List<KnowledgeCard>> all() async => cards;

  @override
  Future<KnowledgeCard?> get(String id) async {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  @override
  Future<List<KnowledgeHit>> search(String query, {int limit = 3}) async {
    final queryTerms = query.toLowerCase().split(RegExp(r'\W+'));
    final hits = <KnowledgeHit>[];
    for (final card in cards) {
      final text = '${card.id} ${card.names.values.join(' ')} ${card.summary}'
          .toLowerCase();
      final score = queryTerms
          .where((term) => term.length > 2 && text.contains(term))
          .length;
      if (score > 0) {
        hits.add(KnowledgeHit(card: card, score: score.toDouble()));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).toList();
  }
}
