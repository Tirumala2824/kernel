import 'dart:math' as math;

import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for EvidenceFusionAgent.
class FusionTask {
  const FusionTask({this.acousticReport, this.visualReport, this.sensorReport});

  final AcousticEvidenceReport? acousticReport;
  final VisualEvidenceReport? visualReport;
  final SensorEvidenceReport? sensorReport;
}

/// Summarizes independent evidence without converting capture quality into
/// classification confidence or treating a binary audio proxy as species ID.
class EvidenceFusionAgent implements Agent<FusionTask, QualityWeightedVerdict> {
  @override
  String get agentId => 'agent.fusion.evidence';

  @override
  Future<QualityWeightedVerdict> execute(FusionTask task) async {
    final acoustic = task.acousticReport;
    final visual = task.visualReport;
    final analysis = visual?.analysis;
    final hasPestLabel = analysis?.cardId?.isNotEmpty == true;

    final scores = <double?>[
      acoustic?.asqi.compositeScore,
      visual?.vqi.compositeScore,
    ].whereType<double>().toList(growable: false);
    // Use the weakest available capture-quality score for a conservative
    // quality badge. It is never multiplied into or displayed as confidence.
    final qualityScore = scores.isEmpty ? null : scores.reduce(math.min);
    final badge = _badgeFor(qualityScore);

    final String activityLabel;
    if (hasPestLabel) {
      activityLabel = analysis!.commonName;
    } else if (analysis != null) {
      activityLabel =
          'The on-device model returned no matching knowledge-card label.';
    } else if (acoustic != null) {
      activityLabel = acoustic.activityLabel;
    } else if (visual != null) {
      activityLabel = 'No on-device image-identification result is available.';
    } else if (task.sensorReport != null) {
      activityLabel =
          'Sensor telemetry is available; it does not identify a pest.';
    } else {
      activityLabel = 'No screening input was evaluated.';
    }

    final confidence = hasPestLabel ? analysis!.aiConfidence : null;
    final agreement = hasPestLabel ? analysis!.agreement : null;
    final modelVersion = analysis?.modelVersion ?? acoustic?.modelVersion;
    final experimental =
        analysis?.experimental ?? acoustic?.experimental ?? false;

    final qualityText = switch (badge) {
      QualityBadge.clear => 'Capture quality looks good.',
      QualityBadge.fair => 'Capture quality is usable with limitations.',
      QualityBadge.noisy => 'Capture quality is low; consider retaking.',
      QualityBadge.unavailable => 'Capture quality could not be measured.',
    };
    final advice = _advice(
      acoustic: acoustic,
      hasPestLabel: hasPestLabel,
      hasImage: visual != null,
      hasSensor: task.sensorReport != null,
      badge: badge,
    );

    return QualityWeightedVerdict(
      activityLabel: activityLabel,
      aiEstimatedConfidence: confidence,
      agreement: agreement,
      modelVersion: modelVersion,
      experimental: experimental,
      qualityScore: qualityScore,
      qualityBadge: badge,
      plainLanguageQuality: qualityText,
      userAdvice: advice,
    );
  }

  QualityBadge _badgeFor(double? score) {
    if (score == null) return QualityBadge.unavailable;
    if (score >= 0.80) return QualityBadge.clear;
    if (score >= 0.58) return QualityBadge.fair;
    return QualityBadge.noisy;
  }

  String _advice({
    required AcousticEvidenceReport? acoustic,
    required bool hasPestLabel,
    required bool hasImage,
    required bool hasSensor,
    required QualityBadge badge,
  }) {
    if (acoustic != null && !acoustic.isPass) {
      return switch (acoustic.retryReason) {
        QualityReason.highNoise => 'Background noise was high. Move away from machinery and record again.',
        QualityReason.silence => 'The recording was too quiet. Check microphone placement and try again.',
        QualityReason.clipping =>
          'The recording was distorted. Hold the device still and try again.',
        QualityReason.tooShort => 'The recording was too short. Record the full interval and try again.',
        QualityReason.permissionDenied =>
          'Microphone permission is required for an audio capture.',
        QualityReason.captureError || null => 'Audio capture could not be evaluated. Check the device and try again.',
      };
    }
    if (hasPestLabel) {
      return 'This is an AI suggestion, not a verified finding. Check the image and confirm the identification independently before acting.';
    }
    if (hasImage) {
      return 'Image quality is not a pest identification. An installed on-device model must return a constrained label before an ID is shown.';
    }
    if (acoustic != null) {
      return 'Audio activity does not identify a grain-pest species. Use physical inspection or a validated grain-specific method.';
    }
    if (hasSensor) {
      return 'Sensor events show recorded telemetry only; inspect the stored evidence and confirm any finding physically.';
    }
    if (badge == QualityBadge.noisy) {
      return 'A clearer capture may help, but capture quality alone does not determine pest presence.';
    }
    return 'Attach a photo or audio recording for on-device analysis, or ask a question covered by the local knowledge cards.';
  }
}
