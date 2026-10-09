import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../reports/report_data.dart' show utcStamp;
import '../support.dart';

/// Absolute path of the WAV the scan engine retained for a scan, or null.
/// Wired by the app to `ScanEngine.retainedAudioPath`.
typedef RetainedAudioPathResolver = Future<String?> Function(String scanId);

/// Columns of `samples.csv` in the dataset ZIP.
const datasetCsvColumns = <String>[
  'scan_id',
  'item_id',
  'label',
  'inspection_id',
  'grain_type',
  'sack_material',
  'environment',
  'notes',
  'wav_filename',
  'model_version',
  'sample_rate',
  'captured_at',
];

/// Name of the manifest entry in the ZIP.
const datasetManifestName = 'samples.csv';

/// Lists samples whose WAV could not be found. Present only when needed.
const datasetMissingName = 'missing.txt';

/// ZIP entry for a sample's WAV.
String datasetWavEntry(String scanId) => 'audio/$scanId.wav';

/// Builds a local ZIP of labeled research recordings. It never uploads
/// anything; the user shares the file through the share sheet.
class DriftDatasetExportService implements DatasetExportService {
  DriftDatasetExportService(
    this._db,
    this._outputDirectory,
    this._clock,
    this._retainedAudioPath,
  );

  final KernelDatabase _db;
  final Directory _outputDirectory;
  final Clock _clock;
  final RetainedAudioPathResolver? _retainedAudioPath;

  /// Writes `kernel-dataset-<utc>-<id>.zip` into the app-private dataset
  /// directory and returns its absolute path. Contents:
  /// - `samples.csv`: one row per labeled sample, oldest first, with
  ///   [datasetCsvColumns]. Labels are human labels; AI predictions are not
  ///   included. `wav_filename` is the entry path, or empty when missing.
  /// - `audio/<scanId>.wav`: each retained WAV, copied unchanged.
  /// - `missing.txt`: samples whose WAV was not found, if any. They are
  ///   listed, never silently dropped.
  @override
  Future<String> exportZip() async {
    final samples = _db.labeledSamples;
    final scans = _db.scans;
    final rows =
        await (_db.select(samples).join([
              innerJoin(scans, scans.id.equalsExp(samples.scanId)),
            ])..orderBy([
              OrderingTerm.asc(samples.createdAt),
              OrderingTerm.asc(samples.id),
            ]))
            .get();

    await _outputDirectory.create(recursive: true);
    final stamp = utcStamp(_clock())
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll('T', '-');
    final target = File(
      p.join(
        _outputDirectory.path,
        'kernel-dataset-$stamp-${newId().substring(0, 8)}.zip',
      ),
    );
    final partial = File('${target.path}.part');
    final encoder = ZipFileEncoder()..create(partial.path);
    var closed = false;
    try {
      final table = <List<Object?>>[datasetCsvColumns];
      final missing = <String>[];
      for (final joined in rows) {
        final sample = joined.readTable(samples);
        final scan = joined.readTable(scans);
        final (wav, problem) = await _findWav(sample.scanId);
        var wavName = '';
        if (wav != null) {
          wavName = datasetWavEntry(sample.scanId);
          await encoder.addFile(wav, wavName);
        } else {
          missing.add('${sample.scanId}\t$problem');
        }
        table.add([
          sample.scanId,
          sample.itemId,
          sample.label.name,
          sample.inspectionId ?? '',
          sample.grainType,
          sample.sackMaterial ?? '',
          sample.environment ?? '',
          sample.notes ?? '',
          wavName,
          scan.modelVersion,
          scan.sampleRate,
          scan.capturedAt.toUtc().toIso8601String(),
        ]);
      }
      encoder.addArchiveFile(
        ArchiveFile.string(datasetManifestName, Csv().encode(table)),
      );
      if (missing.isNotEmpty) {
        encoder.addArchiveFile(
          ArchiveFile.string(
            datasetMissingName,
            '# Retained audio not found. These samples are listed in '
            '$datasetManifestName with an empty wav_filename.\n'
            '# scan_id\treason\n'
            '${missing.join('\n')}\n',
          ),
        );
      }
      await encoder.close();
      closed = true;
      await partial.rename(target.path);
    } catch (_) {
      if (!closed) {
        try {
          await encoder.close();
        } on Object {
          // The partial file is deleted below either way.
        }
      }
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
    return target.absolute.path;
  }

  /// The retained WAV for [scanId], or the reason it is missing.
  Future<(File?, String)> _findWav(String scanId) async {
    final resolve = _retainedAudioPath;
    if (resolve == null) return (null, 'no audio source configured');
    final String? path;
    try {
      path = await resolve(scanId);
    } on Exception catch (error) {
      return (null, 'lookup failed (${error.runtimeType})');
    }
    if (path == null) return (null, 'no retained audio for this scan');
    final file = File(path);
    if (!await file.exists()) return (null, 'file not found');
    return (file, '');
  }
}
