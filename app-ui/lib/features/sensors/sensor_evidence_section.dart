import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'sensor_providers.dart';
import 'sensor_widgets.dart';

/// "Sensor evidence" on a sack or container: events from nodes placed on
/// it, shown alongside (never inside) its acoustic scans and inspections,
/// and never changing them (guardrails §10). Hidden only when loaded data
/// confirms no placed nodes, events or not-evaluated history for the item.
class SensorEvidenceSection extends ConsumerWidget {
  const SensorEvidenceSection({super.key, required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nodesValue = ref.watch(sensorNodesProvider);
    final eventsValue = ref.watch(sensorEventsForItemProvider(item.id));
    final historyValue = ref.watch(sensorNotEvaluatedForItemProvider(item.id));
    final error = nodesValue.error ?? eventsValue.error ?? historyValue.error;
    if (nodesValue.hasError || eventsValue.hasError || historyValue.hasError) {
      return ErrorNote(
        l.errorWithDetail(l.sensorEvidenceTitle, '$error'),
        key: const Key('sensor-evidence-error'),
      );
    }
    if (nodesValue.isLoading ||
        !nodesValue.hasValue ||
        eventsValue.isLoading ||
        !eventsValue.hasValue ||
        historyValue.isLoading ||
        !historyValue.hasValue) {
      return Text(l.loading, key: const Key('sensor-evidence-loading'));
    }
    final nodes = [
      for (final n in nodesValue.requireValue)
        if (n.itemId == item.id) n,
    ];
    final events = eventsValue.requireValue;
    final history = historyValue.requireValue;
    if (nodes.isEmpty && events.isEmpty && history.isEmpty) {
      return const SizedBox.shrink();
    }
    final currentUnavailable = nodes.any((node) {
      final status = ref.watch(sensorStatusProvider(node.id));
      return status.isLoading ||
          status.hasError ||
          !status.hasValue ||
          status.requireValue.notEvaluated;
    });
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('sensor-evidence'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.sensorEvidenceTitle),
        const SizedBox(height: KernelSpace.sm),
        // Own outlined box and icon so it never reads as part of the scan
        // history or the inspection record.
        Container(
          padding: const EdgeInsets.all(KernelSpace.md),
          decoration: BoxDecoration(
            color: KernelColors.ivory,
            borderRadius: BorderRadius.circular(KernelRadii.lg),
            border: Border.all(color: KernelColors.outline, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sensors_rounded, color: KernelColors.forest),
                  const SizedBox(width: KernelSpace.sm),
                  Expanded(
                    child: Text(
                      l.sensorEvidenceBody,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KernelSpace.sm),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExperimentalBadge(),
              ),
              for (final node in nodes) ...[
                const SizedBox(height: KernelSpace.md),
                Text(node.name, style: textTheme.titleSmall),
                const SizedBox(height: KernelSpace.xs),
                SensorStatusChips(node: node),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: Key('sensor-evidence-open-${node.id}'),
                    onPressed: () => context.push(Routes.sensor(node.id)),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l.sensorEvidenceOpen),
                  ),
                ),
              ],
              const SizedBox(height: KernelSpace.sm),
              if (history.isNotEmpty)
                SensorNotEvaluatedHistory(
                  key: const Key('sensor-evidence-not-evaluated'),
                  periods: history,
                )
              else if (currentUnavailable)
                Text(l.sensorSignalNotDiagnosis)
              else if (events.isEmpty)
                Text(
                  l.sensorEvidenceEmpty(sensorEvidenceWindow.inDays),
                  key: const Key('sensor-evidence-empty'),
                  style: textTheme.bodyMedium,
                )
              else ...[
                Text(
                  l.sensorEvidenceWindow(sensorEvidenceWindow.inDays),
                  style: textTheme.bodySmall?.copyWith(
                    color: KernelColors.inkMuted,
                  ),
                ),
                const SizedBox(height: KernelSpace.xs),
                SensorEventSummary(events: events),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
