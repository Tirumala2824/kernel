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
