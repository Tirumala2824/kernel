import 'dart:io';

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

/// Optional user-entered text: trimmed, with blank meaning "not given".
String? blankToNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

double requireNonNegative(double value, String name) {
  if (value.isNaN || value < 0) {
    throw ArgumentError.value(value, name, 'must be zero or more');
  }
  return value;
}

/// Rejects NaN and infinities (they cannot be stored or exported).
double requireFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be a finite number');
  }
  return value;
}

/// Rejects values outside 0..1 (scores, AI-estimated confidence).
double requireUnitInterval(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw ArgumentError.value(value, name, 'must be between 0 and 1');
  }
  return value;
}

/// Deletes an app-private file. Missing files are fine; a link is removed
/// without touching its target, and directories are never touched.
Future<void> deleteFileIfPresent(String path) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  try {
    switch (type) {
      case FileSystemEntityType.file:
        await File(path).delete();
      case FileSystemEntityType.link:
        await Link(path).delete();
      default:
        return;
    }
  } on PathNotFoundException {
    // Already gone.
  }
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
