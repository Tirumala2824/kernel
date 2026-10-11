import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

/// Buyer "sample scans": scan sacks of the lot one at a time. Results are
/// unverified model output and never change the lot's status.
class SampleScansSection extends ConsumerWidget {
  const SampleScansSection({super.key, required this.lot, required this.sacks});

  final Lot lot;
  final List<GrainItem> sacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.sampleScansTitle),
        const SizedBox(height: 4),
        Text(l.sampleScansBody),
        const SizedBox(height: 8),
        if (sacks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.icon(
              key: const Key('start-sample-scans'),
              onPressed: () => context.push(Routes.batchRun(lotId: lot.id)),
              icon: const Icon(Icons.playlist_play_rounded),
              label: Text(l.sampleScansStart),
            ),
          ),
        for (final sack in sacks) _SampleScanTile(item: sack),
      ],
    );
  }
}

class _SampleScanTile extends ConsumerWidget {
  const _SampleScanTile({required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scans = ref.watch(scansForItemProvider(item.id));
    return ItemTile(
      key: Key('sample-${item.id}'),
      item: item,
      onTap: () => context.push(Routes.item(item.id)),
      trailing: IconButton(
        tooltip: l.scanThisItem('sack'),
        icon: const Icon(Icons.graphic_eq_rounded),
        onPressed: () => context.push(Routes.scanItem(item.id)),
      ),
      footer: CurrentDataView<List<ScanRecord>>(
        value: scans,
        data: (records) {
          final latest = records.firstOrNull;
          return latest == null
              ? Text(l.notScannedYet)
              : ScanResultChip(quality: latest.quality, result: latest.result);
        },
      ),
    );
  }
}

/// Buyer physical checks: one human inspection per sack, kept separate
/// from any acoustic result.
class PhysicalChecksSection extends ConsumerWidget {
  const PhysicalChecksSection({super.key, required this.sacks});

  final List<GrainItem> sacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.physicalChecksTitle),
        const SizedBox(height: 4),
        Text(l.physicalChecksBody),
        const SizedBox(height: 8),
        for (final sack in sacks) _PhysicalCheckTile(item: sack),
      ],
    );
  }
}

class _PhysicalCheckTile extends ConsumerWidget {
  const _PhysicalCheckTile({required this.item});

  final GrainItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inspections = ref.watch(inspectionsForItemProvider(item.id));
    return ItemTile(
      key: Key('check-${item.id}'),
      item: item,
      onTap: () => context.push(Routes.item(item.id)),
      trailing: IconButton(
        key: Key('record-check-${item.id}'),
        tooltip: l.recordPhysicalCheck,
        icon: const Icon(Icons.person_search_rounded),
        onPressed: () => context.push(Routes.inspect(item.id)),
      ),
      footer: CurrentDataView<List<Inspection>>(
        value: inspections,
        data: (records) {
          final latest = records.firstOrNull;
          return latest == null
              ? StatusChip(
                  label: l.noPhysicalCheckYet,
                  tone: StatusTone.attention,
                  icon: Icons.pending_actions_rounded,
                )
              : StatusChip(
                  label: l.verifiedFindingLine(latest.verifiedFinding.label(l)),
                  tone: StatusTone.info,
                  icon: Icons.person_search_rounded,
                );
        },
      ),
    );
  }
}
