import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../app/platform_providers.dart';
import '../app/providers.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'kernel_card.dart';

/// CSV / PDF export for one report scope. The file is written to
/// app-private storage by ReportService and then offered through the
/// system share sheet.
class ExportPanel extends ConsumerStatefulWidget {
  const ExportPanel({
    super.key,
    required this.scope,
    required this.title,
    this.subtitle,
    this.formats = const [ReportFormat.csv, ReportFormat.pdf],
    this.icon = Icons.description_rounded,
  });

  final ReportScope scope;
  final String title;
  final String? subtitle;
  final List<ReportFormat> formats;
  final IconData icon;

  @override
  ConsumerState<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends ConsumerState<ExportPanel> {
  ReportFormat? _busy;
  String? _error;
  String? _lastPath;

  Future<void> _export(ReportFormat format) async {
    final l = context.l10n;
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
      await sharer.shareFile(path, subject: l.shareSubject(widget.title));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = l.exportFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kind = widget.scope.kind.name;
    return KernelCard(
      key: Key('export-panel-$kind'),
      tone: KernelCardTone.sage,
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle ?? l.exportPanelBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionWrap(
            children: [
              for (final format in widget.formats)
                FilledButton.icon(
                  key: Key(
                    kind == ReportKind.history.name
                        ? 'export-${format.name}'
                        : 'export-$kind-${format.name}',
                  ),
                  onPressed: _busy == null ? () => _export(format) : null,
                  icon: _busy == format
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          format == ReportFormat.csv
                              ? Icons.table_chart_rounded
                              : Icons.picture_as_pdf_rounded,
                        ),
                  label: Text(
                    format == ReportFormat.csv
                        ? l.exportCsv
                        : widget.scope.kind == ReportKind.sackLabels
                        ? l.exportLabelsPdf
                        : l.exportPdf,
                  ),
                ),
            ],
          ),
          if (_lastPath != null && _error == null) ...[
            const SizedBox(height: 8),
            Text(l.exportSavedAt(_lastPath!)),
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

/// "Print sack labels": a PDF of QR labels (`kernel:item:<id>`) for the
/// sacks in [scope], shared for printing.
class SackLabelsPanel extends StatelessWidget {
  const SackLabelsPanel({super.key, required this.scope});

  /// Scope with kind [ReportKind.sackLabels].
  final ReportScope scope;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ExportPanel(
      scope: scope,
      title: l.sackLabelsTitle,
      subtitle: l.sackLabelsBody,
      formats: const [ReportFormat.pdf],
      icon: Icons.qr_code_2_rounded,
    );
  }
}
