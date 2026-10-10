import 'dart:io';

import 'package:data_operations/src/reports/report_fonts.dart';
import 'package:data_operations/src/reports/report_pdf.dart';
import 'package:data_operations/src/reports/sightings_report.dart';
import 'package:data_operations/src/services/report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;

import 'support/csv.dart';
import 'support/harness.dart';

/// Records every string the PDF kit draws, in document order.
class _RecordingKit extends PdfKit {
  _RecordingKit(ReportFonts fonts) : super(fonts: fonts, compress: false);

  final drawn = <String>[];

  @override
  String t(String text) {
    drawn.add(text);
    return super.t(text);
  }
}

void main() {
  late Harness h;
  late Location house;
  late Location kitchen;
  late Location yard;
  late GrainItem tin;
  late Sighting roach;
  late Sighting scorpion;

  setUp(() async {
    h = await Harness.create();
    house = await h.addLocation('House', type: LocationType.home);
    kitchen = await h.addLocation(
      'Kitchen',
      type: LocationType.room,
      parentId: house.id,
    );
    yard = await h.addLocation('Yard', type: LocationType.home);
    tin = await h.addItem(
      role: Role.household,
      label: 'Rice tin',
      locationId: kitchen.id,
    );
    roach = await h.addSighting(
      minutesAgo: 120,
      locationId: kitchen.id,
      userCardId: 'american_cockroach',
      notes: '=cmd|calc',
      latitude: 12.971599,
      longitude: 77.594566,
      accuracyMeters: 9,
      distance: const DistanceEstimate(
        method: DistanceMethod.arcoreDepth,
        meters: 0.85,
        lowMeters: 0.7,
        highMeters: 1.0,
        confidence: 0.6,
      ),
    );
    scorpion = await h.addSighting(
      minutesAgo: 30,
      locationId: yard.id,
      cardId: 'indian_red_scorpion',
      safety: SafetyLevel.venomous,
      latitude: 12.9,
      longitude: 77.5,
      accuracyMeters: 60,
      distance: const DistanceEstimate(
        method: DistanceMethod.unavailable,
        unavailableReason: 'low_light',
      ),
    );
    await h.ops.sightings.setVerifiedFinding(
      scorpion.id,
      VerifiedFinding.pestsFound,
    );
    await h.addSighting(
      minutesAgo: 10,
      source: SignalSource.microphone,
      itemId: tin.id,
      withAnalysis: false,
      sound: const SoundAnalysis(
        preFilter: [
          ScoredLabel(label: 'Squeak', score: 0.52),
          ScoredLabel(label: 'Insect', score: 0.2),
        ],
        groupHint: PestGroup.rodent,
        modelVersion: 'yamnet-test',
      ),
    );
    await h.addSighting(role: Role.farmer, notes: 'farmer sighting');

    await h.addNode(locationId: kitchen.id, name: 'Kitchen node');
    final t0 = h.clock.now.subtract(const Duration(minutes: 50));
    await h.ops.sensorEvents.record([
      for (var i = 0; i < 3; i++)
        sensorEvent(
          seq: i + 1,
          startedAt: t0.add(Duration(minutes: i * 10)),
        ),
      sensorEvent(
        seq: 4,
        startedAt: t0.add(const Duration(minutes: 5)),
        signatureId: 'rat_22k',
      ),
      sensorEvent(seq: 5, startedAt: t0, signatureId: null),
    ]);
    await h.addNode(id: 'yard-node', address: 'AA:02', name: 'Yard node');
    await h.ops.sensorNodes.setPlacement(
      'yard-node',
      SensorPlacement(locationId: yard.id),
    );
    await h.ops.sensorEvents.record([
      sensorEvent(nodeId: 'yard-node', seq: 1, startedAt: t0),
    ]);
  });
  tearDown(() => h.dispose());

  ReportScope scope({String? locationId, List<String>? itemIds}) => ReportScope(
    role: Role.household,
    kind: ReportKind.sightings,
    locationId: locationId,
    itemIds: itemIds,
  );

  Future<ParsedCsv> csv(ReportScope s) async =>
      readCsv(await h.ops.reports.export(s, ReportFormat.csv));

  test('CSV keeps AI analysis, user validation and human findings in '
      'separate columns', () async {
    final path = await h.ops.reports.export(scope(), ReportFormat.csv);
    expect(p.basename(path), startsWith('kernel-sightings-household-'));
    final report = await readCsv(path);
    expect(report.header, sightingsCsvColumns);
    final ai = [
      for (final c in report.header)
        if (c.startsWith('ai_')) c,
    ];
    expect(
      ai,
      containsAll([
        'ai_label',
        'ai_card_id',
        'ai_estimated_confidence',
        'ai_agreement',
        'ai_model_version',
        'ai_experimental',
      ]),
    );
    expect(report.header, containsAll(['user_validated', 'user_card_id']));
    expect(report.header, contains('human_verified_finding'));
    expect(
      report.header.where(
        (c) => c.contains('verified') && !c.startsWith('human_'),
      ),
      isEmpty,
    );

    final sightings = report.ofType('sighting');
    expect(sightings, hasLength(3), reason: 'household only');
    final r = sightings.firstWhere((row) => row['sighting_id'] == roach.id);
    expect(r['ai_label'], 'German cockroach');
    expect(r['ai_card_id'], 'german_cockroach');
    expect(r['ai_estimated_confidence'], '0.70');
    expect(r['ai_agreement'], '0.60');
    expect(r['ai_samples'], '5');
    expect(r['ai_model_version'], 'gemma-test-e2b');
    expect(r['ai_experimental'], 'yes');
    expect(r['user_validated'], 'yes');
    expect(r['user_card_id'], 'american_cockroach');
    expect(r['human_verified_finding'], 'Not verified');
    expect(r['location'], 'House / Kitchen');
    expect(r['latitude'], '12.97160');
    expect(r['longitude'], '77.59457');
    expect(r['distance_m'], '0.85');
    expect(r['notes'], "'=cmd|calc", reason: 'formula guarded');
    expect(r['media_kept'], 'no');

    final s = sightings.firstWhere((row) => row['sighting_id'] == scorpion.id);
    expect(s['human_verified_finding'], 'Pests found');
    expect(s['ai_card_id'], 'indian_red_scorpion');
    expect(s['ai_safety'], 'venomous');
    expect(s['latitude'], '', reason: 'GPS coarser than 25 m is not listed');
    expect(s['gps_accuracy_m'], '60.0');
    expect(s['distance_method'], 'unavailable');
    expect(s['distance_m'], 'Distance not available');
    expect(s['distance_unavailable_reason'], 'low_light');

    final sound = sightings.firstWhere((row) => row['source'] == 'microphone');
    expect(sound['ai_label'], '');
    expect(sound['ai_sound_labels'], 'Squeak (0.52); Insect (0.20)');
    expect(sound['ai_sound_model_version'], 'yamnet-test');
    expect(sound['ai_experimental'], 'yes');
    expect(sound['item_label'], 'Rice tin');
    // Sighting rows leave every sensor column empty.
    for (final row in sightings) {
      for (final c in report.header.where((c) => c.startsWith('sensor_'))) {
        expect(row[c], '', reason: c);
      }
    }
  });

  test('CSV counts sensor events by signature per node with the '
      'disclaimer', () async {
    final report = await csv(scope());
    expect(
      report.preambleValues('Disclaimer'),
      contains(
        'AI and sensor results are experimental signals, not '
        'diagnoses.',
      ),
    );
    expect(report.preambleValue('Sensor events'), '6');
    final sensor = report.ofType('sensor');
    expect(
      [
        for (final r in sensor)
          '${r['sensor_node_name']}|${r['sensor_signature_id']}|'
              '${r['sensor_events']}',
      ],
      [
        'Kitchen node|mouse_usv|3',
        'Kitchen node|rat_22k|1',
        'Kitchen node|No signature match|1',
        'Yard node|mouse_usv|1',
      ],
    );
    final mouse = sensor.first;
    expect(mouse['sensor_pack_version'], 'sig-pack-test-0.1');
    expect(mouse['sensor_window_minutes'], '21');
    expect(mouse['sensor_placement'], 'House / Kitchen');
    expect(mouse['sensor_experimental'], 'yes');
    expect(mouse['sighting_id'], '');
    expect(mouse['ai_label'], '');
    expect(mouse['human_verified_finding'], '');
  });

  test('scope by location covers nested places and items there; scope by '
      'items covers only those items', () async {
    final inHouse = await csv(scope(locationId: house.id));
    expect(inHouse.ofType('sighting'), hasLength(2));
    expect(
      {for (final r in inHouse.ofType('sensor')) r['sensor_node_name']},
      {'Kitchen node'},
    );
    final onTin = await csv(scope(itemIds: [tin.id]));
    expect(onTin.ofType('sighting').single['source'], 'microphone');
    expect(onTin.ofType('sensor'), isEmpty);

    await h.ops.locations.archive(yard.id);
    final all = await csv(scope());
    expect(all.ofType('sighting'), hasLength(2));
    expect(
      {for (final r in all.ofType('sensor')) r['sensor_node_name']},
      {'Kitchen node'},
    );
  });

  test('PDF has separate AI, validation and sensor sections and the '
      'disclaimer', () async {
    final path = await h.ops.reports.export(scope(), ReportFormat.pdf);
    expect(File(path).readAsBytesSync().take(4), '%PDF'.codeUnits);

    final kit = _RecordingKit(await ReportFonts.load(diskReportFont));
    final service = h.ops.reports as DriftReportService;
    await renderSightingsPdf(await service.loadSightings(scope()), kit);
    final drawn = kit.drawn;
    int at(String text) => drawn.indexOf(text);
    expect(drawn, contains(sightingsDisclaimer.first));
    expect(
      at('AI analysis (experimental; AI-estimated — not calibrated)'),
      lessThan(at('User validation and human-verified findings')),
    );
    expect(
      at('AI sound analysis (experimental)'),
      greaterThan(
        at(
          'AI analysis (experimental; AI-estimated — not '
          'calibrated)',
        ),
      ),
    );
    expect(
      at('Sensor events by signature and node (experimental)'),
      greaterThan(at('User validation and human-verified findings')),
    );
    expect(drawn, contains('AI-estimated confidence'));
    expect(drawn, contains('Human-verified finding'));
    expect(drawn, contains('3 events in 21 minutes'));
    expect(drawn, contains('Pests found'));
    expect(drawn, contains('Distance not available — low_light'));
  });

  test('an empty scope still renders with the disclaimer', () async {
    final empty = await Harness.create();
    addTearDown(empty.dispose);
    final parsed = await readCsv(
      await empty.ops.reports.export(scope(), ReportFormat.csv),
    );
    expect(parsed.rows, isEmpty);
    expect(parsed.preambleValues('Disclaimer'), sightingsDisclaimer);
    final pdf = await empty.ops.reports.export(scope(), ReportFormat.pdf);
    expect(File(pdf).existsSync(), isTrue);
  });
}
