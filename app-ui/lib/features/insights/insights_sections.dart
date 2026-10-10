import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';

/// Items listed as "longest since last check".
const staleItemsShown = 5;

/// A never-scanned item, or one this many days since its last scan, is
/// highlighted for attention.
const staleAttentionDays = 14;

int _percent(int part, int whole) =>
    whole == 0 ? 0 : (part * 100 / whole).round();

/// Paper panel for one insight block.
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KernelSpace.lg),
    decoration: BoxDecoration(
      color: KernelColors.paper,
      borderRadius: BorderRadius.circular(KernelRadii.lg),
      border: Border.all(color: KernelColors.hairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class ActivitySection extends ConsumerWidget {
  const ActivitySection({super.key, required this.scope});

  final AnalyticsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final activity = ref.watch(scanActivityProvider(scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.insightsActivityTitle),
        const SizedBox(height: KernelSpace.sm),
        AsyncView<ScanActivity>(
          value: activity,
          data: (a) => Wrap(
            key: const Key('insights-activity'),
            spacing: KernelSpace.sm,
            runSpacing: KernelSpace.sm,
            children: [
              StatTile(
                key: const Key('stat-today'),
                value: '${a.today}',
                label: l.insightsScansToday,
              ),
              StatTile(
                key: const Key('stat-7days'),
                value: '${a.last7Days}',
                label: l.insightsScans7,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResultRatesSection extends ConsumerWidget {
  const ResultRatesSection({super.key, required this.scope});

  final AnalyticsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rates = ref.watch(resultRatesProvider(scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.insightsRatesTitle),
        const SizedBox(height: KernelSpace.sm),
        AsyncView<ResultRates>(
          value: rates,
          data: (r) {
            if (r.total == 0) {
              return EmptyState(
                key: const Key('insights-empty'),
                message: l.insightsRatesEmpty,
                detail: l.insightsRatesEmptyDetail,
                actionLabel: l.quickScanAction,
                actionIcon: Icons.graphic_eq_rounded,
                onAction: () => context.go(Routes.scan),
              );
            }
            String value(int n) => l.insightsBarValue(n, _percent(n, r.total));
            return _Panel(
              key: const Key('insights-rates'),
              children: [
                NoticeBanner(
                  key: const Key('insights-experimental'),
                  text: l.insightsExperimentalNote,
                  icon: Icons.science_rounded,
                ),
                const SizedBox(height: KernelSpace.md),
                if (r.valid == 0) ...[
                  QuietNote(l.insightsNoModelResults),
                  const SizedBox(height: KernelSpace.md),
                ],
                LabeledBarChart(
                  bars: [
                    BarDatum(
                      id: 'infested',
                      label: Classification.infested.predictionLabel(l),
                      value: r.infested,
                      valueLabel: value(r.infested),
                      attention: r.infested > 0,
                    ),
                    BarDatum(
                      id: 'uncertain',
                      label: Classification.uncertain.predictionLabel(l),
                      value: r.uncertain,
                      valueLabel: value(r.uncertain),
                      attention: r.uncertain > 0,
                    ),
                    BarDatum(
                      id: 'clean',
                      label: Classification.clean.predictionLabel(l),
                      value: r.clean,
                      valueLabel: value(r.clean),
                    ),
                    BarDatum(
                      id: 'notEvaluated',
                      label: Classification.notEvaluated.predictionLabel(l),
                      value: r.notEvaluated,
                      valueLabel: value(r.notEvaluated),
                    ),
                    BarDatum(
                      id: 'retry',
                      label: l.insightsRetryLabel,
                      value: r.retry,
                      valueLabel: value(r.retry),
                      attention: r.retry > 0,
                    ),
                  ],
                ),
                Text(
                  l.insightsTotalScans(r.total),
                  key: const Key('insights-total'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

extension QualityReasonShort on QualityReason {
  String shortLabel(AppLocalizations l) => switch (this) {
    QualityReason.silence => l.qualityShortSilence,
    QualityReason.clipping => l.qualityShortClipping,
    QualityReason.highNoise => l.qualityShortHighNoise,
    QualityReason.tooShort => l.qualityShortTooShort,
    QualityReason.permissionDenied => l.qualityShortPermissionDenied,
    QualityReason.captureError => l.qualityShortCaptureError,
  };
}

class QualityFailuresSection extends ConsumerWidget {
  const QualityFailuresSection({super.key, required this.scope});

  final AnalyticsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final failures = ref.watch(qualityFailuresProvider(scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.insightsQualityTitle),
        const SizedBox(height: KernelSpace.sm),
        AsyncView<QualityFailures>(
          value: failures,
          data: (q) {
            if (q.total == 0) {
              return QuietNote(
                l.insightsQualityEmpty,
                key: const Key('quality-empty'),
              );
            }
            final reasons = [
              for (final reason in QualityReason.values)
                if ((q.counts[reason] ?? 0) > 0) reason,
            ]..sort((a, b) => q.counts[b]!.compareTo(q.counts[a]!));
            return _Panel(
              key: const Key('insights-quality'),
              children: [
                LabeledBarChart(
                  bars: [
                    for (final reason in reasons)
                      BarDatum(
                        id: 'quality-${reason.name}',
                        label: reason.shortLabel(l),
                        value: q.counts[reason]!,
                        valueLabel: l.insightsBarValue(
                          q.counts[reason]!,
                          _percent(q.counts[reason]!, q.total),
                        ),
                        attention: true,
                      ),
                  ],
                ),
                Text(l.insightsQualityHint),
              ],
            );
          },
        ),
      ],
    );
  }
}

class InspectionStatsSection extends ConsumerWidget {
  const InspectionStatsSection({super.key, required this.scope});

  final AnalyticsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(inspectionStatsProvider(scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.insightsInspectionsTitle),
        const SizedBox(height: KernelSpace.sm),
        AsyncView<InspectionStats>(
          value: stats,
          data: (s) {
            if (s.total == 0) {
              return QuietNote(
                l.insightsInspectionsEmpty,
                key: const Key('inspections-empty'),
              );
            }
            String value(int n) => l.insightsBarValue(n, _percent(n, s.total));
            return _Panel(
              key: const Key('insights-inspections'),
              children: [
                LabeledBarChart(
                  bars: [
                    BarDatum(
                      id: 'open',
                      label: FollowUpStatus.open.label(l),
                      value: s.open,
                      valueLabel: value(s.open),
                      attention: s.open > 0,
                    ),
                    BarDatum(
                      id: 'inProgress',
                      label: FollowUpStatus.inProgress.label(l),
                      value: s.inProgress,
                      valueLabel: value(s.inProgress),
                    ),
                    BarDatum(
                      id: 'done',
                      label: FollowUpStatus.done.label(l),
                      value: s.done,
                      valueLabel: value(s.done),
                    ),
                  ],
                ),
                Text(
                  l.insightsClosureRate(_percent(s.done, s.total)),
                  key: const Key('closure-rate'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class StaleItemsSection extends ConsumerWidget {
  const StaleItemsSection({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final freshness = ref.watch(itemFreshnessProvider(roleScope(role)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.insightsStaleTitle),
        const SizedBox(height: KernelSpace.sm),
        AsyncView<List<ItemFreshness>>(
          value: freshness,
          data: (list) {
            if (list.isEmpty) {
              return QuietNote(
                l.emptyItemsMessage(role.itemKind),
                key: const Key('stale-empty'),
              );
            }
            return Column(
              key: const Key('insights-stale'),
              children: [
                for (final f in list.take(staleItemsShown))
                  Padding(
                    padding: const EdgeInsets.only(bottom: KernelSpace.sm),
                    child: _StaleTile(item: f),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StaleTile extends StatelessWidget {
  const _StaleTile({required this.item});

  final ItemFreshness item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = item.daysSinceLastScan;
    final attention = days == null || days >= staleAttentionDays;
    return KernelCard(
      key: Key('stale-${item.itemId}'),
      tone: KernelCardTone.ivory,
      icon: attention ? Icons.event_busy_rounded : Icons.event_available_rounded,
      title: item.label,
      onTap: () => context.push(Routes.item(item.itemId)),
      child: StatusChip(
        label: days == null ? l.staleNeverScanned : l.scannedDaysAgo(days),
        tone: attention ? StatusTone.attention : StatusTone.neutral,
        icon: Icons.schedule_rounded,
      ),
    );
  }
}
