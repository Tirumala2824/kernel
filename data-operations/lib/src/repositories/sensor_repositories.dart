import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'location_repository.dart';

/// Paired BLE sensor nodes (guardrails §10). Only the key fingerprint is
/// stored; the per-device key stays in Keystore-backed storage owned by
/// sensor-link.
class DriftSensorNodeRepository implements SensorNodeRepository {
  DriftSensorNodeRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Inserts [node], or updates the stored node with the same id.
  ///
  /// The data layer owns `createdAt`, `updatedAt` and `syncState`. On an
  /// update the identity, name, type, protocol and firmware versions and
  /// key fingerprint are replaced; `lastSeenAt` and `batteryPercent` only
  /// when given (null means "not reported"); the placement is kept, since
  /// [setPlacement] is the only way to move a node. A new node's placement
  /// is taken from [node].
  ///
  /// [ArgumentError] for a blank id, address, name or firmware version; a
  /// fingerprint that is not exactly 8 hex characters (it must never be
  /// the key itself); a negative protocol version; a battery outside
  /// 0..100; a device address already paired under another node id; an
  /// unknown or archived location or item on a new node.
  @override
  Future<SensorNode> upsert(SensorNode node) async {
    final id = requireText(node.id, 'id');
    final address = requireText(node.deviceAddress, 'deviceAddress');
    final name = requireText(node.name, 'name');
    final firmware = requireText(node.firmwareVersion, 'firmwareVersion');
    final fingerprint = _fingerprint(node.keyFingerprint);
    if (node.protocolVersion < 0) {
      throw ArgumentError.value(
        node.protocolVersion,
        'protocolVersion',
        'must be zero or more',
      );
    }
    _checkBattery(node.batteryPercent);
    return _db.transaction(() async {
      final other =
          await (_db.select(_db.sensorNodes)..where(
                (n) => n.deviceAddress.equals(address) & n.id.equals(id).not(),
              ))
              .getSingleOrNull();
      if (other != null) {
        throw ArgumentError.value(
          address,
          'deviceAddress',
          'is already paired as node ${other.id}',
        );
      }
      final existing = await _row(id);
      final now = _clock().toUtc();
      if (existing == null) {
        await checkPlacement(
          _db,
          SensorPlacement(locationId: node.locationId, itemId: node.itemId),
        );
        await _db
            .into(_db.sensorNodes)
            .insert(
              SensorNodesCompanion.insert(
                id: id,
                createdAt: now,
                updatedAt: now,
                deviceAddress: address,
                name: name,
                type: node.type,
                protocolVersion: node.protocolVersion,
                firmwareVersion: firmware,
                keyFingerprint: fingerprint,
                locationId: Value(node.locationId),
                itemId: Value(node.itemId),
                lastSeenAt: Value(node.lastSeenAt?.toUtc()),
                batteryPercent: Value(node.batteryPercent),
              ),
            );
      } else {
        await (_db.update(
          _db.sensorNodes,
        )..where((n) => n.id.equals(id))).write(
          SensorNodesCompanion(
            updatedAt: Value(now),
            deviceAddress: Value(address),
            name: Value(name),
            type: Value(node.type),
            protocolVersion: Value(node.protocolVersion),
            firmwareVersion: Value(firmware),
            keyFingerprint: Value(fingerprint),
            lastSeenAt: Value(node.lastSeenAt?.toUtc() ?? existing.lastSeenAt),
            batteryPercent: Value(
              node.batteryPercent ?? existing.batteryPercent,
            ),
          ),
        );
      }
      return (await _row(id))!.toModel();
    });
  }

  @override
  Future<SensorNode?> get(String id) async => (await _row(id))?.toModel();

  /// Every paired node, by name.
  @override
  Stream<List<SensorNode>> watchAll() {
    final query = _db.select(_db.sensorNodes)
      ..orderBy([
        (n) => OrderingTerm.asc(n.name),
        (n) => OrderingTerm.asc(n.id),
      ]);
    return query.watch().map(
      (rows) => List.unmodifiable([for (final row in rows) row.toModel()]),
    );
  }

  /// Moves (or unplaces, with both ids null) a node. Events already
  /// recorded keep the placement they were recorded with. [ArgumentError]
  /// for an unknown node or an unknown or archived location or item.
  @override
  Future<SensorNode> setPlacement(String id, SensorPlacement placement) {
    return _db.transaction(() async {
      if (await _row(id) == null) {
        throw ArgumentError.value(id, 'id', 'unknown sensor node');
      }
      await checkPlacement(_db, placement);
      await (_db.update(_db.sensorNodes)..where((n) => n.id.equals(id))).write(
        SensorNodesCompanion(
          locationId: Value(placement.locationId),
          itemId: Value(placement.itemId),
          updatedAt: Value(_clock().toUtc()),
        ),
      );
      return (await _row(id))!.toModel();
    });
  }

