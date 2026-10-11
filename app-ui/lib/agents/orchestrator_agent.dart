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
    this.cropContext,
    this.itemId,
    this.isLiveCapture = false,
  });

  final String userMessage;
  final PickedMedia? audioMedia;
  final PickedMedia? visualMedia;
  final String? sensorNodeId;
  final String? cropContext;

  /// A real local inventory item is required before the scan engine can
  /// persist a scan. No synthetic item identifier is invented by chat.
  final String? itemId;
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

/// Coordinates on-device specialists, curated local retrieval, and safety.
/// It never invents scan records, pest labels, or calibrated confidence.
class OrchestratorAgent
    implements Agent<OrchestratorTask, OrchestratorResponse> {
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
    final audioRequested = task.audioMedia != null || task.isLiveCapture;
    final audioNeedsItem = audioRequested && task.itemId == null;

    // Scan history is linked to a real grain item. Chat never creates a fake ID.
    if (audioRequested && task.itemId != null) {
      acousticReport = await acousticAgent.execute(
        AcousticTask(
          itemId: task.itemId!,
          filePath: task.audioMedia?.path,
          sensorType: task.audioMedia?.sensorType ?? SensorType.audioAir,
          sensorNodeId: task.sensorNodeId,
          isLiveCapture: task.isLiveCapture,
        ),
      );
    }

    if (task.visualMedia != null && task.visualMedia!.bytes.isNotEmpty) {
      visualReport = await visualAgent.execute(
        VisualTask(
          bytes: task.visualMedia!.bytes,
          source: task.visualMedia!.visualSource,
          fileName: task.visualMedia!.fileName,
        ),
      );
    }

    if (task.sensorNodeId != null) {
      sensorReport = await sensorAgent.execute(
        SensorTelemetryTask(nodeId: task.sensorNodeId!),
      );
    }

    final verdict = await fusionAgent.execute(
      FusionTask(
        acousticReport: acousticReport,
        visualReport: visualReport,
        sensorReport: sensorReport,
      ),
    );

    final hasEvidence =
        acousticReport != null || visualReport != null || sensorReport != null;
    final cardId = visualReport?.analysis?.cardId;
    final guidance = !hasEvidence && task.userMessage.trim().isNotEmpty
        ? await safetyAgent.answerQuestion(task.userMessage)
        : await safetyAgent.execute(
            AgronomySafetyTask(
              verdict: verdict,
              cropContext: task.cropContext,
              sightingCardId: cardId,
            ),
          );

    final responseText = _composeResponse(
      task: task,
      verdict: verdict,
      guidance: guidance,
      acoustic: acousticReport,
      visual: visualReport,
      sensor: sensorReport,
      audioNeedsItem: audioNeedsItem,
    );

    return OrchestratorResponse(
      responseText: responseText,
      verdict: verdict,
      guidance: guidance,
      acousticReport: acousticReport,
      visualReport: visualReport,
      sensorReport: sensorReport,
    );
  }

  String _composeResponse({
    required OrchestratorTask task,
    required QualityWeightedVerdict verdict,
    required GroundedGuidanceReport guidance,
    required AcousticEvidenceReport? acoustic,
    required VisualEvidenceReport? visual,
    required SensorEvidenceReport? sensor,
    required bool audioNeedsItem,
  }) {
    final buffer = StringBuffer();
    final hasEvidence = acoustic != null || visual != null || sensor != null;

    if (audioNeedsItem) {
      buffer.writeln(
        'Audio screening was not run. Link the capture to an existing saved grain item first; no scan record or model result was created.\n',
      );
    }

    if (hasEvidence) {
      buffer.writeln('### On-device screening result\n');
      if (visual != null) {
        buffer.writeln('**Image result:** ${verdict.activityLabel}\n');
        final analysis = visual.analysis;
        if (analysis?.cardId != null) {
          if (verdict.aiEstimatedConfidence != null) {
            buffer.writeln(
              '**AI-estimated confidence:** ${(verdict.aiEstimatedConfidence! * 100).round()}% (not calibrated).\n',
            );
          }
          if (verdict.agreement != null) {
            buffer.writeln(
              '**Independent-run agreement:** ${(verdict.agreement! * 100).round()}% across ${analysis!.samples} sample(s).\n',
            );
          }
          buffer.writeln(
            '**Model:** ${analysis!.modelVersion}${analysis.experimental ? ' — experimental' : ''}. This is an AI suggestion, not a verified finding.\n',
          );
        } else {
          buffer.writeln(
            'Image quality measurements do not identify a pest. No constrained knowledge-card label was returned.\n',
          );
        }
      }
      if (acoustic != null) {
        buffer.writeln('**Audio result:** ${acoustic.activityLabel}\n');
        buffer.writeln(
          '**Audio model:** ${acoustic.modelVersion}${acoustic.experimental ? ' — experimental' : ''}. Its score is not a calibrated grain-pest probability.\n',
        );
      }
      if (sensor != null) {
        buffer.writeln(
          '**Sensor:** ${sensor.isEvaluated ? '${sensor.recentEventsCount} stored event(s) evaluated.' : 'No events were available for evaluation.'} Sensor telemetry alone does not identify a pest.\n',
        );
      }
      buffer.writeln('**Capture quality:** ${verdict.plainLanguageQuality}');
      if (verdict.qualityScore != null) {
        buffer.writeln(
          ' (quality score ${(verdict.qualityScore! * 100).round()}%, not a classification score).\n',
        );
      } else {
        buffer.writeln('\n');
      }
      buffer.writeln('> ${verdict.userAdvice}\n');
      _appendGuidance(buffer, guidance);
      return buffer.toString().trim();
    }

    if (task.userMessage.trim().isNotEmpty) {
      buffer.writeln('### Local knowledge\n');
      buffer.writeln(guidance.summary);
      if (guidance.safeSteps.isNotEmpty) {
        buffer.writeln('\n**Suggested steps from the reviewed local card:**');
        for (final step in guidance.safeSteps) {
          buffer.writeln('- $step');
        }
      }
      if (guidance.callProfessionalWhen.isNotEmpty) {
        buffer.writeln('\n**Contact a qualified professional when:**');
        for (final condition in guidance.callProfessionalWhen) {
          buffer.writeln('- $condition');
        }
      }
      if (guidance.legalNote != null) {
        buffer.writeln('\n**Card note:** ${guidance.legalNote}');
      }
      if (guidance.sources.isNotEmpty) {
        buffer.writeln('\n**Sources:** ${guidance.sources.join('; ')}');
      }
      return buffer.toString().trim();
    }

    if (audioNeedsItem) return buffer.toString().trim();

    return 'Kernel runs available screening and knowledge features on this device. Attach a photo for constrained on-device identification, or ask a question covered by the bundled local knowledge cards. Experimental model suggestions require independent confirmation; no identification or verified finding is created by this welcome message.';
  }

  void _appendGuidance(StringBuffer buffer, GroundedGuidanceReport guidance) {
    if (guidance.cardId == 'unavailable') {
      buffer.writeln(
        '\nNo matching reviewed local guidance card is available.',
      );
      return;
    }
    if (guidance.safeSteps.isNotEmpty) {
      buffer.writeln('\n#### Relevant reviewed guidance');
      for (final step in guidance.safeSteps) {
        buffer.writeln('- $step');
      }
    }
    if (guidance.legalNote != null) {
      buffer.writeln('\n> ${guidance.legalNote}');
    }
    if (guidance.sources.isNotEmpty) {
      buffer.writeln('\n**Sources:** ${guidance.sources.join('; ')}');
    }
  }
}
