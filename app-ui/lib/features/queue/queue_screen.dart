import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

/// F08 inspection queue from RankingService. Only valid, comparable scans
/// are ranked; everything else is listed as "Needs scan".
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider).value;
    final queue = ref.watch(
      inspectionQueueProvider((role: role, locationId: null, lotId: null)),
    );
    return Scaffold(
      appBar: const KernelAppBar(title: 'Inspection queue'),
      body: AsyncView<InspectionQueue>(
        value: queue,
        data: (queue) => PageList(
          children: [
            ScreenHeader(
              title: 'Inspection queue',
              subtitle: queue.modelVersion == null || queue.ranked.isEmpty
                  ? 'Nothing ranked yet'
                  : provenanceLine(
                      modelVersion: queue.modelVersion!,
                      experimental: queue.ranked.any(
                        (e) => e.latestValidScan.experimental,
                      ),
                    ),
            ),
            const Text(
              'The order is a suggestion of what to check first. Inspect '
              'physically before any decision.',
            ),
            const SectionTitle('Ranked'),
            if (queue.ranked.isEmpty)
              const Text(
                'No item has a usable model result yet, so nothing is '
                'ranked. Items without one are listed under "Needs scan".',
              )
            else
              for (final (index, entry) in queue.ranked.indexed)
                ItemTile(
                  item: entry.item,
                  onTap: () => context.push(Routes.item(entry.item.id)),
                  trailing: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('#${index + 1}'),
                      ScanResultChip(
                        quality: entry.latestValidScan.quality,
                        result: entry.latestValidScan.result,
                      ),
                    ],
                  ),
                ),
            SectionTitle('Needs scan (${queue.needsScan.length})'),
            if (queue.needsScan.isEmpty)
              const Text('Every item has a usable scan.')
            else
              for (final item in queue.needsScan)
                ItemTile(
                  item: item,
                  onTap: () => context.push(Routes.item(item.id)),
                  trailing: const StatusChip(
                    label: 'Needs scan',
                    tone: StatusTone.neutral,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