  /// Forgets a node together with its recorded events (user-initiated). An
  /// unknown id is a no-op.
  @override
  Future<void> delete(String id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.sensorEvents,
      )..where((e) => e.nodeId.equals(id))).go();
      await (_db.delete(_db.sensorNodes)..where((n) => n.id.equals(id))).go();
    });
  }

  Future<SensorNodeRow?> _row(String id) => (_db.select(
    _db.sensorNodes,
  )..where((n) => n.id.equals(id))).getSingleOrNull();

  static final _hex8 = RegExp(r'^[0-9a-fA-F]{8}$');

  static String _fingerprint(String value) {
    final trimmed = value.trim();
    if (!_hex8.hasMatch(trimmed)) {
      throw ArgumentError.value(
        '<${trimmed.length} chars>',
        'keyFingerprint',
        'must be exactly 8 hex characters',
      );
    }
    return trimmed.toLowerCase();
  }

  static void _checkBattery(int? percent) {
    if (percent != null && (percent < 0 || percent > 100)) {
      throw ArgumentError.value(
        percent,
        'batteryPercent',
        'must be within 0..100',
      );
    }
  }
}

/// Throws [ArgumentError] when [placement] names an unknown or archived
/// location or item.
Future<void> checkPlacement(
  KernelDatabase db,
  SensorPlacement placement,
) async {
  final locationId = placement.locationId;
  if (locationId != null) {
    final location = await (db.select(
      db.locations,
    )..where((l) => l.id.equals(locationId))).getSingleOrNull();
    if (location == null) {
      throw ArgumentError.value(locationId, 'locationId', 'unknown location');
    }
    if (location.archivedAt != null) {
      throw ArgumentError.value(locationId, 'locationId', 'is archived');
    }
  }
  final itemId = placement.itemId;
  if (itemId != null) {
    final item = await (db.select(
      db.items,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null) {
      throw ArgumentError.value(itemId, 'itemId', 'unknown item');
    }
    if (item.archivedAt != null) {
      throw ArgumentError.value(itemId, 'itemId', 'is archived');
    }
  }
}

/// Signature-matched detection events (features only, never audio).
/// Append-only (trigger-guarded) and unique on (nodeId, seq).
class DriftSensorEventRepository implements SensorEventRepository {
  DriftSensorEventRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Stores the events that are new and returns how many were.
  ///
  /// Idempotent on (nodeId, seq): an event already stored, or repeated
  /// within [events], is skipped. So is an event whose seq is at or below
  /// the point a history wipe cleared for that node, so a node's
  /// store-and-forward buffer never brings deleted events back. Each new
  /// event keeps the node's placement at this moment.
  ///
  /// [ArgumentError], before anything is stored, for an unknown node; a
  /// negative seq, duration, impulse or harmonic count; a non-finite
  /// frequency or level; minHz above maxHz; a match with a blank signature
  /// id or pack version or a score outside 0..1.
  @override
  Future<int> record(List<SensorEvent> events) async {
    if (events.isEmpty) return 0;
    for (final event in events) {
      _check(event);
    }
    return _db.transaction(() async {
      final ids = {for (final e in events) e.nodeId};
      final nodes = {
        for (final row in await (_db.select(
          _db.sensorNodes,
        )..where((n) => n.id.isIn(ids))).get())
          row.id: row,
      };
      for (final id in ids) {
        if (!nodes.containsKey(id)) {
          throw ArgumentError.value(id, 'nodeId', 'unknown sensor node');
        }
      }
      final now = _clock().toUtc();
      var added = 0;
      for (final event in events) {
        final node = nodes[event.nodeId]!;
        final cleared = node.eventsClearedThroughSeq;
        if (cleared != null && event.seq <= cleared) continue;
        final match = event.match;
        final row = await _db
            .into(_db.sensorEvents)
            .insertReturningOrNull(
              SensorEventsCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                nodeId: event.nodeId,
                seq: event.seq,
                startedAt: event.startedAt.toUtc(),
                durationMs: event.durationMs,
                eventClass: event.eventClass,
                peakHz: event.peakHz,
                minHz: event.minHz,
                maxHz: event.maxHz,
                slopeHzPerMs: event.slopeHzPerMs,
                snrDb: event.snrDb,
                peakDbfs: event.peakDbfs,
                impulses: event.impulses,
                repRateHz: event.repRateHz,
                harmonics: event.harmonics,
                signatureId: Value(match?.signatureId.trim()),
                packVersion: Value(match?.packVersion.trim()),
                matchScore: Value(match?.score),
                matchExperimental: Value(match?.experimental),
                locationId: Value(node.locationId),
                itemId: Value(node.itemId),
              ),
              onConflict: DoNothing(
                target: [_db.sensorEvents.nodeId, _db.sensorEvents.seq],
              ),
            );
        if (row != null) added++;
      }
      return added;
    });
  }

  /// Newest first (startedAt, then seq), at most [limit] (must be
  /// positive).
  @override
  Stream<List<SensorEvent>> watchForNode(String nodeId, {int limit = 500}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }
    final query = _db.select(_db.sensorEvents)
      ..where((e) => e.nodeId.equals(nodeId))
      ..orderBy(_newestFirst)
      ..limit(limit);
    return query.watch().map(_toModels);
  }

  /// Events recorded in [locationId] or a location nested below it, or on
  /// an item currently stored there; newest first. [window] keeps events
  /// that started at or after `now - window` (clock read on each
  /// recompute; the stream does not tick on its own).
  @override
  Stream<List<SensorEvent>> watchForLocation(
    String locationId, {
    Duration? window,
  }) {
    return watchTables(
      _db,
      {_db.sensorEvents, _db.locations, _db.items},
      () async {
        final subtree = await locationSubtree(_db, locationId);
        final items = await (_db.select(
          _db.items,
        )..where((i) => i.locationId.isIn(subtree))).map((i) => i.id).get();
        final since = _since(window);
        final query = _db.select(_db.sensorEvents)
          ..where(
            (e) =>
                (e.locationId.isIn(subtree) | e.itemId.isIn(items)) &
                (since == null
                    ? const Constant(true)
                    : e.startedAt.isBiggerOrEqualValue(since)),
          )
          ..orderBy(_newestFirst);
        return _toModels(await query.get());
      },
    );
  }

  /// Events recorded while the node was on [itemId], newest first.
  /// [window] as in [watchForLocation].
  @override
  Stream<List<SensorEvent>> watchForItem(String itemId, {Duration? window}) {
    return watchTables(_db, {_db.sensorEvents}, () async {
      final since = _since(window);
      final query = _db.select(_db.sensorEvents)
        ..where(
          (e) =>
              e.itemId.equals(itemId) &
              (since == null
                  ? const Constant(true)
                  : e.startedAt.isBiggerOrEqualValue(since)),
        )
        ..orderBy(_newestFirst);
      return _toModels(await query.get());
    });
  }

  /// The highest seq stored for the node, or the point a history wipe
  /// cleared, whichever is higher; null when neither exists (or the node is
  /// unknown). sensor-link asks the node for events after it.
  @override
  Future<int?> lastSeq(String nodeId) async {
    final node = await (_db.select(
      _db.sensorNodes,
    )..where((n) => n.id.equals(nodeId))).getSingleOrNull();
    if (node == null) return null;
    final maxSeq = _db.sensorEvents.seq.max();
    final stored =
        await (_db.selectOnly(_db.sensorEvents)
              ..addColumns([maxSeq])
              ..where(_db.sensorEvents.nodeId.equals(nodeId)))
            .map((row) => row.read(maxSeq))
            .getSingle();
    final cleared = node.eventsClearedThroughSeq;
    if (stored == null) return cleared;
    if (cleared == null) return stored;
    return stored > cleared ? stored : cleared;
  }

  DateTime? _since(Duration? window) =>
      window == null ? null : _clock().toUtc().subtract(window);

  static List<OrderingTerm Function($SensorEventsTable)> get _newestFirst => [
    (e) => OrderingTerm.desc(e.startedAt),
    (e) => OrderingTerm.desc(e.seq),
    (e) => OrderingTerm.desc(e.id),
  ];

  static List<SensorEvent> _toModels(List<SensorEventRow> rows) =>
      List.unmodifiable([for (final row in rows) row.toModel()]);

  static void _check(SensorEvent e) {
    for (final (value, name) in [
      (e.seq, 'seq'),
      (e.durationMs, 'durationMs'),
      (e.impulses, 'impulses'),
      (e.harmonics, 'harmonics'),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must be zero or more');
      }
    }
    for (final (value, name) in [
      (e.peakHz, 'peakHz'),
      (e.minHz, 'minHz'),
      (e.maxHz, 'maxHz'),
      (e.slopeHzPerMs, 'slopeHzPerMs'),
      (e.snrDb, 'snrDb'),
      (e.peakDbfs, 'peakDbfs'),
      (e.repRateHz, 'repRateHz'),
    ]) {
      requireFinite(value, name);
    }
    if (e.minHz > e.maxHz) {
      throw ArgumentError.value(e.minHz, 'minHz', 'is above maxHz');
    }
    final match = e.match;
    if (match != null) {
      requireText(match.signatureId, 'match.signatureId');
      requireText(match.packVersion, 'match.packVersion');
      requireUnitInterval(match.score, 'match.score');
    }
  }
}
