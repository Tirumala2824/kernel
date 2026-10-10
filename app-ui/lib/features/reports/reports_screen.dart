import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/export_panel.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';

/// How many recent scans the history list shows.
const reportHistoryLimit = 50;

/// Reports tab: local CSV/PDF export from stored records, shared via the
/// system share sheet, printable sack labels, and recent scan history for
/// the active role.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key, this.presetKind, this.harvestId, this.lotId});

  /// Report opened from a next step ([ReportKind.preSale] for a harvest or
  /// [ReportKind.lotSummary] for a lot); shown first.
  final ReportKind? presetKind;
  final String? harvestId;
  final String? lotId;

  /// Parses the `kind` query parameter written by [Routes.reportPreset].
  static ReportKind? kindFromQuery(String? value) => switch (value) {
    'preSale' => ReportKind.preSale,
    'lotSummary' => ReportKind.lotSummary,
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: role == null
          ? const SizedBox.shrink()
          : _ReportsBody(
              role: role,
              presetKind: presetKind,
              harvestId: harvestId,
              lotId: lotId,
            ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody({
    required this.role,
    this.presetKind,
    this.harvestId,
    this.lotId,
  });

  final Role role;
  final ReportKind? presetKind;
  final String? harvestId;
  final String? lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final recent = ref.watch(recentScansProvider(reportHistoryLimit));
    return PageList(
      children: [
        ScreenHeader(title: l.reportsTitle, subtitle: role.reportTitle(l)),
        if (presetKind != null)
          _PresetPanel(
            role: role,
            kind: presetKind!,
            harvestId: harvestId,
            lotId: lotId,
          ),
        ExportPanel(
          scope: ReportScope(role: role),
          title: role.reportTitle(l),
        ),
        KernelCard(
          key: const Key('reports-insights'),
          tone: KernelCardTone.ivory,
          icon: Icons.insights_rounded,
          title: l.insightsTitle,
          subtitle: l.insightsCardSubtitle,
          onTap: () => context.push(Routes.insights),
        ),
        if (role == Role.farmer) QuietNote(l.reportsFarmerHint),
        if (role == Role.buyer) QuietNote(l.reportsBuyerHint),
        SackLabelsPanel(
          scope: ReportScope(role: role, kind: ReportKind.sackLabels),
        ),
        SectionTitle(l.recentScans),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            final labels = {for (final item in items) item.id: item.label};
            return AsyncView<List<ScanRecord>>(
              value: recent,
              data: (recent) {
                final mine = recent
                    .where((s) => labels.containsKey(s.itemId))
                    .toList();
                if (mine.isEmpty) return QuietNote(l.recentScansEmpty);
                return Column(
                  children: [
                    for (final scan in mine)
                      ScanRecordTile(
                        scan: scan,
                        itemLabel: labels[scan.itemId],
                        onTap: () =>
                            context.push(Routes.result(scan.itemId, scan.id)),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// The report a next step asked for, with its scope already filled in.
class _PresetPanel extends ConsumerWidget {
  const _PresetPanel({
    required this.role,
    required this.kind,
    this.harvestId,
    this.lotId,
  });

  final Role role;
  final ReportKind kind;
  final String? harvestId;
  final String? lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final preSale = kind == ReportKind.preSale;
    final String title;
    if (preSale) {
      final harvest = harvestId == null
          ? null
          : ref.watch(harvestProvider(harvestId!)).value;
      title = harvest == null
          ? l.reportTitleFarmer
          : l.preSaleCardHarvest(harvest.name);
    } else {
      final lot = lotId == null ? null : ref.watch(lotProvider(lotId!)).value;
      title = lot == null ? l.reportTitleBuyer : l.lotSummaryTitle(lot.code);
    }
    return ExportPanel(
      key: const Key('report-preset'),
      scope: ReportScope(
        role: role,
        kind: kind,
        harvestId: preSale ? harvestId : null,
        lotId: preSale ? null : lotId,
      ),
      title: title,
      subtitle: preSale ? l.preSaleBody : l.lotSummaryBody,
    );
  }
}
