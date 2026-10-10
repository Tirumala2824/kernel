import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'location_repository.dart';
import 'settings_repository.dart';

/// Pest ID sightings (guardrails §9). Three records stay separate: the AI
/// analysis (`analysis`, `sound`; never edited after saving, trigger-
/// guarded), the user's validation (`userValidated`, `userCardId`) and the
/// human verified finding (set once by [setVerifiedFinding]).
class DriftSightingRepository implements SightingRepository {
  DriftSightingRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Stores a sighting.
  ///
  /// - [ArgumentError] for an unknown or archived location or item; a
  ///   latitude without a longitude (or the reverse), out-of-range
  ///   coordinates, a GPS fix without `accuracyMeters`, or an accuracy
  ///   without a fix; a distance that is negative, non-finite, or given
  ///   with method `unavailable`; an analysis whose source differs from the
  ///   sighting's, whose AI-estimated confidence or agreement is outside
  ///   0..1, with fewer than one sample, a blank card id or model version,
  ///   or `experimental == false` (always experimental until validated on
  ///   field data); a sound analysis with a non-finite score or a blank
  ///   model version; a media path that is not absolute.
  /// - [StateError] when a media path is given while the keep-sighting-media
  ///   setting is off.
  @override
  Future<Sighting> create(SightingDraft draft) async {
    _checkPosition(draft);
    _checkDistance(draft.distance);
    _checkAnalysis(draft.analysis, draft.source);
    _checkSound(draft.sound);
    final mediaPath = _mediaPath(draft.mediaPath);
    return _db.transaction(() async {
      final locationId = draft.locationId;
      if (locationId != null) {
        final location = await (_db.select(
          _db.locations,
        )..where((l) => l.id.equals(locationId))).getSingleOrNull();
        if (location == null) {
          throw ArgumentError.value(locationId, 'locationId', 'unknown');
        }
        if (location.archivedAt != null) {
          throw ArgumentError.value(locationId, 'locationId', 'is archived');
        }
      }
      final itemId = draft.itemId;
      if (itemId != null) {
        final item = await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(itemId))).getSingleOrNull();
        if (item == null) {
          throw ArgumentError.value(itemId, 'itemId', 'unknown item');
        }
        if (item.archivedAt != null) {
          throw ArgumentError.value(itemId, 'itemId', 'is archived');
        }
      }
      if (mediaPath != null &&
          !await DriftSettingsRepository.keepSightingMediaEnabled(_db)) {
        throw StateError('Keeping sighting media is off');
      }
      final now = _clock().toUtc();
      final row = await _db
          .into(_db.sightings)
          .insertReturning(
            SightingsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              role: draft.role,
              source: draft.source,
              observedAt: draft.observedAt.toUtc(),
              locationId: Value(locationId),
              itemId: Value(itemId),
              latitude: Value(draft.latitude),
              longitude: Value(draft.longitude),
              accuracyMeters: Value(draft.accuracyMeters),
              distance: Value(draft.distance),
              analysis: Value(draft.analysis),
              sound: Value(draft.sound),
              userValidated: draft.userValidated,
              userCardId: Value(blankToNull(draft.userCardId)),
              notes: Value(blankToNull(draft.notes)),
              mediaPath: Value(mediaPath),
            ),
          );
      return row.toModel();
    });
  }

  @override
  Future<Sighting?> get(String id) async => (await _row(id))?.toModel();

  /// Newest first (observedAt, then createdAt, then id), at most [limit]
  /// (must be positive). Sightings in an archived location or on an
  /// archived item are excluded. [locationId] covers that location and
  /// every location nested below it, matched by the sighting's own location
  /// or by the current location of its item.
  @override
  Stream<List<Sighting>> watchRecent({
    Role? role,
    String? locationId,
    int limit = 100,
  }) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }
    return watchTables(_db, {
      _db.sightings,
      _db.locations,
      _db.items,
    }, () => _recent(role, locationId, limit));
  }

  /// Every sighting on [itemId], newest first. It is item history, so the
  /// sighting's location being archived does not hide it.
  @override
  Stream<List<Sighting>> watchForItem(String itemId) {
    final query = _db.select(_db.sightings)
      ..where((s) => s.itemId.equals(itemId))
      ..orderBy(_newestFirst);
    return query.watch().map(
      (rows) => List.unmodifiable([for (final row in rows) row.toModel()]),
    );
  }

  /// Sets the human verified finding once. [ArgumentError] for an unknown
  /// id; [StateError] when a finding is already set (it is never
  /// overwritten, even with the same value). A trigger enforces the same
  /// rule below this layer.
  @override
  Future<Sighting> setVerifiedFinding(String id, VerifiedFinding finding) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null) {
        throw ArgumentError.value(id, 'id', 'unknown sighting');
      }
      if (row.verifiedFinding != null) {
        throw StateError(
          'Sighting $id already has a verified finding; it is never '
          'overwritten',
        );
      }
      await (_db.update(_db.sightings)..where((s) => s.id.equals(id))).write(
        SightingsCompanion(
          verifiedFinding: Value(finding),
          updatedAt: Value(_clock().toUtc()),
        ),
      );
      return (await _row(id))!.toModel();
    });
  }

  /// User-initiated delete of one sighting and its kept media file (a
  /// missing file is fine). The file goes first, so a failure leaves the
  /// row and the call can be repeated. An unknown id is a no-op.
  @override
  Future<void> delete(String id) async {
    final row = await _row(id);
    if (row == null) return;
    final mediaPath = row.mediaPath;
    if (mediaPath != null) await deleteFileIfPresent(mediaPath);
    await (_db.delete(_db.sightings)..where((s) => s.id.equals(id))).go();
  }

  Future<SightingRow?> _row(String id) => (_db.select(
    _db.sightings,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<List<Sighting>> _recent(Role? role, String? locationId, int limit) {
    return _db.transaction(() async {
      final subtree = locationId == null
          ? null
          : await locationSubtree(_db, locationId);
      return activeSightings(
        _db,
        role: role,
        locationIds: subtree,
        limit: limit,
      );
    });
  }

  static List<OrderingTerm Function($SightingsTable)> get _newestFirst => [
    (s) => OrderingTerm.desc(s.observedAt),
    (s) => OrderingTerm.desc(s.createdAt),
    (s) => OrderingTerm.desc(s.id),
  ];

  static void _checkPosition(SightingDraft draft) {
    final lat = draft.latitude;
    final lng = draft.longitude;
    final accuracy = draft.accuracyMeters;
    if ((lat == null) != (lng == null)) {
      throw ArgumentError.value(
        lat ?? lng,
        'latitude/longitude',
        'must be given together',
      );
    }
    if (lat == null || lng == null) {
      if (accuracy != null) {
        throw ArgumentError.value(
          accuracy,
          'accuracyMeters',
          'needs a latitude and longitude',
        );
      }
      return;
    }
    if (!lat.isFinite || lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'latitude', 'must be within -90..90');
    }
    if (!lng.isFinite || lng < -180 || lng > 180) {
      throw ArgumentError.value(lng, 'longitude', 'must be within -180..180');
    }
    if (accuracy == null) {
      throw ArgumentError.value(
        accuracy,
        'accuracyMeters',
        'is required with a GPS fix',
      );
    }
    requireNonNegative(
      requireFinite(accuracy, 'accuracyMeters'),
      'accuracyMeters',
    );
  }

  static void _checkDistance(DistanceEstimate? distance) {
    if (distance == null) return;
    for (final (value, name) in [
      (distance.meters, 'distance.meters'),
      (distance.lowMeters, 'distance.lowMeters'),
      (distance.highMeters, 'distance.highMeters'),
    ]) {
      if (value != null) requireNonNegative(requireFinite(value, name), name);
    }
    final confidence = distance.confidence;
    if (confidence != null) {
      requireUnitInterval(confidence, 'distance.confidence');
    }
    if (distance.method == DistanceMethod.unavailable &&
        distance.meters != null) {
      throw ArgumentError.value(
        distance.meters,
        'distance.meters',
        'must be null when the method is unavailable',
      );
    }
  }

  static void _checkAnalysis(PestAnalysis? analysis, SignalSource source) {
    if (analysis == null) return;
    if (analysis.source != source) {
      throw ArgumentError.value(
        analysis.source,
        'analysis.source',
        'differs from the sighting source $source',
      );
    }
    requireUnitInterval(analysis.aiConfidence, 'analysis.aiConfidence');
    requireUnitInterval(analysis.agreement, 'analysis.agreement');
    if (analysis.samples < 1) {
      throw ArgumentError.value(
        analysis.samples,
        'analysis.samples',
        'must be at least 1',
      );
    }
    if (analysis.latencyMs < 0) {
      throw ArgumentError.value(
        analysis.latencyMs,
        'analysis.latencyMs',
        'must be zero or more',
      );
    }
    final cardId = analysis.cardId;
    if (cardId != null && cardId.trim().isEmpty) {
      throw ArgumentError.value(cardId, 'analysis.cardId', 'is blank');
    }
    requireText(analysis.modelVersion, 'analysis.modelVersion');
    if (!analysis.experimental) {
      // Guardrail §9: never present an unvalidated model as settled.
      throw ArgumentError.value(
        analysis.experimental,
        'analysis.experimental',
        'Pest ID analyses are always experimental',
      );
    }
  }

  static void _checkSound(SoundAnalysis? sound) {
    if (sound == null) return;
    requireText(sound.modelVersion, 'sound.modelVersion');
    for (final label in sound.preFilter) {
      requireFinite(label.score, 'sound.preFilter.score');
    }
  }

  static String? _mediaPath(String? path) {
    final trimmed = blankToNull(path);
    if (trimmed != null && !p.isAbsolute(trimmed)) {
      throw ArgumentError.value(path, 'mediaPath', 'must be absolute');
    }
    return trimmed;
  }
}

