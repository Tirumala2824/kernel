import '../enums.dart';
import '../pest_id.dart';
import '../sensor.dart';

/// Base contract for autonomous on-device domain agents.
abstract interface class Agent<TTask, TReport> {
  String get agentId;
  Future<TReport> execute(TTask task);
}

/// Visual quality badge for plain-language UX across all user bases.
enum QualityBadge { clear, fair, noisy }

/// Evaluated Audio Signal Quality Index based on noise floor, SNR, and sensor coupling.
class AudioSignalQualityIndex {
  const AudioSignalQualityIndex({
    required this.snrDb,
    required this.noiseFloorDbfs,
    required this.clipRatio,
    required this.sampleRate,
    required this.durationSeconds,
    required this.sensorType,
  });

  final double snrDb;
  final double noiseFloorDbfs;
  final double clipRatio;
  final int sampleRate;
  final double durationSeconds;
  final SensorType sensorType;

  /// Sensor physical acoustic coupling factor (1.0 = best contact piezo).
  double get sensorCouplingFactor => switch (sensorType) {
    SensorType.contactPiezo => 1.0,
    SensorType.contactAccel => 0.95,
    SensorType.usAir => 0.90,
    SensorType.audioAir => 0.88,
  };

  /// Noise score in 0..1 (SNR penalty + clipping penalty).
  double get noiseScore {
    final snrFraction = (snrDb / 18.0).clamp(0.2, 1.0);
    final clipPenalty = (1.0 - clipRatio * 10.0).clamp(0.2, 1.0);
    return snrFraction * clipPenalty;
  }

  /// Resolution score based on duration (target 2.0 s) and sample rate.
  double get resolutionScore {
    final durFraction = (durationSeconds / 2.0).clamp(0.5, 1.0);
    final rateFraction = sampleRate >= 16000 ? 1.0 : 0.8;
    return durFraction * rateFraction;
  }

  /// Composite Audio Signal Quality Index (0..1).
  double get compositeScore => (noiseScore * resolutionScore * sensorCouplingFactor).clamp(0.1, 1.0);

  QualityBadge get badge {
    if (compositeScore >= 0.78) return QualityBadge.clear;
    if (compositeScore >= 0.50) return QualityBadge.fair;
    return QualityBadge.noisy;
  }
}

/// Evaluated Visual Quality Index based on sharpness, exposure, and crop resolution.
class VisualQualityIndex {
  const VisualQualityIndex({
    required this.laplacianSharpness,
    required this.meanLuminance,
    required this.cropWidth,
    required this.cropHeight,
  });

  final double laplacianSharpness;
  final double meanLuminance;
  final int cropWidth;
  final int cropHeight;

  /// Sharpness score in 0..1 (Laplacian variance: >=100 is sharp, <30 is blurry).
  double get sharpnessScore => (laplacianSharpness / 100.0).clamp(0.4, 1.0);

  /// Exposure score (optimal luminance 60..200).
  double get exposureScore {
    if (meanLuminance >= 60 && meanLuminance <= 200) return 1.0;
    if (meanLuminance < 60) return (meanLuminance / 60.0).clamp(0.5, 1.0);
    return ((255 - meanLuminance) / 55.0).clamp(0.5, 1.0);
  }

  /// Resolution score (512+ px long edge is optimal).
  double get resolutionScore {
    final maxDim = cropWidth > cropHeight ? cropWidth : cropHeight;
    return (maxDim / 512.0).clamp(0.5, 1.0);
  }

  /// Composite Visual Quality Index (0..1).
  double get compositeScore => (sharpnessScore * exposureScore * resolutionScore).clamp(0.2, 1.0);

  QualityBadge get badge {
    if (compositeScore >= 0.80) return QualityBadge.clear;
    if (compositeScore >= 0.58) return QualityBadge.fair;
    return QualityBadge.noisy;
  }
}

/// Structured acoustic diagnostic report emitted by AcousticDiagnosticAgent.
class AcousticEvidenceReport {
  const AcousticEvidenceReport({
    required this.speciesId,
    required this.speciesName,
    required this.rawConfidence,
    required this.asqi,
    required this.modelVersion,
    required this.isPass,
    this.retryReason,
    this.topCandidates = const [],
  });

  final String speciesId;
  final String speciesName;
  final double rawConfidence;
  final AudioSignalQualityIndex asqi;
  final String modelVersion;
  final bool isPass;
  final QualityReason? retryReason;
  final List<ScoredLabel> topCandidates;
}

/// Structured visual report emitted by VisualDiagnosticAgent.
class VisualEvidenceReport {
  const VisualEvidenceReport({
    required this.vqi,
    required this.candidates,
    this.analysis,
    this.selectedCandidate,
  });

  final VisualQualityIndex vqi;
  final List<SignalCandidate> candidates;
  final PestAnalysis? analysis;
  final SignalCandidate? selectedCandidate;
}

/// Structured sensor telemetry report emitted by SensorTelemetryAgent.
class SensorEvidenceReport {
  const SensorEvidenceReport({
    required this.nodeId,
    required this.nodeName,
    required this.recentEventsCount,
    required this.isEvaluated,
    required this.signatureMatches,
    this.peakHz,
  });

  final String nodeId;
  final String nodeName;
  final int recentEventsCount;
  final bool isEvaluated;
  final List<SignatureMatch> signatureMatches;
  final double? peakHz;
}

/// Calibrated quality-weighted verdict produced by EvidenceFusionAgent.
class QualityWeightedVerdict {
  const QualityWeightedVerdict({
    required this.speciesName,
    required this.calibratedConfidence,
    required this.rawConfidence,
    required this.qualityWeight,
    required this.qualityBadge,
    required this.plainLanguageQuality,
    required this.userAdvice,
  });

  final String speciesName;
  final double calibratedConfidence;
  final double rawConfidence;
  final double qualityWeight;
  final QualityBadge qualityBadge;
  final String plainLanguageQuality;
  final String userAdvice;
}

/// Grounded guidance report emitted by AgronomySafetyAgent.
class GroundedGuidanceReport {
  const GroundedGuidanceReport({
    required this.cardId,
    required this.summary,
    required this.safeSteps,
    required this.safetyConcerns,
    this.callProfessionalWhen,
    this.firstAid,
    this.legalNote,
  });

  final String cardId;
  final String summary;
  final List<String> safeSteps;
  final Set<SafetyLevel> safetyConcerns;
  final List<String>? callProfessionalWhen;
  final List<String>? firstAid;
  final String? legalNote;
}
