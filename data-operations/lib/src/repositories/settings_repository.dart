import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../support.dart';

/// Settings stored as key/value rows. Defaults live here, not in the
/// database, so a fresh install has no rows at all.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db, this._clock);

  static const activeRoleKey = 'activeRole';
  static const retainAudioOptInKey = 'retainAudioOptIn';

  final KernelDatabase _db;
  final Clock _clock;

  /// Null until the user picks a role. Changing role never touches records.
  @override
  Stream<Role?> watchActiveRole() => _watchValue(activeRoleKey).map((value) {
    if (value == null) return null;
    for (final role in Role.values) {
      if (role.name == value) return role;
    }
    return null;
  }).distinct();

  @override
  Future<void> setActiveRole(Role role) => _put(activeRoleKey, role.name);

  /// False unless the user has explicitly opted in.
  @override
  Stream<bool> watchRetainAudioOptIn() =>
      _watchValue(retainAudioOptInKey)
          .map((value) => value == 'true')
          .distinct();

  @override
  Future<void> setRetainAudioOptIn(bool value) =>
      _put(retainAudioOptInKey, value ? 'true' : 'false');

  Stream<String?> _watchValue(String key) {
    final query = _db.select(_db.settings)..where((s) => s.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<void> _put(String key, String value) async {
    final now = _clock().toUtc();
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            key: key,
            value: value,
          ),
          onConflict: DoUpdate(
            (_) =>
                SettingsCompanion(value: Value(value), updatedAt: Value(now)),
            target: [_db.settings.key],
          ),
        );
  }
}
