import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'pest_json.dart';

/// Stores a list of [QualityReason] as comma-separated enum names.
class QualityReasonsConverter
    extends TypeConverter<List<QualityReason>, String> {
  const QualityReasonsConverter();

  @override
  List<QualityReason> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return [
      for (final name in fromDb.split(',')) QualityReason.values.byName(name),
    ];
  }

  @override
  String toSql(List<QualityReason> value) =>
      value.map((reason) => reason.name).join(',');
}

/// Stores a list of strings (e.g. file paths) as a JSON array.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      throw FormatException('Expected a JSON array', fromDb);
    }
    return List.unmodifiable([for (final value in decoded) value as String]);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores a string -> string map (e.g. card names by language) as a JSON
/// object.
class StringMapConverter extends TypeConverter<Map<String, String>, String> {
  const StringMapConverter();

  @override
  Map<String, String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! Map) {
      throw FormatException('Expected a JSON object', fromDb);
    }
    return Map.unmodifiable({
      for (final entry in decoded.entries)
        entry.key as String: entry.value as String,
    });
  }

  @override
  String toSql(Map<String, String> value) => jsonEncode(value);
}

/// Stores a [PestAnalysis] as JSON (see pest_json.dart).
class PestAnalysisConverter extends TypeConverter<PestAnalysis, String> {
  const PestAnalysisConverter();

  @override
  PestAnalysis fromSql(String fromDb) => pestAnalysisFromJson(_object(fromDb));

  @override
  String toSql(PestAnalysis value) => jsonEncode(pestAnalysisToJson(value));
}

/// Stores a [SoundAnalysis] as JSON.
class SoundAnalysisConverter extends TypeConverter<SoundAnalysis, String> {
  const SoundAnalysisConverter();

  @override
  SoundAnalysis fromSql(String fromDb) =>
      soundAnalysisFromJson(_object(fromDb));

  @override
  String toSql(SoundAnalysis value) => jsonEncode(soundAnalysisToJson(value));
}

/// Stores a [DistanceEstimate] as JSON.
class DistanceEstimateConverter
    extends TypeConverter<DistanceEstimate, String> {
  const DistanceEstimateConverter();

  @override
  DistanceEstimate fromSql(String fromDb) => distanceFromJson(_object(fromDb));

  @override
  String toSql(DistanceEstimate value) => jsonEncode(distanceToJson(value));
}

Map<String, Object?> _object(String fromDb) {
  final decoded = jsonDecode(fromDb);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Expected a JSON object', fromDb);
  }
  return decoded;
}
