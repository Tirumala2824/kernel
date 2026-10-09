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
import '../../widgets/record_tiles.dart';

/// How many recent scans the history list shows.
const reportHistoryLimit = 50;

/// Reports tab: local CSV/PDF export from stored records, shared via the
/// system share sheet, printable sack labels, and recent scan history for
/// the active role.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: role == null ? const SizedBox.shrink() : _ReportsBody(role: role),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final recent = ref.watch(recentScansProvider(reportHistoryLimit));
    return PageList(
      children: [
        ScreenHeader(title: l.reportsTitle, subtitle: role.reportTitle(l)),
        ExportPanel(scope: ReportScope(role: role), title: role.reportTitle(l)),
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
