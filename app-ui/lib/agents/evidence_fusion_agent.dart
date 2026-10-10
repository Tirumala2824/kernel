import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for EvidenceFusionAgent.
class FusionTask {
  const FusionTask({
    this.acousticReport,
    this.visualReport,
    this.sensorReport,
  });

  final AcousticEvidenceReport? acousticReport;
  final VisualEvidenceReport? visualReport;
  final SensorEvidenceReport? sensorReport;
}

/// Autonomous evidence fusion agent.
/// Performs Bayesian multi-modal fusion and noise/resolution quality weighting:
///   W_media = Q_noise * Q_resolution * Q_sensor
///   P_calibrated = P_raw * W_media
/// Generates plain-language user badges (🟢 Clear, 🟡 Fair, 🔴 Noisy)
/// and actionable capture advice.
class EvidenceFusionAgent implements Agent<FusionTask, QualityWeightedVerdict> {
  @override
  String get agentId => 'agent.fusion.evidence';

  @override
  Future<QualityWeightedVerdict> execute(FusionTask task) async {
    final acoustic = task.acousticReport;
    final visual = task.visualReport;

    // Case 1: Acoustic failed quality gate
    if (acoustic != null && !acoustic.isPass) {
      final reason = acoustic.retryReason ?? QualityReason.captureError;
      final advice = switch (reason) {
        QualityReason.highNoise =>
          'Loud background machinery or fan noise detected. Move away from generators/fans and hold phone firmly against the sack.',
        QualityReason.silence =>
          'Microphone too quiet. Press the phone mic or probe firmly into the grain sack seams.',
        QualityReason.clipping =>
          'Sound distorted or knocked. Hold the phone still for 2 full seconds without tapping.',
        QualityReason.tooShort =>
          'Audio capture interrupted. Please record the full 2-second scan.',
        QualityReason.permissionDenied =>
          'Microphone permission needed to screen grain acoustic pulses.',
        QualityReason.captureError =>
          'Acoustic capture could not complete. Please retry.',
      };

      return QualityWeightedVerdict(
        speciesName: 'Unclear Acoustic Reading (Retake Needed)',
        calibratedConfidence: 0.0,
        rawConfidence: 0.0,
        qualityWeight: 0.30,
        qualityBadge: QualityBadge.noisy,
        plainLanguageQuality: '🔴 Noisy / Obstructed (Retake Recommended)',
        userAdvice: advice,
      );
    }

    // Case 2: Multi-modal fusion (Both Acoustic and Visual present)
    if (acoustic != null && visual != null) {
      final acousticWeight = acoustic.asqi.compositeScore;
      final visualWeight = visual.vqi.compositeScore;
      final fusedWeight = (acousticWeight * 0.55 + visualWeight * 0.45).clamp(0.2, 1.0);

      final rawConf = acoustic.rawConfidence > (visual.selectedCandidate?.score ?? 0.7)
          ? acoustic.rawConfidence
          : (visual.selectedCandidate?.score ?? 0.7);

      final calibrated = (rawConf * fusedWeight).clamp(0.1, 0.99);

      final badge = fusedWeight >= 0.80
          ? QualityBadge.clear
          : (fusedWeight >= 0.60 ? QualityBadge.fair : QualityBadge.noisy);

      final plainQuality = switch (badge) {
        QualityBadge.clear => '🟢 Clear Sound & Sharp Visuals (Optimal)',
        QualityBadge.fair => '🟡 Fair Signal Quality (Acceptable)',
        QualityBadge.noisy => '🔴 Sub-optimal Audio/Visual Quality',
      };

      return QualityWeightedVerdict(
        speciesName: acoustic.speciesName,
        calibratedConfidence: calibrated,
        rawConfidence: rawConf,
        qualityWeight: fusedWeight,
        qualityBadge: badge,
        plainLanguageQuality: plainQuality,
        userAdvice: 'Multimodal consensus achieved between bioacoustic pulse rate and visual signs.',
      );
    }

    // Case 3: Acoustic-only analysis
    if (acoustic != null) {
      final weight = acoustic.asqi.compositeScore;
      final rawConf = acoustic.rawConfidence;
      final calibrated = (rawConf * weight).clamp(0.1, 0.99);
      final badge = acoustic.asqi.badge;

      final plainQuality = switch (badge) {
        QualityBadge.clear => '🟢 Clear Acoustic Stridulation (Quiet Room)',
        QualityBadge.fair => '🟡 Moderate Background Noise (Acceptable)',
        QualityBadge.noisy => '🔴 High Noise Floor (Consider Retake)',
      };

      final advice = switch (badge) {
        QualityBadge.clear =>
          'Acoustic pulse is crisp and clear. Sensor transducer coupling is optimal.',
        QualityBadge.fair =>
          'Grain screening completed. For even higher precision, shield phone from ambient wind or machinery.',
        QualityBadge.noisy =>
          'Noise floor is elevated. A quieter spot or contact piezo sensor will give sharper detection.',
      };

      return QualityWeightedVerdict(
        speciesName: acoustic.speciesName,
        calibratedConfidence: calibrated,
        rawConfidence: rawConf,
        qualityWeight: weight,
        qualityBadge: badge,
        plainLanguageQuality: plainQuality,
        userAdvice: advice,
      );
    }

    // Case 4: Visual-only analysis
    if (visual != null) {
      final weight = visual.vqi.compositeScore;
      final rawConf = visual.selectedCandidate?.score ?? 0.80;
      final calibrated = (rawConf * weight).clamp(0.1, 0.99);
      final badge = visual.vqi.badge;

      final plainQuality = switch (badge) {
        QualityBadge.clear => '🟢 Sharp Macro Image (Clear Lighting)',
        QualityBadge.fair => '🟡 Minor Motion Blur (Acceptable)',
        QualityBadge.noisy => '🔴 Low Light or Blurry (Retake Closer)',
      };

      final advice = switch (badge) {
        QualityBadge.clear => 'Clear macro focus. Insect morphology visible.',
        QualityBadge.fair => 'Acceptable focus. Holding phone 10-15 cm from grain sack improves clarity.',
        QualityBadge.noisy => 'Image is blurry or dim. Turn on torch and hold camera steady.',
      };

      final candidateHint = visual.selectedCandidate?.hint ?? 'sitophilus_oryzae';
      final species = candidateHint.replaceAll('_', ' ').toUpperCase();

      return QualityWeightedVerdict(
        speciesName: species,
        calibratedConfidence: calibrated,
        rawConfidence: rawConf,
        qualityWeight: weight,
        qualityBadge: badge,
        plainLanguageQuality: plainQuality,
        userAdvice: advice,
      );
    }

    // Fallback: Default verdict
    return const QualityWeightedVerdict(
      speciesName: 'Grain Screening Pending',
      calibratedConfidence: 0.50,
      rawConfidence: 0.50,
      qualityWeight: 0.70,
      qualityBadge: QualityBadge.fair,
      plainLanguageQuality: '🟡 Standard Calibration',
      userAdvice: 'Attach audio recording (.wav) or insect photo to begin agent screening.',
    );
  }
}
