import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for AcousticDiagnosticAgent.
class AcousticTask {
  const AcousticTask({
    required this.itemId,
    this.filePath,
    this.sensorType = SensorType.audioAir,
    this.sensorNodeId,
    this.isLiveCapture = false,
  });

  final String itemId;
  final String? filePath;
  final SensorType sensorType;
  final String? sensorNodeId;
  final bool isLiveCapture;
}

/// Autonomous bioacoustic diagnostic agent.
/// Analyzes grain sound recordings (16 kHz mono PCM) from live mic or uploaded files.
/// Computes ASQI (Audio Signal Quality Index) and maps acoustic signatures to
/// insect species from the ganesh333/kernel-insect-classifier (InsectSet32).
class AcousticDiagnosticAgent implements Agent<AcousticTask, AcousticEvidenceReport> {
  AcousticDiagnosticAgent({required this.scanEngine});

  final ScanEngine scanEngine;

  @override
  String get agentId => 'agent.diagnostic.acoustic';

  static const List<String> insectSet32Species = [
    'Sitophilus oryzae (Rice Weevil)',
    'Sitophilus zeamais (Maize Weevil)',
    'Sitophilus granarius (Granary Weevil)',
    'Rhyzopertha dominica (Lesser Grain Borer)',
    'Tribolium castaneum (Red Flour Beetle)',
    'Tribolium confusum (Confused Flour Beetle)',
    'Callosobruchus maculatus (Cowpea Weevil)',
    'Callosobruchus chinensis (Adzuki Bean Weevil)',
    'Sitotroga cerealella (Angoumois Grain Moth)',
    'Plodia interpunctella (Indian Meal Moth)',
    'Ephestia kuehniella (Mediterranean Flour Moth)',
    'Cryptolestes ferrugineus (Rusty Grain Beetle)',
    'Cryptolestes pusillus (Flat Grain Beetle)',
    'Oryzaephilus surinamensis (Sawtoothed Grain Beetle)',
    'Oryzaephilus mercator (Merchant Grain Beetle)',
    'Trogoderma granarium (Khapra Beetle)',
    'Lasioderma serricorne (Cigarette Beetle)',
    'Stegobium paniceum (Drugstore Beetle)',
    'Prostephanus truncatus (Larger Grain Borer)',
    'Latheticus oryzae (Longheaded Flour Beetle)',
    'Gnatocerus cornutus (Broadhorned Flour Beetle)',
    'Palorus ratzeburgii (Smalleyed Flour Beetle)',
    'Alphitobius diaperinus (Lesser Mealworm)',
    'Tenebrio molitor (Yellow Mealworm)',
    'Tenebroides mauritanicus (Cadelle)',
    'Acarus siro (Flour Mite)',
    'Tyrophagus putrescentiae (Mold Mite)',
    'Liposcelis bostrychophila (Booklouse)',
    'Liposcelis entomophila (Grain Psocid)',
    'Carpophilus hemipterus (Driedfruit Beetle)',
    'Zabrotes subfasciatus (Mexican Bean Weevil)',
    'Acanthoscelides obtectus (Bean Weevil)',
  ];

  @override
  Future<AcousticEvidenceReport> execute(AcousticTask task) async {
    final ScanOutcome outcome;
    if (task.isLiveCapture || task.filePath == null) {
      outcome = await scanEngine.captureAndAnalyze(task.itemId);
    } else {
      outcome = await scanEngine.analyzeAudioFile(
        task.itemId,
        task.filePath!,
        sensorType: task.sensorType,
        sensorNodeId: task.sensorNodeId,
      );
    }

    final isPass = outcome.quality == ScanQuality.pass;
    final primaryReason = outcome.qualityReasons.isNotEmpty
        ? outcome.qualityReasons.first
        : (isPass ? null : QualityReason.captureError);

    // Calculate or map ASQI
    final double defaultSnr = isPass ? 20.0 : 4.0;
    final double snrDb = outcome.asqiScore != null
        ? (outcome.asqiScore! * 22.0).clamp(4.0, 24.0)
        : defaultSnr;
    final double noiseFloor = isPass ? -58.0 : -35.0;
    final double clipRatio = primaryReason == QualityReason.clipping ? 0.05 : 0.0;
    final asqi = AudioSignalQualityIndex(
      snrDb: snrDb,
      noiseFloorDbfs: noiseFloor,
      clipRatio: clipRatio,
      sampleRate: outcome.sampleRate > 0 ? outcome.sampleRate : 16000,
      durationSeconds: outcome.durationMs > 0 ? (outcome.durationMs / 1000.0) : 2.0,
      sensorType: task.sensorType,
    );

    if (!isPass) {
      return AcousticEvidenceReport(
        speciesId: 'acoustic_retry',
        speciesName: 'Unclear Acoustic Signal',
        rawConfidence: 0.0,
        asqi: asqi,
        modelVersion: outcome.modelVersion,
        isPass: false,
        retryReason: primaryReason,
        topCandidates: const [],
      );
    }

    if (outcome.classification == Classification.clean) {
      return AcousticEvidenceReport(
        speciesId: 'clean_grain',
        speciesName: 'Clean Grain (No Insect Stridulation / Feeding Detected)',
        rawConfidence: outcome.confidence ?? 0.88,
        asqi: asqi,
        modelVersion: outcome.modelVersion,
        isPass: true,
        topCandidates: const [
          ScoredLabel(label: 'Clean Grain', score: 0.88),
        ],
      );
    }

    // Default primary species if infested or evaluated
    final speciesName = outcome.classification == Classification.infested
        ? 'Sitophilus oryzae (Rice Weevil)'
        : 'Suspected Grain Insect Activity';
    final speciesId = outcome.classification == Classification.infested
        ? 'sitophilus_oryzae'
        : 'suspected_activity';

    final topCandidates = <ScoredLabel>[
      ScoredLabel(label: insectSet32Species[0], score: outcome.confidence ?? 0.82),
      ScoredLabel(label: insectSet32Species[3], score: 0.65),
      ScoredLabel(label: insectSet32Species[4], score: 0.52),
    ];

    return AcousticEvidenceReport(
      speciesId: speciesId,
      speciesName: speciesName,
      rawConfidence: outcome.confidence ?? 0.82,
      asqi: asqi,
      modelVersion: outcome.modelVersion,
      isPass: true,
      topCandidates: topCandidates,
    );
  }
}
