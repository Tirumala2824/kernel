import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

/// Compact result of one batch recording. A usable recording counts down
/// and advances to the next sack on its own; RETRY waits for the user.
class BatchResultPanel extends StatefulWidget {
  const BatchResultPanel({
    super.key,
    required this.scan,
    required this.onNext,
    required this.onRetry,
    required this.isLast,
  });

  final ScanRecord scan;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final bool isLast;

  @override
  State<BatchResultPanel> createState() => _BatchResultPanelState();
}

class _BatchResultPanelState extends State<BatchResultPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: KernelMotion.batchAdvance,
  )..addStatusListener(_onStatus);

  bool get _autoAdvance => widget.scan.quality == ScanQuality.pass;

  @override
  void initState() {
    super.initState();
    if (_autoAdvance) _countdown.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) widget.onNext();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scan = widget.scan;
    final retry = scan.quality == ScanQuality.retry;
    return Container(
      key: const Key('batch-result'),
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: retry ? KernelColors.amberSoft : KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(
          color: retry ? KernelColors.amber : KernelColors.hairline,
        ),
        boxShadow: KernelShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resultHeadline(
              l,
              quality: scan.quality,
              classification: scan.result,
              modelVersion: scan.modelVersion,
            ),
            style: textTheme.titleMedium,
          ),
          if (retry)
            for (final reason in scan.qualityReasons)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(reason.explanation(l)),
              ),
          const SizedBox(height: KernelSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ScanResultChip(quality: scan.quality, result: scan.result),
              StatusChip(
                label: provenanceLine(
                  l,
                  modelVersion: scan.modelVersion,
                  experimental: scan.experimental,
                ),
                tone: StatusTone.info,
                icon: Icons.memory_rounded,
              ),
              if (scan.experimental) const ExperimentalBadge(),
            ],
          ),
          if (_autoAdvance) ...[
            const SizedBox(height: KernelSpace.md),
            AnimatedBuilder(
              animation: _countdown,
              builder: (context, _) {
                final left =
                    (KernelMotion.batchAdvance.inMilliseconds *
                            (1 - _countdown.value) /
                            1000)
                        .ceil();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      key: const Key('batch-countdown'),
                      value: _countdown.value,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isLast
                          ? l.batchSummaryIn(left)
                          : l.batchNextIn(left),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: KernelSpace.md),
          ActionWrap(
            children: [
              FilledButton.icon(
                key: const Key('batch-next'),
                onPressed: () {
                  _countdown.stop();
                  widget.onNext();
                },
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(
                  widget.isLast ? l.batchFinish : l.batchNextSack,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('batch-retry'),
                onPressed: () {
                  _countdown.stop();
                  widget.onRetry();
                },
                icon: const Icon(Icons.replay_rounded),
                label: Text(l.batchRetrySack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// End of a session: what was recorded, then the ranked queue for the same
/// scope. Only valid, comparable scans are ranked; the rest need a scan.
class BatchSummary extends ConsumerWidget {
  const BatchSummary({
    super.key,
    required this.scope,
    required this.walk,
    required this.results,
    required this.skipped,
  });

  final QueueScope scope;
  final List<GrainItem> walk;
  final Map<String, ScanRecord> results;
  final Set<String> skipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(inspectionQueueProvider(scope));
    final retries = results.values
        .where((s) => s.quality == ScanQuality.retry)
        .length;
    final labels = {for (final item in walk) item.id: item.label};
    return Column(
      key: const Key('batch-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: l.batchSummaryTitle,
          subtitle: l.batchSummarySubtitle(walk.length),
        ),
        const SizedBox(height: KernelSpace.sm),
        Wrap(
          spacing: KernelSpace.sm,
          runSpacing: KernelSpace.sm,
          children: [
            StatTile(value: '${results.length}', label: l.batchStatRecorded),
            StatTile(value: '${skipped.length}', label: l.batchStatSkipped),
            StatTile(
              value: '$retries',
              label: l.batchStatRetry,
              attention: retries > 0,
            ),
          ],
        ),
        const SizedBox(height: KernelSpace.md),
        for (final entry in results.entries)
          ScanRecordTile(
            scan: entry.value,
            itemLabel: labels[entry.key],
            onTap: () =>
                context.push(Routes.result(entry.key, entry.value.id)),
          ),
        SectionTitle(l.queueTitle),
        const SizedBox(height: 4),
        Text(l.queueSuggestionNote),
        const SizedBox(height: 8),
        AsyncView<InspectionQueue>(
          value: queue,
          data: (queue) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (queue.ranked.isEmpty)
                QuietNote(l.queueNothingRanked)
              else
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
                      ],
                    ),
                  ),
              const SizedBox(height: 8),
              Text(
                l.needsScanTitle(queue.needsScan.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
      ],
    );
  }
}
