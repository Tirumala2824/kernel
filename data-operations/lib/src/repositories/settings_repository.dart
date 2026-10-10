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
  static const researchModeOptInKey = 'researchModeOptIn';
  static const languageTagKey = 'languageTag';
  static const hapticsKey = 'haptics';
  static const voicePromptsKey = 'voicePrompts';
  static const onboardingDoneKey = 'onboardingDone';
  static const localAdviceOptInKey = 'localAdviceOptIn';
  static const mapsConsentKey = 'mapsConsent';
  static const keepSightingMediaKey = 'keepSightingMedia';

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
      _watchBool(retainAudioOptInKey, defaultValue: false);

  @override
  Future<void> setRetainAudioOptIn(bool value) =>
      _putBool(retainAudioOptInKey, value);

  /// False unless the user has explicitly opted in. Separate from the
  /// audio retention opt-in.
  @override
  Stream<bool> watchResearchModeOptIn() =>
      _watchBool(researchModeOptInKey, defaultValue: false);

  @override
  Future<void> setResearchModeOptIn(bool value) =>
      _putBool(researchModeOptInKey, value);

  /// Null (follow the device) until the user picks a language.
  @override
  Stream<String?> watchLanguageTag() => _watchValue(languageTagKey).distinct();

  /// A null or blank [tag] removes the choice, so the device language is
  /// followed again.
  @override
  Future<void> setLanguageTag(String? tag) async {
    final value = blankToNull(tag);
    if (value == null) {
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.equals(languageTagKey))).go();
    } else {
      await _put(languageTagKey, value);
    }
  }

  /// True unless the user turned haptics off.
  @override
  Stream<bool> watchHaptics() => _watchBool(hapticsKey, defaultValue: true);

  @override
  Future<void> setHaptics(bool value) => _putBool(hapticsKey, value);

  /// False unless the user turned spoken prompts on.
  @override
  Stream<bool> watchVoicePrompts() =>
      _watchBool(voicePromptsKey, defaultValue: false);

  @override
  Future<void> setVoicePrompts(bool value) => _putBool(voicePromptsKey, value);

  /// False until onboarding has been completed once.
  @override
  Stream<bool> watchOnboardingDone() =>
      _watchBool(onboardingDoneKey, defaultValue: false);

  @override
  Future<void> setOnboardingDone(bool value) =>
      _putBool(onboardingDoneKey, value);

  /// False unless the user has explicitly turned on the on-phone assistant
  /// (local LLM advice, guardrails §8).
  @override
  Stream<bool> watchLocalAdviceOptIn() =>
      _watchBool(localAdviceOptInKey, defaultValue: false);

  @override
  Future<void> setLocalAdviceOptIn(bool value) =>
      _putBool(localAdviceOptInKey, value);

  /// False until the user consents to Google map tiles and routes
  /// (guardrails §7). This package only stores the choice; it makes no
  /// network calls.
  @override
  Stream<bool> watchMapsConsent() =>
      _watchBool(mapsConsentKey, defaultValue: false);

  @override
  Future<void> setMapsConsent(bool value) => _putBool(mapsConsentKey, value);

  /// False unless the user chose to keep validated stills/clips with saved
  /// sightings. While false, `sightings.create` refuses a media path.
  @override
  Stream<bool> watchKeepSightingMedia() =>
      _watchBool(keepSightingMediaKey, defaultValue: false);

  @override
  Future<void> setKeepSightingMedia(bool value) =>
      _putBool(keepSightingMediaKey, value);

  /// Current research opt-in, read inside other repositories' transactions.
  static Future<bool> researchModeEnabled(KernelDatabase db) =>
      _readBool(db, researchModeOptInKey);

  /// Current keep-sighting-media choice, read inside other repositories'
  /// transactions.
  static Future<bool> keepSightingMediaEnabled(KernelDatabase db) =>
      _readBool(db, keepSightingMediaKey);

  static Future<bool> _readBool(KernelDatabase db, String key) async {
    final row = await (db.select(
      db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value == 'true';
  }

  Stream<bool> _watchBool(String key, {required bool defaultValue}) =>
      _watchValue(key)
          .map(
            (value) => switch (value) {
              'true' => true,
              'false' => false,
              _ => defaultValue,
            },
          )
          .distinct();

  Future<void> _putBool(String key, bool value) =>
      _put(key, value ? 'true' : 'false');

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
