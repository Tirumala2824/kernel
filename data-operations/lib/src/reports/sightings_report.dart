import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_csv.dart' show narrativeRows, userText;
import 'report_data.dart';
import 'report_pdf.dart' show PdfKit;

/// Everything the Pest ID sightings report shows ([ReportKind.sightings]),
/// loaded from stored records only.
class SightingsReportData {
  const SightingsReportData({
    required this.scope,
    required this.generatedAt,
    required this.locationLabel,
    required this.lotLabel,
    required this.harvestLabel,
    required this.sightings,
    required this.sensor,
  });

  final ReportScope scope;

  /// UTC.
  final DateTime generatedAt;
  final String? locationLabel;
  final String? lotLabel;
  final String? harvestLabel;

  /// Oldest first.
  final List<ReportSighting> sightings;

  /// Per node, then per signature (unmatched events last).
  final List<SensorEventCount> sensor;

  int get sensorEventCount => sensor.fold(0, (sum, row) => sum + row.events);
  int get sensorNodeCount => {for (final row in sensor) row.node.id}.length;
}

class ReportSighting {
  const ReportSighting({
    required this.sighting,
    required this.locationPath,
    required this.itemLabel,
  });

  final Sighting sighting;
  final String? locationPath;
  final String? itemLabel;

  /// Item label, else the location path, else empty.
  String get where => itemLabel ?? locationPath ?? '';
}

/// Signature-matched (or unmatched) events of one node in scope.
class SensorEventCount {
  const SensorEventCount({
    required this.node,
    required this.placements,
    required this.signatureId,
    required this.packVersion,
    required this.events,
    required this.firstStartedAt,
    required this.lastEndedAt,
    required this.experimental,
  });

  final SensorNode node;

  /// Where the node was when these events were recorded ("; "-joined).
  final String placements;

  /// Null for events that matched no signature.
  final String? signatureId;
  final String? packVersion;
  final int events;
  final DateTime firstStartedAt;
  final DateTime lastEndedAt;

  /// True unless every match said otherwise; unmatched rows are true too.
  final bool experimental;

