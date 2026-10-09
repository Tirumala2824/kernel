import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
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
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final queue = ref.watch(
      inspectionQueueProvider((role: role, locationId: null, lotId: null)),
    );
    return Scaffold(
      appBar: KernelAppBar(title: l.queueTitle),
      body: AsyncView<InspectionQueue>(
        value: queue,
        data: (queue) => PageList(
          children: [
            ScreenHeader(
              title: l.queueTitle,
              subtitle: queue.modelVersion == null || queue.ranked.isEmpty
                  ? l.queueNothingRankedShort
                  : provenanceLine(
                      l,
                      modelVersion: queue.modelVersion!,
                      experimental: queue.experimental,
                    ),
            ),
            Text(l.queueSuggestionNote),
            SectionTitle(l.rankedTitle),
            if (queue.ranked.isEmpty) ...[
              Center(
                child: KernelIllustration(KernelIllustrations.queue, height: 96),
              ),
              QuietNote(l.queueNothingRanked),
            ] else
              for (final (index, entry) in queue.ranked.indexed)
                ItemTile(
                  item: entry.item,
                  onTap: () => context.push(Routes.item(entry.item.id)),
                  footer: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(label: l.rankLabel(index + 1)),
                      ScanResultChip(
                        quality: entry.latestValidScan.quality,
                        result: entry.latestValidScan.result,
                      ),
                      if (entry.latestValidScan.experimental)
                        const ExperimentalBadge(),
                    ],
                  ),
                ),
            SectionTitle(l.needsScanTitle(queue.needsScan.length)),
            if (queue.needsScan.isEmpty)
              QuietNote(l.needsScanEmpty)
            else
              for (final item in queue.needsScan)
                ItemTile(
                  item: item,
                  onTap: () => context.push(Routes.item(item.id)),
                  footer: StatusChip(
                    label: l.needsScanChip,
                    icon: Icons.hearing_disabled_rounded,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
