import 'dart:typed_data';

import 'advice.dart';
import 'enums.dart';
import 'models.dart';

// Pest & Animal ID mode (guardrails §8 amended, §9). Camera and mic signals
// are found on the device, validated by the user, then analysed by the
// on-device LLM. AI analysis, user validation and a human verified finding
// are always kept separate.

enum PestGroup { insect, arachnid, rodent, reptile, other, notAPest, unknown }

/// Drives the safety banner. Ordered from least to most serious.
enum SafetyLevel { low, caution, medicalRisk, venomous, protectedWildlife }

enum SignalSource { camera, microphone, sensor }

enum SignalKind {
  motion,
  darkSpecks,
  eyeshine,
  embeddingMatch,
  modelBox,
  soundEvent,
}

/// Box in normalised image coordinates (0..1, origin top-left).
class NormalizedBox {
  const NormalizedBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class SignalCandidate {
  const SignalCandidate({
    required this.id,
    required this.source,
    required this.kind,
    required this.score,
    required this.detectedAt,
    this.box,
    this.hint,
  });

  final String id;
  final SignalSource source;
  final SignalKind kind;

  /// Detector score in 0..1. Not a probability.
  final double score;
  final DateTime detectedAt;
  final NormalizedBox? box;

  /// Best-matching sign or card id from zero-shot ranking, if any.
  final String? hint;
}

class ScoredLabel {
  const ScoredLabel({required this.label, required this.score});

  final String label;

  /// Raw model score, not calibrated.
  final double score;
}

/// Result of the on-device LLM analysis of one user-validated signal.
class PestAnalysis {
  const PestAnalysis({
    required this.analysisId,
    required this.createdAt,
    required this.source,
    required this.cardId,
    required this.commonName,
    required this.group,
    required this.taxonomyPath,
    required this.aiConfidence,
    required this.agreement,
    required this.samples,
    required this.keyFeatures,
    required this.anomalies,
    required this.insights,
    required this.safety,
    required this.modelVersion,
    required this.promptVersion,
    required this.latencyMs,
    this.experimental = true,
  });

  final String analysisId;
  final DateTime createdAt;
  final SignalSource source;

  /// Knowledge-card id from the constrained label set; null = no match.
  final String? cardId;
  final String commonName;
  final PestGroup group;

  /// Coarse to fine, e.g. ['Insect', 'Cockroach', 'German cockroach'].
  final List<String> taxonomyPath;

  /// Model's own estimate in 0..1. Self-reported, NOT calibrated.
  final double aiConfidence;

  /// Share of [samples] independent runs that chose the same label.
  final double agreement;
  final int samples;
  final List<String> keyFeatures;
  final List<String> anomalies;
  final List<String> insights;
  final SafetyLevel safety;
  final String modelVersion;
  final String promptVersion;
  final int latencyMs;

  /// Always true until a model is validated on labelled field data.
  final bool experimental;
}

class SoundAnalysis {
  const SoundAnalysis({
    required this.preFilter,
    required this.groupHint,
    required this.modelVersion,
    this.description,
  });

  /// Sound-classifier scores (e.g. YAMNet), top first.
  final List<ScoredLabel> preFilter;
  final PestGroup groupHint;
  final String modelVersion;

  /// Optional experimental LLM description of the clip.
  final String? description;
}

class PestImageRequest {
  const PestImageRequest({
    required this.crop,
    required this.allowedCardIds,
    this.context,
    this.candidate,
    this.languageTag,
    this.roomHint,
  });

  /// PNG or JPEG of the user-confirmed region.
  final Uint8List crop;

  /// Optional downscaled full frame for context.
  final Uint8List? context;
  final SignalCandidate? candidate;
  final List<String> allowedCardIds;
  final String? languageTag;

  /// e.g. 'kitchen'. Free text from the user's room name, sanitised.
  final String? roomHint;
}

class PestSoundRequest {
  const PestSoundRequest({
    required this.wav,
    required this.preFilter,
    required this.allowedCardIds,
    this.languageTag,
  });

  /// RIFF WAV, mono, 16 kHz, 16-bit, at most 30 s.
  final Uint8List wav;
  final List<ScoredLabel> preFilter;
  final List<String> allowedCardIds;
  final String? languageTag;
}

class PestGuideInput {
  const PestGuideInput({
    required this.analysis,
    required this.cards,
    this.question,
    this.languageTag,
  });

  final PestAnalysis analysis;

  /// Retrieved cards the answer must be grounded in.
  final List<KnowledgeCard> cards;
  final String? question;
  final String? languageTag;
}

/// On-device multimodal analysis (Gemma via LiteRT-LM). Every method never
/// throws; null or an empty stream means "use static copy".
abstract interface class PestAnalyzer {
  Stream<AdviceStatus> watchStatus();
  Future<PestAnalysis?> analyzeImage(PestImageRequest request);
  Future<SoundAnalysis?> describeSound(PestSoundRequest request);

  /// Optional slow region proposal on a still (box_2d). Empty when unsupported.
  Future<List<NormalizedBox>> proposeRegions(
    Uint8List image, {
    required List<String> labels,
  });

  /// Plain-language guidance grounded in [PestGuideInput.cards]; guarded.
  Stream<AdviceText> guide(PestGuideInput input);
}

enum DistanceMethod { arcoreDepth, focusDistance, unavailable }

class DistanceEstimate {
  const DistanceEstimate({
    required this.method,
    this.meters,
    this.lowMeters,
    this.highMeters,
    this.confidence,
    this.unavailableReason,
  });

  final DistanceMethod method;
  final double? meters;
  final double? lowMeters;
  final double? highMeters;

