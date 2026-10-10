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
    test('analyzes audio file and computes ASQI and top candidates', () async {
      final engine = ScriptedScanEngine(
        next: (_) => ScanOutcome(
          scanId: 'scan-100',
          itemId: 'item-1',
          capturedAt: DateTime.utc(2026, 10, 10),
          quality: ScanQuality.pass,
          qualityReasons: [],
          classification: Classification.infested,
          confidence: 0.88,
          experimental: false,
          modelVersion: 'kernel-insect-classifier-v1',
          latencyMs: 42,
          durationMs: 2000,
          sampleRate: 16000,
          deviceModel: 'test-device',
          osVersion: 'test-os',
          asqiScore: 0.94,
        ),
      );

      final agent = AcousticDiagnosticAgent(scanEngine: engine);
      final report = await agent.execute(
        const AcousticTask(
          itemId: 'item-1',
          filePath: '/path/to/rice_weevil.wav',
          sensorType: SensorType.contactPiezo,
        ),
      );

      expect(report.isPass, isTrue);
      expect(report.speciesId, 'sitophilus_oryzae');
      expect(report.speciesName, contains('Sitophilus oryzae'));
      expect(report.rawConfidence, 0.88);
      expect(report.asqi.badge, QualityBadge.clear);
      expect(report.topCandidates, isNotEmpty);
      expect(report.topCandidates.first.label, contains('Sitophilus oryzae'));
    });

    test('maps retry outcome with quality reason when noise is high', () async {
      final engine = ScriptedScanEngine(
        next: (_) => ScanOutcome(
          scanId: 'scan-101',
          itemId: 'item-1',
          capturedAt: DateTime.utc(2026, 10, 10),
          quality: ScanQuality.retry,
          qualityReasons: [QualityReason.highNoise],
          classification: Classification.notEvaluated,
          confidence: null,
          experimental: true,
          modelVersion: 'none',
          latencyMs: 10,
          durationMs: 2000,
          sampleRate: 16000,
          deviceModel: 'test-device',
          osVersion: 'test-os',
          asqiScore: 0.35,
        ),
      );

      final agent = AcousticDiagnosticAgent(scanEngine: engine);
      final report = await agent.execute(
        const AcousticTask(
          itemId: 'item-1',
          filePath: '/path/to/noisy.wav',
          sensorType: SensorType.audioAir,
        ),
      );

      expect(report.isPass, isFalse);
      expect(report.retryReason, QualityReason.highNoise);
      expect(report.rawConfidence, 0.0);
    });
  });

  group('VisualDiagnosticAgent', () {
    test('computes VQI and returns candidate', () async {
      final agent = VisualDiagnosticAgent();
      final bytes = Uint8List.fromList(List.generate(2000, (i) => (i * 7) % 256));

      final report = await agent.execute(VisualTask(bytes: bytes));

      expect(report.vqi.laplacianSharpness, greaterThan(20.0));
      expect(report.vqi.meanLuminance, greaterThan(0.0));
      expect(report.candidates, isNotEmpty);
    });
  });

  group('EvidenceFusionAgent', () {
    test('calibrates confidence using noise and resolution weighting', () async {
      final fusion = EvidenceFusionAgent();

      const asqi = AudioSignalQualityIndex(
        snrDb: 18.0,
        noiseFloorDbfs: -55.0,
        clipRatio: 0.0,
        sampleRate: 16000,
        durationSeconds: 2.0,
        sensorType: SensorType.contactPiezo,
      );

      const acousticReport = AcousticEvidenceReport(
        speciesId: 'sitophilus_oryzae',
        speciesName: 'Sitophilus oryzae (Rice Weevil)',
        rawConfidence: 0.90,
        asqi: asqi,
        modelVersion: 'ganesh333/kernel-insect-classifier',
        isPass: true,
      );

      final verdict = await fusion.execute(
        const FusionTask(acousticReport: acousticReport),
      );

      expect(verdict.speciesName, contains('Sitophilus oryzae'));
      expect(verdict.calibratedConfidence, greaterThan(0.70));
      expect(verdict.qualityBadge, QualityBadge.clear);
      expect(verdict.plainLanguageQuality, contains('Clear'));
    });

    test('downgrades verdict when acoustic recording failed quality gate', () async {
      final fusion = EvidenceFusionAgent();

      const asqi = AudioSignalQualityIndex(
        snrDb: 4.0,
        noiseFloorDbfs: -35.0,
        clipRatio: 0.0,
        sampleRate: 16000,
        durationSeconds: 2.0,
        sensorType: SensorType.audioAir,
      );

      const acousticReport = AcousticEvidenceReport(
        speciesId: 'retry',
        speciesName: 'Noisy Audio',
        rawConfidence: 0.0,
        asqi: asqi,
        modelVersion: 'none',
        isPass: false,
        retryReason: QualityReason.highNoise,
      );

      final verdict = await fusion.execute(
        const FusionTask(acousticReport: acousticReport),
      );

      expect(verdict.calibratedConfidence, 0.0);
      expect(verdict.qualityBadge, QualityBadge.noisy);
      expect(verdict.plainLanguageQuality, contains('Noisy'));
      expect(verdict.userAdvice, contains('machinery or fan noise'));
    });
  });

  group('AgronomySafetyAgent', () {
    test('enforces non-chemical safe IPM steps', () async {
      final safetyAgent = AgronomySafetyAgent();
      const verdict = QualityWeightedVerdict(
        speciesName: 'Sitophilus oryzae (Rice Weevil)',
        calibratedConfidence: 0.85,
        rawConfidence: 0.90,
        qualityWeight: 0.95,
        qualityBadge: QualityBadge.clear,
        plainLanguageQuality: 'Clear Signal',
        userAdvice: 'Clean signal',
      );

      final guidance = await safetyAgent.execute(
        const AgronomySafetyTask(verdict: verdict),
      );

      expect(guidance.safeSteps, isNotEmpty);
      expect(guidance.safeSteps.any((s) => s.contains('Hermetic') || s.contains('PICS')), isTrue);
      expect(guidance.safeSteps.any((s) => s.contains('Solar') || s.contains('Sieving')), isTrue);
      expect(guidance.legalNote, contains('Strict IPM Compliance'));
    });
  });

  group('OrchestratorAgent', () {
    test('coordinates multimodal analysis and builds comprehensive response', () async {
      final engine = ScriptedScanEngine(
        next: (_) => ScanOutcome(
          scanId: 'scan-1',
          itemId: 'item-1',
          capturedAt: DateTime.utc(2026, 10, 10),
          quality: ScanQuality.pass,
          qualityReasons: [],
          classification: Classification.infested,
          confidence: 0.86,
          experimental: false,
          modelVersion: 'ganesh333/kernel-insect-classifier',
          latencyMs: 25,
          durationMs: 2000,
          sampleRate: 16000,
          deviceModel: 'test-device',
          osVersion: 'test-os',
          asqiScore: 0.92,
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
          userMessage: 'Screen this grain sample',
          isLiveCapture: true,
        ),
      );

      expect(response.responseText, contains('Multimodal Screening Diagnostic'));
      expect(response.responseText, contains('Sitophilus oryzae'));
      expect(response.verdict.qualityBadge, QualityBadge.clear);
      expect(response.guidance.safeSteps, isNotEmpty);
    });
  });

  group('KernelChatScreen UI', () {
    testWidgets('renders conversational interface with attachment buttons', (tester) async {
      final env = TestEnv();

      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: const MaterialApp(
            home: KernelChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kernel Agent Chat'), findsOneWidget);
      expect(find.textContaining('Welcome to Kernel Autonomous Multi-Agent'), findsOneWidget);
      expect(find.byIcon(Icons.audio_file), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}
