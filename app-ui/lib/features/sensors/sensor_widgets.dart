import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'sensor_copy.dart';
import 'sensor_providers.dart';

/// Link state, battery and health chips for one node, with the
/// "not evaluated" notice when it is jammed, clipped or needs a survey.
class SensorStatusChips extends ConsumerWidget {
  const SensorStatusChips({
    super.key,
    required this.node,
    this.showNotice = true,
  });

  final SensorNode node;
  final bool showNotice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(sensorStatusProvider(node.id)).value;
    final battery = status?.batteryPercent ?? node.batteryPercent;
    final health = [...?status?.health]
      ..sort((a, b) => a.index.compareTo(b.index));
    final notEvaluated = status != null && isNotEvaluated(status.health);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: KernelSpace.sm,
          runSpacing: KernelSpace.xs,
          children: [
            if (status == null)
              StatusChip(
                key: Key('sensor-status-unknown-${node.id}'),
                label: l.sensorStatusUnknown,
                icon: Icons.bluetooth_rounded,
              )
            else
              StatusChip(
                key: Key('sensor-link-${node.id}'),
                label: status.linkState.label(l),
                tone: status.linkState.tone,
                icon: status.linkState.icon,
              ),
            StatusChip(
              key: Key('sensor-battery-${node.id}'),
              label: battery == null
                  ? l.sensorBatteryUnknown
                  : l.sensorBattery(battery),
              tone: battery != null && battery <= 15
                  ? StatusTone.attention
                  : StatusTone.neutral,
              icon: Icons.battery_std_rounded,
            ),
            for (final h in health)
              // "Sensor working" is implied by the link chip; only problems
              // get their own chip when anything else is reported.
              if (h != SensorHealth.ok || health.length == 1)
                StatusChip(
                  key: Key('sensor-health-${h.name}-${node.id}'),
                  label: h.label(l),
                  tone: h.tone,
                  icon: h.icon,
                ),
          ],
        ),
        if (showNotice && notEvaluated) ...[
          const SizedBox(height: KernelSpace.sm),
          NoticeBanner(
            key: Key('sensor-not-evaluated-${node.id}'),
            title: l.sensorNotEvaluatedTitle,
            text: l.sensorNotEvaluatedBody,
            icon: Icons.do_not_disturb_on_outlined,
          ),
        ],
      ],
    );
  }
}

/// Live band view: one bar per band with its range and level in words.
class SensorBandBars extends StatelessWidget {
  const SensorBandBars({super.key, required this.frame});

  final BandFrame frame;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bands = frame.bandsDbAboveFloor;
    final edges = frame.bandEdgesHz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledBarChart(
          key: const Key('sensor-bands'),
          bars: [
            for (var i = 0; i < bands.length && i + 1 < edges.length; i++)
              BarDatum(
                id: 'band-$i',
                label: l.sensorBandRange(khz(edges[i]), khz(edges[i + 1])),
                value: bands[i].round().clamp(0, 1000),
                valueLabel: l.sensorBandLevel(bands[i].toStringAsFixed(0)),
              ),
          ],
        ),
        Text(
          l.sensorLivePeak(khz(frame.peakHz)),
          key: const Key('sensor-peak'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// "N events in M minutes" per signature, each marked experimental.
class SensorEventSummary extends StatelessWidget {
  const SensorEventSummary({super.key, required this.events});

  final List<SensorEvent> events;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in summarizeEvents(events))
          Padding(
            key: Key('sensor-summary-${s.signatureId ?? 'unmatched'}'),
            padding: const EdgeInsets.only(bottom: KernelSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signatureName(l, s.signatureId),
                  style: textTheme.titleSmall,
                ),
                Text(
                  l.sensorEventsSummary(s.count, s.minutes),
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: KernelSpace.xxs),
                Wrap(
                  spacing: KernelSpace.sm,
                  runSpacing: KernelSpace.xs,
                  children: [
                    const ExperimentalBadge(),
                    if (s.packVersion != null)
                      StatusChip(
                        label: l.sensorPack(s.packVersion!),
                        icon: Icons.inventory_2_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        Text(
          l.sensorSignalNotDiagnosis,
          style: textTheme.bodyMedium?.copyWith(color: KernelColors.inkMuted),
        ),
      ],
    );
  }
}

/// Newest-first event list.
class SensorEventTimeline extends StatelessWidget {
  const SensorEventTimeline({super.key, required this.events, this.limit = 50});

  final List<SensorEvent> events;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in events.take(limit))
          Container(
            key: Key('sensor-event-${e.nodeId}-${e.seq}'),
            margin: const EdgeInsets.only(bottom: KernelSpace.sm),
            padding: const EdgeInsets.all(KernelSpace.md),
            decoration: BoxDecoration(
              color: KernelColors.paper,
              borderRadius: BorderRadius.circular(KernelRadii.md),
              border: Border.all(color: KernelColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signatureName(l, e.match?.signatureId),
                  style: textTheme.titleSmall,
                ),
                Text(
                  l.sensorEventLine(
                    formatDateTime(context, e.startedAt),
                    e.eventClass.label(l),
                    khz(e.peakHz),
                    e.durationMs,
                  ),
                  style: textTheme.bodyMedium,
                ),
                if (e.match != null)
                  Text(
                    l.sensorScore(e.match!.score.toStringAsFixed(2)),
                    style: textTheme.bodySmall?.copyWith(
                      color: KernelColors.inkMuted,
                    ),
                  ),
                const SizedBox(height: KernelSpace.xxs),
                const ExperimentalBadge(),
              ],
            ),
          ),
      ],
    );
  }
}
