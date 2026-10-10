import 'package:kernel_contracts/kernel_contracts.dart';

// JSON codecs for the Pest ID value types stored in the sightings table.
// Every object carries a format version `v` so later builds can read old
// rows. The stored AI analysis is written once and never edited.

const _formatVersion = 1;

Map<String, Object?> pestAnalysisToJson(PestAnalysis a) => {
  'v': _formatVersion,
  'analysisId': a.analysisId,
  'createdAt': a.createdAt.toUtc().toIso8601String(),
  'source': a.source.name,
  'cardId': a.cardId,
  'commonName': a.commonName,
  'group': a.group.name,
  'taxonomyPath': a.taxonomyPath,
  'aiConfidence': a.aiConfidence,
  'agreement': a.agreement,
  'samples': a.samples,
  'keyFeatures': a.keyFeatures,
  'anomalies': a.anomalies,
  'insights': a.insights,
  'safety': a.safety.name,
  'modelVersion': a.modelVersion,
  'promptVersion': a.promptVersion,
  'latencyMs': a.latencyMs,
  'experimental': a.experimental,
};

PestAnalysis pestAnalysisFromJson(Map<String, Object?> json) => PestAnalysis(
  analysisId: json['analysisId']! as String,
  createdAt: DateTime.parse(json['createdAt']! as String),
  source: SignalSource.values.byName(json['source']! as String),
  cardId: json['cardId'] as String?,
  commonName: json['commonName']! as String,
  group: PestGroup.values.byName(json['group']! as String),
  taxonomyPath: _strings(json['taxonomyPath']),
  aiConfidence: _double(json['aiConfidence']),
  agreement: _double(json['agreement']),
  samples: (json['samples']! as num).toInt(),
  keyFeatures: _strings(json['keyFeatures']),
  anomalies: _strings(json['anomalies']),
  insights: _strings(json['insights']),
  safety: SafetyLevel.values.byName(json['safety']! as String),
  modelVersion: json['modelVersion']! as String,
  promptVersion: json['promptVersion']! as String,
  latencyMs: (json['latencyMs']! as num).toInt(),
  experimental: json['experimental']! as bool,
);

Map<String, Object?> soundAnalysisToJson(SoundAnalysis s) => {
  'v': _formatVersion,
  'preFilter': [
    for (final label in s.preFilter)
      {'label': label.label, 'score': label.score},
  ],
  'groupHint': s.groupHint.name,
  'modelVersion': s.modelVersion,
  'description': s.description,
};

SoundAnalysis soundAnalysisFromJson(Map<String, Object?> json) => SoundAnalysis(
  preFilter: List.unmodifiable([
    for (final entry in json['preFilter']! as List<Object?>)
      if (entry case final Map<String, Object?> label)
        ScoredLabel(
          label: label['label']! as String,
          score: _double(label['score']),
        ),
  ]),
  groupHint: PestGroup.values.byName(json['groupHint']! as String),
  modelVersion: json['modelVersion']! as String,
  description: json['description'] as String?,
);

Map<String, Object?> distanceToJson(DistanceEstimate d) => {
  'v': _formatVersion,
  'method': d.method.name,
  'meters': d.meters,
  'lowMeters': d.lowMeters,
  'highMeters': d.highMeters,
  'confidence': d.confidence,
  'unavailableReason': d.unavailableReason,
};

DistanceEstimate distanceFromJson(Map<String, Object?> json) =>
    DistanceEstimate(
      method: DistanceMethod.values.byName(json['method']! as String),
      meters: _doubleOrNull(json['meters']),
      lowMeters: _doubleOrNull(json['lowMeters']),
      highMeters: _doubleOrNull(json['highMeters']),
      confidence: _doubleOrNull(json['confidence']),
      unavailableReason: json['unavailableReason'] as String?,
    );

List<String> _strings(Object? value) =>
    List.unmodifiable([for (final s in value! as List<Object?>) s! as String]);

double _double(Object? value) => (value! as num).toDouble();

double? _doubleOrNull(Object? value) => (value as num?)?.toDouble();