  /// Whole minutes from the first start to the last end, at least 1.
  int get windowMinutes {
    final ms = lastEndedAt.difference(firstStartedAt).inMilliseconds;
    final minutes = (ms / Duration.millisecondsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// "N events in M minutes" (guardrails §10).
  String get summary =>
      '$events ${events == 1 ? 'event' : 'events'} in $windowMinutes '
      '${windowMinutes == 1 ? 'minute' : 'minutes'}';
}

/// Disclaimer on every sightings report (guardrails §4, §9, §10).
const sightingsDisclaimer = <String>[
  'AI and sensor results are experimental signals, not diagnoses.',
  'AI labels, AI-estimated confidence and agreement come from on-device '
      'models and are not calibrated. "Not a pest", "no match" or no sensor '
      'events never prove that nothing is there. No result is a guarantee; '
      'physical inspection is required for decisions.',
  "The AI analysis, the user's validation and the human-verified finding "
      'are separate records, listed in separate columns.',
  'Sensor results are counts of events matched against an experimental '
      'signature pack, per node ("N events in M minutes"). A jammed or '
      'clipped node is not evaluated.',
  'GPS coordinates are listed only when their accuracy is 25 m or better. '
      'This report was built only from records stored on this device.',
];

/// GPS fixes coarser than this are not printed (guardrails §9).
const maxListedGpsAccuracyMeters = 25.0;

const distanceNotAvailable = 'Distance not available';
const notVerified = 'Not verified';
const noSignatureMatch = 'No signature match';

/// Column header of the sightings table. `sighting` rows fill the sighting
/// columns; `sensor` rows fill the `sensor_*` columns. AI analysis columns
/// (`ai_*`), the user's validation (`user_*`) and the human verified
/// finding (`human_*`) are separate.
const sightingsCsvColumns = <String>[
  'row_type',
  'sighting_id',
  'observed_at_utc',
  'role',
  'source',
  'location',
  'item_label',
  'latitude',
  'longitude',
  'gps_accuracy_m',
  'distance_method',
  'distance_m',
  'distance_low_m',
  'distance_high_m',
  'distance_unavailable_reason',
  'ai_label',
  'ai_card_id',
  'ai_group',
  'ai_taxonomy',
  'ai_estimated_confidence',
  'ai_agreement',
  'ai_samples',
  'ai_safety',
  'ai_model_version',
  'ai_prompt_version',
  'ai_experimental',
  'ai_sound_labels',
  'ai_sound_group_hint',
  'ai_sound_model_version',
  'ai_sound_description',
  'user_validated',
  'user_card_id',
  'human_verified_finding',
  'notes',
  'media_kept',
  'sensor_node_id',
  'sensor_node_name',
  'sensor_type',
  'sensor_placement',
  'sensor_signature_id',
  'sensor_pack_version',
  'sensor_events',
  'sensor_window_minutes',
  'sensor_first_event_utc',
  'sensor_last_event_utc',
  'sensor_experimental',
];

const _sightingCellCount = 34;
const _sensorCellCount = 11;

/// UTF-8 (with BOM) CSV: preamble (title, scope, counts, disclaimer), a
/// blank line, then [sightingsCsvColumns].
List<int> renderSightingsCsv(SightingsReportData data) {
  final rows = <List<Object?>>[
    ['Kernel Pest ID sightings report'],
    ['Generated (UTC)', utcStamp(data.generatedAt)],
    ['Role', roleLabel(data.scope.role)],
    ['Location', userText(data.locationLabel ?? 'All')],
    ['Lot', userText(data.lotLabel ?? 'All')],
    ['Harvest', userText(data.harvestLabel ?? 'All')],
    ['Sightings', data.sightings.length],
    ['Sensor nodes with events', data.sensorNodeCount],
    ['Sensor events', data.sensorEventCount],
    for (final line in sightingsDisclaimer) ['Disclaimer', line],
    ...narrativeRows(data.scope),
    [],
    sightingsCsvColumns,
  ];
  for (final entry in data.sightings) {
    rows.add([
      'sighting',
      ..._sightingCells(entry),
      ...List.filled(_sensorCellCount, ''),
    ]);
  }
  for (final count in data.sensor) {
    rows.add([
      'sensor',
      ...List.filled(_sightingCellCount, ''),
      count.node.id,
      userText(count.node.name),
      count.node.type.name,
      userText(count.placements),
      count.signatureId ?? noSignatureMatch,
      count.packVersion ?? '',
      count.events,
      count.windowMinutes,
      utcStamp(count.firstStartedAt),
      utcStamp(count.lastEndedAt),
      yesNo(count.experimental),
    ]);
  }
  return utf8.encode(Csv(addBom: true).encode(rows));
}

List<Object?> _sightingCells(ReportSighting entry) {
  final s = entry.sighting;
  final gps = listedGps(s);
  final distance = s.distance;
  final a = s.analysis;
  final sound = s.sound;
  return [
    s.id,
    utcStamp(s.observedAt),
    roleLabel(s.role),
    s.source.name,
    userText(entry.locationPath ?? ''),
    userText(entry.itemLabel ?? ''),
    gps?.$1 ?? '',
    gps?.$2 ?? '',
    s.accuracyMeters == null ? '' : s.accuracyMeters!.toStringAsFixed(1),
    distance?.method.name ?? '',
    distance == null ? '' : distanceLabel(distance),
    _meters(distance?.isAvailable == true ? distance!.lowMeters : null),
    _meters(distance?.isAvailable == true ? distance!.highMeters : null),
    userText(distance?.unavailableReason ?? ''),
    userText(a?.commonName ?? ''),
    a?.cardId ?? '',
    a?.group.name ?? '',
    userText(a?.taxonomyPath.join(' > ') ?? ''),
    a == null ? '' : a.aiConfidence.toStringAsFixed(2),
    a == null ? '' : a.agreement.toStringAsFixed(2),
    a?.samples ?? '',
    a?.safety.name ?? '',
    userText(a?.modelVersion ?? ''),
    userText(a?.promptVersion ?? ''),
    a == null ? (sound == null ? '' : yesNo(true)) : yesNo(a.experimental),
    userText(sound == null ? '' : soundLabels(sound)),
    sound?.groupHint.name ?? '',
    userText(sound?.modelVersion ?? ''),
    userText(sound?.description ?? ''),
    yesNo(s.userValidated),
    s.userCardId ?? '',
    sightingFindingLabel(s.verifiedFinding),
    userText(s.notes ?? ''),
    yesNo(s.mediaPath != null),
  ];
}

String _meters(double? value) => value == null ? '' : value.toStringAsFixed(2);

/// (latitude, longitude) with 5 decimals when the fix is accurate enough
/// to list, else null.
(String, String)? listedGps(Sighting s) {
  final lat = s.latitude;
  final lng = s.longitude;
  final accuracy = s.accuracyMeters;
  if (lat == null || lng == null || accuracy == null) return null;
  if (accuracy > maxListedGpsAccuracyMeters) return null;
  return (lat.toStringAsFixed(5), lng.toStringAsFixed(5));
}

/// Meters when the method's gates passed, else "Distance not available".
String distanceLabel(DistanceEstimate d) =>
    d.isAvailable ? d.meters!.toStringAsFixed(2) : distanceNotAvailable;

String soundLabels(SoundAnalysis sound) => [
  for (final label in sound.preFilter)
    '${label.label} (${label.score.toStringAsFixed(2)})',
].join('; ');

String sightingFindingLabel(VerifiedFinding? finding) =>
    finding == null ? notVerified : verifiedFindingLabel(finding);

/// Sightings report PDF: sightings, AI analysis, AI sound analysis, user
/// validation with human-verified findings, and sensor event counts are
/// separate tables; the disclaimer is shown up front and in every footer.
Future<Uint8List> renderSightingsPdf(
  SightingsReportData data, [
  PdfKit kit = const PdfKit(),
]) {
  final doc = kit.document('Kernel Pest ID sightings report');
  final withSound = [
    for (final entry in data.sightings)
      if (entry.sighting.sound != null) entry,
  ];
  doc.addPage(
    kit.reportPages(
      footerNote: sightingsDisclaimer.first,
      build: (context) => [
        kit.title('Kernel Pest ID sightings report'),
        pw.SizedBox(height: 6),
        kit.text(
          'Generated ${utcStamp(data.generatedAt)} (UTC) · '
          'Role: ${roleLabel(data.scope.role)} · '
          'Location: ${data.locationLabel ?? 'All'} · '
          'Lot: ${data.lotLabel ?? 'All'} · '
          'Harvest: ${data.harvestLabel ?? 'All'}',
        ),
        kit.text(
          'Sightings: ${data.sightings.length} · '
          'Sensor nodes with events: ${data.sensorNodeCount} · '
          'Sensor events: ${data.sensorEventCount}',
        ),
        pw.SizedBox(height: 8),
        kit.notice('Disclaimer', sightingsDisclaimer),
        ...kit.narrative(data.scope),
        kit.heading('Sightings'),
        if (data.sightings.isEmpty)
          kit.empty('No sightings in this scope.')
        else
          kit.table(
            const ['Observed (UTC)', 'Where', 'Source', 'Distance', 'GPS'],
            [
              for (final entry in data.sightings)
                [
                  utcStamp(entry.sighting.observedAt),
                  entry.where,
                  entry.sighting.source.name,
                  switch (entry.sighting.distance) {
                    null => '',
                    final d => [
                      distanceLabel(d),
                      if (d.unavailableReason != null) d.unavailableReason!,
                    ].join(' — '),
                  },
                  switch (listedGps(entry.sighting)) {
                    null => '',
                    (final lat, final lng) =>
                      '$lat, $lng '
                          '(±${entry.sighting.accuracyMeters!.toStringAsFixed(0)} m)',
                  },
                ],
            ],
          ),
        kit.heading(
          'AI analysis (experimental; AI-estimated — not calibrated)',
        ),
        if (data.sightings.every((e) => e.sighting.analysis == null))
          kit.empty('No AI analyses in this scope.')
        else
          kit.table(
            const [
              'Observed (UTC)',
              'AI label',
              'AI card',
              'AI-estimated confidence',
              'Agreement (runs)',
              'Safety',
              'Model version',
              'Experimental',
            ],
            [
              for (final entry in data.sightings)
                if (entry.sighting.analysis case final a?)
                  [
                    utcStamp(entry.sighting.observedAt),
                    a.commonName,
                    a.cardId ?? 'No match',
                    a.aiConfidence.toStringAsFixed(2),
                    '${a.agreement.toStringAsFixed(2)} (${a.samples})',
                    a.safety.name,
                    a.modelVersion,
                    yesNo(a.experimental),
                  ],
            ],
          ),
        if (withSound.isNotEmpty) ...[
          kit.heading('AI sound analysis (experimental)'),
          kit.table(
            const [
              'Observed (UTC)',
              'Sound labels (raw scores)',
              'Group hint',
              'Model version',
              'Description (AI)',
            ],
            [
              for (final entry in withSound)
                [
                  utcStamp(entry.sighting.observedAt),
                  soundLabels(entry.sighting.sound!),
                  entry.sighting.sound!.groupHint.name,
                  entry.sighting.sound!.modelVersion,
                  entry.sighting.sound!.description ?? '',
                ],
            ],
          ),
        ],
        kit.heading('User validation and human-verified findings'),
        if (data.sightings.isEmpty)
          kit.empty('No sightings in this scope.')
        else
          kit.table(
            const [
              'Observed (UTC)',
              'User validated',
              'User-picked card',
              'Human-verified finding',
              'Notes',
            ],
            [
              for (final entry in data.sightings)
                [
                  utcStamp(entry.sighting.observedAt),
                  yesNo(entry.sighting.userValidated),
                  entry.sighting.userCardId ?? '',
                  sightingFindingLabel(entry.sighting.verifiedFinding),
                  entry.sighting.notes ?? '',
                ],
            ],
          ),
        kit.heading('Sensor events by signature and node (experimental)'),
        if (data.sensor.isEmpty)
          kit.empty('No sensor events in this scope.')
        else
          kit.table(
            const [
              'Node',
              'Type',
              'Placement when recorded',
              'Signature',
              'Pack version',
              'Events',
              'First (UTC)',
              'Last (UTC)',
            ],
            [
              for (final count in data.sensor)
                [
                  count.node.name,
                  count.node.type.name,
                  count.placements,
                  count.signatureId ?? noSignatureMatch,
                  count.packVersion ?? '',
                  count.summary,
                  utcStamp(count.firstStartedAt),
                  utcStamp(count.lastEndedAt),
                ],
            ],
          ),
      ],
    ),
  );
  return doc.save();
}
