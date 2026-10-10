import 'package:kernel_contracts/kernel_contracts.dart';

import 'acoustic_diagnostic_agent.dart';
import 'agronomy_safety_agent.dart';
import 'evidence_fusion_agent.dart';
import 'media_picker_service.dart';
import 'sensor_telemetry_agent.dart';
import 'visual_diagnostic_agent.dart';

/// Multimodal input task for the OrchestratorAgent.
class OrchestratorTask {
  const OrchestratorTask({
    required this.userMessage,
    this.audioMedia,
    this.visualMedia,
    this.sensorNodeId,
    this.cropContext = 'Paddy / Rice',
    this.itemId = 'grain-item-01',
    this.isLiveCapture = false,
  });

  final String userMessage;
  final PickedMedia? audioMedia;
  final PickedMedia? visualMedia;
  final String? sensorNodeId;
  final String cropContext;
  final String itemId;
  final bool isLiveCapture;
}

/// Structured conversational response produced by OrchestratorAgent.
class OrchestratorResponse {
  const OrchestratorResponse({
    required this.responseText,
    required this.verdict,
    required this.guidance,
    this.acousticReport,
    this.visualReport,
    this.sensorReport,
  });

  final String responseText;
  final QualityWeightedVerdict verdict;
  final GroundedGuidanceReport guidance;
  final AcousticEvidenceReport? acousticReport;
  final VisualEvidenceReport? visualReport;
  final SensorEvidenceReport? sensorReport;
}

/// Orchestrator agent coordinating the autonomous domain agents.
/// Manages user dialogue, delegates to specialist diagnostic agents,
/// synthesizes quality-weighted evidence, and enforces safe IPM agronomic guidance.
class OrchestratorAgent implements Agent<OrchestratorTask, OrchestratorResponse> {
  OrchestratorAgent({
    required this.acousticAgent,
    required this.visualAgent,
    required this.sensorAgent,
    required this.fusionAgent,
    required this.safetyAgent,
  });

  final AcousticDiagnosticAgent acousticAgent;
  final VisualDiagnosticAgent visualAgent;
  final SensorTelemetryAgent sensorAgent;
  final EvidenceFusionAgent fusionAgent;
  final AgronomySafetyAgent safetyAgent;

  @override
  String get agentId => 'agent.orchestrator.multimodal';

  @override
  Future<OrchestratorResponse> execute(OrchestratorTask task) async {
    AcousticEvidenceReport? acousticReport;
    VisualEvidenceReport? visualReport;
    SensorEvidenceReport? sensorReport;

    // 1. Dispatch acoustic task if audio provided or live capture requested
    if (task.audioMedia != null || task.isLiveCapture) {
      acousticReport = await acousticAgent.execute(
        AcousticTask(
          itemId: task.itemId,
          filePath: task.audioMedia?.path,
          sensorType: task.audioMedia?.sensorType ?? SensorType.audioAir,
          sensorNodeId: task.sensorNodeId,
          isLiveCapture: task.isLiveCapture,
        ),
      );
    }

    // 2. Dispatch visual task if photo/video provided
    if (task.visualMedia != null && task.visualMedia!.bytes.isNotEmpty) {
      visualReport = await visualAgent.execute(
        VisualTask(
          bytes: task.visualMedia!.bytes,
          source: task.visualMedia!.visualSource,
          fileName: task.visualMedia!.fileName,
        ),
      );
    }

    // 3. Dispatch sensor telemetry task if sensor node tagged
    if (task.sensorNodeId != null) {
      sensorReport = await sensorAgent.execute(
        SensorTelemetryTask(nodeId: task.sensorNodeId),
      );
    }

    // 4. Multi-agent evidence fusion & quality weighting
    final verdict = await fusionAgent.execute(
      FusionTask(
        acousticReport: acousticReport,
        visualReport: visualReport,
        sensorReport: sensorReport,
      ),
    );

    // 5. Agronomy and safety validation
    final guidance = await safetyAgent.execute(
      AgronomySafetyTask(verdict: verdict, cropContext: task.cropContext),
    );

    // 6. Build conversational response text
    final buffer = StringBuffer();
    if (acousticReport != null || visualReport != null) {
      buffer.writeln('### 🌾 Multimodal Screening Diagnostic\n');
      buffer.writeln(
        '**Signal Quality:** ${verdict.plainLanguageQuality} '
        '(Weight: ${(verdict.qualityWeight * 100).toInt()}%)\n',
      );
      buffer.writeln(
        '**Identified Activity:** **${verdict.speciesName}** '
        '(*${(verdict.calibratedConfidence * 100).toInt()}% calibrated confidence*)\n',
      );
      buffer.writeln('> 💡 **Capture Quality Advice:** ${verdict.userAdvice}\n');
      buffer.writeln('#### 🛡️ Recommended IPM Protocol:');
      for (final step in guidance.safeSteps) {
        buffer.writeln('- $step');
      }
      buffer.writeln('\n⚠️ *${guidance.legalNote}*');
    } else {
      buffer.writeln(
        'Hello! I am your **Kernel Autonomous Grain Screening & Pest ID Agent**.\n\n'
        'You can:\n'
        '• 🎙️ **Record live acoustic audio** from grain sacks\n'
        '• 📁 **Upload .wav audio files** with sensor transducer tags (Contact Piezo, Acoustic Air, BLE node)\n'
        '• 📷 **Take or upload insect photos/videos**\n'
        '• 💬 Ask agronomic questions regarding safe grain storage, hermetic sealing, and non-chemical IPM.\n\n'
        '*Everything runs entirely on your device with calibrated noise-weighting and zero cloud leakage.*',
      );
    }

    return OrchestratorResponse(
      responseText: buffer.toString(),
      verdict: verdict,
      guidance: guidance,
      acousticReport: acousticReport,
      visualReport: visualReport,
      sensorReport: sensorReport,
    );
  }
}
