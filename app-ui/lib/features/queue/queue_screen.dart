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
import 'queue_filters.dart';

/// F08 inspection queue from RankingService. Only valid, comparable scans
/// are ranked; everything else is listed as "Needs scan". Filter chips
/// narrow the queue; the ranking rule itself stays in the service.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  Classification? _result;
  String? _locationId;
  int? _maxAgeDays;

  bool get _filtered =>
      _result != null || _locationId != null || _maxAgeDays != null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final queue = ref.watch(
      filteredQueueProvider((
        role: role,
        locationId: _locationId,
        result: _result,
        maxAgeDays: _maxAgeDays,
      )),
    );
    return Scaffold(
      appBar: KernelAppBar(title: l.queueTitle),
      body: PageList(
        children: [
          ScreenHeader(
            title: l.queueTitle,
            subtitle: switch (queue.value) {
              final q? when q.modelVersion != null && q.ranked.isNotEmpty =>
                provenanceLine(
                  l,
                  modelVersion: q.modelVersion!,
                  experimental: q.experimental,
                ),
              _ => l.queueNothingRankedShort,
            },
          ),
          Text(l.queueSuggestionNote),
          QueueFilterBar(
            result: _result,
            locationId: _locationId,
            maxAgeDays: _maxAgeDays,
            onResult: (v) => setState(() => _result = v),
            onLocation: (v) => setState(() => _locationId = v),
            onMaxAge: (v) => setState(() => _maxAgeDays = v),
          ),
          AsyncView<InspectionQueue>(
            value: queue,
            data: (queue) => _QueueLists(queue: queue, filtered: _filtered),
          ),
        ],
      ),
    );
  }
}

class _QueueLists extends StatelessWidget {
  const _QueueLists({required this.queue, required this.filtered});

  final InspectionQueue queue;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.rankedTitle),
        const SizedBox(height: 12),
        if (queue.ranked.isEmpty) ...[
          if (!filtered)
            Center(
              child: KernelIllustration(KernelIllustrations.queue, height: 96),
            ),
          QuietNote(
            filtered ? l.queueNoMatch : l.queueNothingRanked,
            key: const Key('queue-ranked-empty'),
          ),
        ] else
          for (final (index, entry) in queue.ranked.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ItemTile(
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
                    StatusChip(
                      key: Key('reason-${entry.item.id}'),
                      label: entry.reason.label(l),
                      tone: entry.reason == RankReason.clean
                          ? StatusTone.neutral
                          : StatusTone.attention,
                      icon: Icons.help_center_rounded,
                    ),
                    StatusChip(
                      key: Key('age-${entry.item.id}'),
                      label: l.scannedDaysAgo(
                        entry.ageDays ??
                            daysSince(entry.latestValidScan.capturedAt),
                      ),
                      icon: Icons.schedule_rounded,
                    ),
                    if (entry.latestValidScan.experimental)
                      const ExperimentalBadge(),
                  ],
                ),
              ),
            ),
        SectionTitle(l.needsScanTitle(queue.needsScan.length)),
        const SizedBox(height: 12),
        if (queue.needsScan.isEmpty)
          QuietNote(l.needsScanEmpty)
        else
          for (final item in queue.needsScan)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ItemTile(
                item: item,
                onTap: () => context.push(Routes.item(item.id)),
                footer: StatusChip(
                  label: l.needsScanChip,
                  icon: Icons.hearing_disabled_rounded,
                ),
              ),
            ),
      ],
    );
  }
}