/// Sightings that are neither in an archived location nor on an archived
/// item, newest first (observedAt, createdAt, id).
///
/// - [role]: only sightings saved under that role.
/// - [locationIds]: only sightings whose own location, or whose item's
///   current location, is one of these.
/// - [since]: only sightings observed at or after it.
Future<List<Sighting>> activeSightings(
  KernelDatabase db, {
  Role? role,
  Set<String>? locationIds,
  DateTime? since,
  int? limit,
}) async {
  final s = db.sightings;
  final l = db.locations;
  final i = db.items;
  final query =
      db.select(s).join([
          leftOuterJoin(l, l.id.equalsExp(s.locationId)),
          leftOuterJoin(i, i.id.equalsExp(s.itemId)),
        ])
        ..where(
          Expression.and([
            // Null for "no location/item" as well as "not archived".
            l.archivedAt.isNull(),
            i.archivedAt.isNull(),
            if (role != null) s.role.equalsValue(role),
            if (locationIds != null)
              s.locationId.isIn(locationIds) | i.locationId.isIn(locationIds),
            if (since != null) s.observedAt.isBiggerOrEqualValue(since.toUtc()),
          ]),
        )
        ..orderBy([
          OrderingTerm.desc(s.observedAt),
          OrderingTerm.desc(s.createdAt),
          OrderingTerm.desc(s.id),
        ]);
  if (limit != null) query.limit(limit);
  final rows = await query.get();
  return List<Sighting>.unmodifiable([
    for (final row in rows) row.readTable(s).toModel(),
  ]);
}
