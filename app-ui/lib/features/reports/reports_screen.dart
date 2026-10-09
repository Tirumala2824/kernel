import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';

/// How many recent scans the history list shows.
const reportHistoryLimit = 50;

/// Reports tab: local CSV/PDF export from stored records, shared via the
/// system share sheet, plus recent scan history for the active role.
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
    final items = ref.watch(itemsByRoleProvider(role));
    final recent = ref.watch(recentScansProvider(reportHistoryLimit));
    return PageList(
      children: [
        ScreenHeader(title: 'Reports', subtitle: role.reportTitle),
        ExportPanel(
          scope: ReportScope(role: role),
          title: role.reportTitle,
        ),
        const SectionTitle('Recent scans'),
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
                if (mine.isEmpty) {
                  return const Text(
                    'No scans yet. Scans you record appear here.',
                  );
                }
                return Column(
                  children: [
                    for (final scan in mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScanRecordTile(
                          scan: scan,
                          itemLabel: labels[scan.itemId],
                          onTap: () =>
                              context.push(Routes.result(scan.itemId, scan.id)),
                        ),
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

/// CSV / PDF export buttons for one report scope.
class ExportPanel extends ConsumerStatefulWidget {
  const ExportPanel({super.key, required this.scope, required this.title});

  final ReportScope scope;
  final String title;

  @override
  ConsumerState<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends ConsumerState<ExportPanel> {
  ReportFormat? _busy;
  String? _error;
  String? _lastPath;

  Future<void> _export(ReportFormat format) async {
    setState(() {
      _busy = format;
      _error = null;
    });
    final reports = ref.read(reportServiceProvider);
    final sharer = ref.read(reportSharerProvider);
    try {
      final path = await reports.export(widget.scope, format);
      if (!mounted) return;
      setState(() => _lastPath = path);
      await sharer.shareFile(path, subject: 'Kernel ${widget.title}');
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = 'The report could not be created or shared. $e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KernelCard(
      key: const Key('export-panel'),
      tone: KernelCardTone.sage,
      icon: Icons.description_outlined,
      title: widget.title,
      subtitle:
          'Built only from records stored on this phone. Every scan shows '
          'its model version and experimental status. AI predictions and '
          'verified inspection findings are listed separately.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('export-csv'),
                onPressed: _busy == null
                    ? () => _export(ReportFormat.csv)
                    : null,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export CSV'),
              ),
              FilledButton.icon(
                key: const Key('export-pdf'),
                onPressed: _busy == null
                    ? () => _export(ReportFormat.pdf)
                    : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          if (_lastPath != null && _error == null) ...[
            const SizedBox(height: 8),
            Text('Saved on this phone: $_lastPath'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorNote(_error!),
          ],
        ],
      ),
    );
  }
}
