import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Source of "now". Injected so tests control time; production uses the
/// device clock.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();

const _uuid = Uuid();

/// New UUID v4 for a row id.
String newId() => _uuid.v4();

/// Rejects blank user-entered text.
String requireText(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return trimmed;
}

double requireNonNegative(double value, String name) {
  if (value.isNaN || value < 0) {
    throw ArgumentError.value(value, name, 'must be zero or more');
  }
  return value;
}

/// Emits [compute] once on listen and again whenever any of [tables]
/// changes. Recomputations run one at a time, in order.
Stream<T> watchTables<T>(
  GeneratedDatabase db,
  Set<ResultSetImplementation<dynamic, dynamic>> tables,
  Future<T> Function() compute,
) {
  return db
      .customSelect('SELECT 1', readsFrom: tables)
      .watch()
      .asyncMap((_) => compute());
}
