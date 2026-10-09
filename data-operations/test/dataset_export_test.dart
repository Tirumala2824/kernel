import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:data_operations/src/services/dataset_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/harness.dart';

/// Reads a dataset ZIP: entry name -> bytes.
Map<String, List<int>> readZip(String path) {
  final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
  return {
    for (final file in archive.files)
      if (file.isFile) file.name: file.content,
  };
}

List<Map<String, String>> readManifest(List<int> bytes) {
  final rows = Csv(autoDetect: false).decode(utf8.decode(bytes));
  final header = [for (final cell in rows.first) '$cell'];
  expect(header, datasetCsvColumns);
  return [
    for (final row in rows.skip(1))
      {for (var i = 0; i < header.length; i++) header[i]: '${row[i]}'},
  ];
}

void main() {
  late Harness h;
  late Directory audioDir;
  final audio = <String, String>{};

  setUp(() async {
    audio.clear();
    audioDir = await Directory.systemTemp.createTemp('kernel_audio_');
    h = await Harness.create(retainedAudio: audio);
    await h.ops.settings.setResearchModeOptIn(true);
  });
  tearDown(() async {
    await h.dispose();
    if (audioDir.existsSync()) await audioDir.delete(recursive: true);
  });

  /// Test-only stand-in for a retained recording (bytes are arbitrary).
  Future<String> writeWav(String scanId, List<int> bytes) async {
    final file = File(p.join(audioDir.path, '$scanId.wav'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  test('the ZIP holds samples.csv, every retained WAV, and lists missing '
      'ones in missing.txt', () async {
    final item = await h.addItem(label: 'Sack R-001', grainType: 'Wheat');
    final withWav = await h.recordScan(
      item.id,
      minutesAgo: 10,
      audioRetained: true,
      modelVersion: 'none',
    );
    final lost = await h.recordScan(
      item.id,
      minutesAgo: 5,
      audioRetained: true,
    );
    final unresolved = await h.recordScan(
      item.id,
      minutesAgo: 1,
      audioRetained: true,
    );
    final wavBytes = List<int>.generate(64, (i) => i);
    audio[withWav.id] = await writeWav(withWav.id, wavBytes);
    // The engine reports a path whose file is gone.
    audio[lost.id] = p.join(audioDir.path, 'deleted.wav');
    // No entry for `unresolved`: the engine has no recording for it.

    final pests = await h.addInspection(
      item.id,
      VerifiedFinding.pestsFound,
      scanId: withWav.id,
    );
    final first = await h.ops.labeledSamples.create(
      LabeledSampleDraft(
        scanId: withWav.id,
        label: SampleLabel.infested,
        inspectionId: pests.id,
        grainType: 'Wheat',
        sackMaterial: 'jute',
        environment: 'warehouse, fans on',
        notes: '=not a formula',
      ),
    );
    h.clock.advance(const Duration(seconds: 1));
    await h.ops.labeledSamples.create(
      LabeledSampleDraft(
        scanId: lost.id,
        label: SampleLabel.unknown,
        grainType: 'Wheat',
      ),
    );
    h.clock.advance(const Duration(seconds: 1));
    await h.ops.labeledSamples.create(
      LabeledSampleDraft(
        scanId: unresolved.id,
        label: SampleLabel.unknown,
        grainType: 'Wheat',
      ),
    );

    final path = await h.ops.datasetExport.exportZip();
    expect(p.isAbsolute(path), isTrue);
    expect(p.isWithin(h.datasetDir.path, path), isTrue);
    expect(p.extension(path), '.zip');
    expect(File('$path.part').existsSync(), isFalse);

    final entries = readZip(path);
    expect(
      entries.keys,
      unorderedEquals([
        datasetManifestName,
        datasetMissingName,
        datasetWavEntry(withWav.id),
      ]),
    );
    expect(entries[datasetWavEntry(withWav.id)], wavBytes);

    final rows = readManifest(entries[datasetManifestName]!);
    expect(rows.map((r) => r['scan_id']), [withWav.id, lost.id, unresolved.id]);
    expect(rows[0], {
      'scan_id': withWav.id,
      'item_id': item.id,
      'label': 'infested',
      'inspection_id': first.inspectionId,
      'grain_type': 'Wheat',
      'sack_material': 'jute',
      'environment': 'warehouse, fans on',
      'notes': '=not a formula',
      'wav_filename': 'audio/${withWav.id}.wav',
      'model_version': 'none',
      'sample_rate': '16000',
      'captured_at': withWav.capturedAt.toUtc().toIso8601String(),
    });
    expect(rows[1]['wav_filename'], '');
    expect(rows[1]['label'], 'unknown');
    expect(rows[1]['inspection_id'], '');
    expect(rows[2]['wav_filename'], '');

    final missing = utf8.decode(entries[datasetMissingName]!);
    final listed = [
      for (final line in const LineSplitter().convert(missing))
        if (!line.startsWith('#')) line.split('\t').first,
    ];
    expect(listed, [lost.id, unresolved.id]);
    expect(missing, contains('file not found'));
    expect(missing, contains('no retained audio for this scan'));
    expect(missing, isNot(contains(audioDir.path)), reason: 'no paths');
  });

  test('without labeled samples the ZIP has only the CSV header', () async {
    final entries = readZip(await h.ops.datasetExport.exportZip());
    expect(entries.keys, [datasetManifestName]);
    expect(readManifest(entries[datasetManifestName]!), isEmpty);
  });

  test(
    'without an audio source every WAV is listed missing, none dropped',
    () async {
      final bare = await Harness.create();
      addTearDown(bare.dispose);
      await bare.ops.settings.setResearchModeOptIn(true);
      final item = await bare.addItem();
      final scan = await bare.recordScan(item.id, audioRetained: true);
      await bare.ops.labeledSamples.create(
        LabeledSampleDraft(
          scanId: scan.id,
          label: SampleLabel.unknown,
          grainType: 'Wheat',
        ),
      );
      final entries = readZip(await bare.ops.datasetExport.exportZip());
      expect(
        entries.keys,
        unorderedEquals([datasetManifestName, datasetMissingName]),
      );
      expect(
        readManifest(entries[datasetManifestName]!).single['scan_id'],
        scan.id,
      );
      expect(utf8.decode(entries[datasetMissingName]!), contains(scan.id));
    },
  );

  test('each export is a new file', () async {
    final a = await h.ops.datasetExport.exportZip();
    final b = await h.ops.datasetExport.exportZip();
    expect(a, isNot(b));
    expect(File(a).existsSync() && File(b).existsSync(), isTrue);
  });
}
