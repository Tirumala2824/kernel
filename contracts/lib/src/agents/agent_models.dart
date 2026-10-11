import '../enums.dart';
import '../pest_id.dart';
import '../sensor.dart';

/// Base contract for autonomous on-device domain agents.
abstract interface class Agent<TTask, TReport> {
  String get agentId;
  Future<TReport> execute(TTask task);
}

/// Plain-language state for a measured capture-quality signal.
enum QualityBadge { clear, fair, noisy, unavailable }

/// An audio capture-quality score reported by the scan engine.
///
/// No proxy SNR, noise floor, or sensor-coupling values are synthesized when
/// the engine does not report them. The score describes recording quality; it
/// is not a pest probability.
class AudioSignalQualityIndex {
  const AudioSignalQualityIndex({
    required this.score,
    required this.sampleRate,
    required this.durationSeconds,
    required this.sensorType,
  });

  /// Scan-engine ASQI in 0..1, or null when the engine did not report it.
  final double? score;
  final int sampleRate;
  final double durationSeconds;
  final SensorType sensorType;

  double? get compositeScore => score?.clamp(0.0, 1.0).toDouble();

  QualityBadge get badge {
    final value = compositeScore;
    if (value == null) return QualityBadge.unavailable;
    if (value >= 0.78) return QualityBadge.clear;
    if (value >= 0.50) return QualityBadge.fair;
    return QualityBadge.noisy;
  }
}

/// Pixel-derived image-capture measurements. Scores are quality heuristics,
/// never evidence that an image contains a particular pest.
class VisualQualityIndex {
  const VisualQualityIndex({
    required this.laplacianSharpness,
    required this.meanLuminance,
    required this.cropWidth,
    required this.cropHeight,
  });

  final double? laplacianSharpness;
  final double? meanLuminance;
  final int? cropWidth;
  final int? cropHeight;

  double? get sharpnessScore {
    final value = laplacianSharpness;
    return value == null ? null : (value / 100.0).clamp(0.0, 1.0).toDouble();
  }

  double? get exposureScore {
    final value = meanLuminance;
    if (value == null) return null;
    if (value >= 60 && value <= 200) return 1.0;
    if (value < 60) return (value / 60.0).clamp(0.0, 1.0).toDouble();
    return ((255 - value) / 55.0).clamp(0.0, 1.0).toDouble();
  }

  double? get resolutionScore {
    final width = cropWidth;
    final height = cropHeight;
    if (width == null || height == null) return null;
    final maxDim = width > height ? width : height;
    return (maxDim / 512.0).clamp(0.0, 1.0).toDouble();
  }

  double? get compositeScore {
    final sharpness = sharpnessScore;
    final exposure = exposureScore;
    final resolution = resolutionScore;
    if (sharpness == null || exposure == null || resolution == null) {
      return null;
    }
    return (sharpness * exposure * resolution).clamp(0.0, 1.0).toDouble();
  }

  QualityBadge get badge {
    final value = compositeScore;
    if (value == null) return QualityBadge.unavailable;
    if (value >= 0.80) return QualityBadge.clear;
    if (value >= 0.58) return QualityBadge.fair;
    return QualityBadge.noisy;
  }
}

/// Acoustic activity result. It does not claim a pest/species identification.
class AcousticEvidenceReport {
  const AcousticEvidenceReport({
    required this.activityLabel,
    required this.modelScore,
    required this.asqi,
    required this.modelVersion,
    required this.experimental,
    required this.isPass,
    this.retryReason,
  });

  final String activityLabel;

  /// Model-reported score, in its training domain; not a calibrated probability.
  final double? modelScore;
  final AudioSignalQualityIndex asqi;
  final String modelVersion;
  final bool experimental;
  final bool isPass;
  final QualityReason? retryReason;
}

/// Image report. A pest label exists only when the on-device analyzer returned
/// an actual [PestAnalysis].
class VisualEvidenceReport {
  const VisualEvidenceReport({required this.vqi, this.analysis});

  final VisualQualityIndex vqi;
  final PestAnalysis? analysis;
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

/// Summary of screening evidence. AI estimates and capture quality are kept
/// separate; an AI estimate is never relabelled as calibrated confidence.
class QualityWeightedVerdict {
  const QualityWeightedVerdict({
    required this.activityLabel,
    required this.aiEstimatedConfidence,
    required this.agreement,
    required this.modelVersion,
    required this.experimental,
    required this.qualityScore,
    required this.qualityBadge,
    required this.plainLanguageQuality,
    required this.userAdvice,
  });

  final String activityLabel;

  /// The vision model's own self-estimate, not calibrated. Null when there is
  /// no constrained on-device identification result.
  final double? aiEstimatedConfidence;

  /// Fraction of independent model samples agreeing on the displayed label.
  final double? agreement;
  final String? modelVersion;
  final bool experimental;

  /// Capture-quality score, not a pest-classification score.
  final double? qualityScore;
  final QualityBadge qualityBadge;
  final String plainLanguageQuality;
  final String userAdvice;
}

/// Guidance grounded in an actual local knowledge card, or an explicit
/// unavailable state when no reviewed card matches.
class GroundedGuidanceReport {
  const GroundedGuidanceReport({
    required this.cardId,
    required this.summary,
    required this.safeSteps,
    required this.safetyConcerns,
    this.callProfessionalWhen = const [],
    this.firstAid = const [],
    this.legalNote,
    this.sources = const [],
  });

  final String cardId;
  final String summary;
  final List<String> safeSteps;
  final Set<SafetyLevel> safetyConcerns;
  final List<String> callProfessionalWhen;
  final List<String> firstAid;
  final String? legalNote;
  final List<String> sources;
}