  /// 0..1 from the method's own quality signals.
  final double? confidence;

  /// Why no distance is shown, plus a fix hint key, when unavailable.
  final String? unavailableReason;

  bool get isAvailable => method != DistanceMethod.unavailable && meters != null;
}

class DistanceCapability {
  const DistanceCapability({
    required this.arcoreDepth,
    required this.focusDistance,
    this.reason,
  });

  final bool arcoreDepth;
  final bool focusDistance;
  final String? reason;
}

enum ListenMode { general, mosquitoCloseUp, night }

/// Camera, microphone and distance sensing for Pest ID (sense-ai plugin).
abstract interface class PestSenseEngine {
  /// Live Stage-0/1 candidates while the camera preview is running.
  Stream<List<SignalCandidate>> cameraCandidates();

  /// Full-resolution still plus candidate tiles (512-768 px crops).
  Future<CapturedStill?> captureStill({List<SignalCandidate> candidates});
  Future<void> setTorch(double level);

  /// Starts listening; emits sound-event candidates until [stopListening].
  Stream<SignalCandidate> listen(ListenMode mode);
  Future<void> stopListening();

  /// WAV for a sound candidate, held in memory only until discarded.
  Future<Uint8List?> clipFor(String candidateId);
  Future<List<ScoredLabel>> soundLabelsFor(String candidateId);

  Future<DistanceCapability> distanceCapability();

  /// Opens the Measure screen; returns unavailable with a reason if needed.
  Future<DistanceEstimate> measure({NormalizedBox? target});

  /// Drops every buffered still and clip.
  Future<void> discardMedia();
}

class CapturedStill {
  const CapturedStill({
    required this.stillId,
    required this.contextImage,
    required this.tiles,
  });

  final String stillId;

  /// Downscaled full frame (about 1024 px long edge).
  final Uint8List contextImage;
  final List<ImageTile> tiles;
}

class ImageTile {
  const ImageTile({required this.candidateId, required this.box, required this.image});

  final String candidateId;
  final NormalizedBox box;
  final Uint8List image;
}

/// Curated, sourced card per pest/animal (docs/knowledge-cards.md).
class KnowledgeCard {
  const KnowledgeCard({
    required this.id,
    required this.names,
    required this.group,
    required this.safety,
    required this.summary,
    required this.signs,
    required this.lookAlikes,
    required this.healthRisks,
    required this.safeSteps,
    required this.callProfessionalWhen,
    required this.firstAid,
    required this.legal,
    required this.sources,
    required this.reviewStatus,
  });

  final String id;

  /// languageTag -> name; 'en' is always present.
  final Map<String, String> names;
  final PestGroup group;
  final SafetyLevel safety;
  final String summary;
  final List<String> signs;
  final List<String> lookAlikes;
  final List<String> healthRisks;
  final List<String> safeSteps;
  final List<String> callProfessionalWhen;
  final List<String> firstAid;
  final String? legal;
  final List<String> sources;

  /// e.g. 'needs-expert-review'.
  final String reviewStatus;
}

class KnowledgeHit {
  const KnowledgeHit({required this.card, required this.score});

  final KnowledgeCard card;
  final double score;
}

abstract interface class KnowledgeService {
  Future<List<KnowledgeCard>> all();
  Future<KnowledgeCard?> get(String id);

  /// Semantic search (EmbeddingGemma); keyword fallback when no embedder.
  Future<List<KnowledgeHit>> search(String query, {int limit = 3});
}

class Sighting implements Tracked {
  const Sighting({
    required this.id,
    required this.role,
    required this.source,
    required this.observedAt,
    required this.userValidated,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.locationId,
    this.itemId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.distance,
    this.analysis,
    this.sound,
    this.userCardId,
    this.verifiedFinding,
    this.notes,
    this.mediaPath,
  });

  @override
  final String id;
  final Role role;
  final SignalSource source;
  final DateTime observedAt;

  /// Room/stack/container where it was seen.
  final String? locationId;
  final String? itemId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DistanceEstimate? distance;

  /// AI analysis (never edited after saving).
  final PestAnalysis? analysis;
  final SoundAnalysis? sound;

  /// The user confirmed the signal was real.
  final bool userValidated;

  /// Card the user picked, if they corrected the AI label.
  final String? userCardId;

  /// Human physical verification, separate from the AI analysis.
  final VerifiedFinding? verifiedFinding;
  final String? notes;

  /// App-private still or clip, only when the user chose to keep it.
  final String? mediaPath;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

class SightingDraft {
  const SightingDraft({
    required this.role,
    required this.source,
    required this.observedAt,
    required this.userValidated,
    this.locationId,
    this.itemId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.distance,
    this.analysis,
    this.sound,
    this.userCardId,
    this.notes,
    this.mediaPath,
  });

  final Role role;
  final SignalSource source;
  final DateTime observedAt;
  final bool userValidated;
  final String? locationId;
  final String? itemId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DistanceEstimate? distance;
  final PestAnalysis? analysis;
  final SoundAnalysis? sound;
  final String? userCardId;
  final String? notes;
  final String? mediaPath;
}

abstract interface class SightingRepository {
  Future<Sighting> create(SightingDraft draft);
  Future<Sighting?> get(String id);

  /// Newest first; archived locations excluded.
  Stream<List<Sighting>> watchRecent({Role? role, String? locationId, int limit = 100});
  Stream<List<Sighting>> watchForItem(String itemId);

  /// Set once by a human; never overwritten.
  Future<Sighting> setVerifiedFinding(String id, VerifiedFinding finding);
  Future<void> delete(String id);
}
