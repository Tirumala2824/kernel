import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

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
