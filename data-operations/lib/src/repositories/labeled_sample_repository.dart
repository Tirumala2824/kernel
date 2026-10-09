import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../support.dart';
import 'settings_repository.dart';

/// Research recordings for building training data. A label is a human
/// statement about a retained recording, kept apart from the scan's AI
/// prediction, and never shown as a pest result.
class DriftLabeledSampleRepository implements LabeledSampleRepository {
  DriftLabeledSampleRepository(this._db, this._clock);

  final KernelDatabase _db;
  final Clock _clock;

  /// Stores one label for a retained scan.
  ///
  /// - [StateError] when the research opt-in is off, or the scan already
  ///   has a label (one label per recording; samples are immutable).
  /// - [ArgumentError] when the scan is unknown or its audio was not
  ///   retained, the grain type is blank, or the inspection rule fails:
  ///   `clean` needs an inspection of the same item that found no pests,
  ///   `infested` one that found pests. A RETRY recording can only be
  ///   labelled `unknown`. An optional inspection on an `unknown` label must
  ///   belong to the same item.
  @override
  Future<LabeledSample> create(LabeledSampleDraft draft) async {
    final grainType = requireText(draft.grainType, 'grainType');
    return _db.transaction(() async {
      if (!await DriftSettingsRepository.researchModeEnabled(_db)) {
        throw StateError('Research recording mode is off');
      }
      final scan = await (_db.select(
        _db.scans,
      )..where((s) => s.id.equals(draft.scanId))).getSingleOrNull();
      if (scan == null) {
        throw ArgumentError.value(draft.scanId, 'scanId', 'unknown scan');
      }
      if (!scan.audioRetained) {
        throw ArgumentError.value(
          draft.scanId,
          'scanId',
          'scan has no retained audio',
        );
      }
      final existing = await (_db.select(
        _db.labeledSamples,
      )..where((l) => l.scanId.equals(draft.scanId))).getSingleOrNull();
      if (existing != null) {
        throw StateError('Scan ${draft.scanId} already has a label');
      }

      final inspectionId = draft.inspectionId;
      final required = switch (draft.label) {
        SampleLabel.clean => VerifiedFinding.noneFound,
        SampleLabel.infested => VerifiedFinding.pestsFound,
        SampleLabel.unknown => null,
      };
      if (required != null) {
        if (scan.quality == ScanQuality.retry) {
          // Guardrail: a RETRY recording never carries a pest class.
          throw ArgumentError.value(
            draft.label,
            'label',
            'a RETRY recording can only be labelled unknown',
          );
        }
        if (inspectionId == null) {
          throw ArgumentError.value(
            draft.label,
            'label',
            'needs an inspection confirming it',
          );
        }
      }
      if (inspectionId != null) {
        final inspection = await (_db.select(
          _db.inspections,
        )..where((i) => i.id.equals(inspectionId))).getSingleOrNull();
        if (inspection == null) {
          throw ArgumentError.value(
            inspectionId,
            'inspectionId',
            'unknown inspection',
          );
        }
        if (inspection.itemId != scan.itemId) {
          throw ArgumentError.value(
            inspectionId,
            'inspectionId',
            'inspects a different item',
          );
        }
        if (required != null && inspection.verifiedFinding != required) {
          throw ArgumentError.value(
            inspectionId,
            'inspectionId',
            'verified finding ${inspection.verifiedFinding.name} does not '
                'confirm label ${draft.label.name}',
          );
        }
      }

      final now = _clock().toUtc();
      final row = await _db
          .into(_db.labeledSamples)
          .insertReturning(
            LabeledSamplesCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              scanId: scan.id,
              itemId: scan.itemId,
              label: draft.label,
              inspectionId: Value(inspectionId),
              grainType: grainType,
              sackMaterial: Value(blankToNull(draft.sackMaterial)),
              environment: Value(blankToNull(draft.environment)),
              notes: Value(blankToNull(draft.notes)),
            ),
          );
      return row.toModel();
    });
  }

  /// Every stored sample (also for archived items, since they stay part of
  /// the dataset), oldest first.
  @override
  Stream<List<LabeledSample>> watchAll() {
    final query = _db.select(_db.labeledSamples)
      ..orderBy([
        (l) => OrderingTerm.asc(l.createdAt),
        (l) => OrderingTerm.asc(l.id),
      ]);
    return query.watch().map((rows) => [for (final row in rows) row.toModel()]);
  }
}
