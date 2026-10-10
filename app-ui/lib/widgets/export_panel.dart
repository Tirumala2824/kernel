import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../app/data_providers.dart';
import '../app/platform_providers.dart';
import '../app/providers.dart';
import '../features/advice/narrative_preview.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'kernel_card.dart';

/// [scope] with an optional user-approved narrative attached.
ReportScope scopeWithNarrative(ReportScope scope, AdviceText? narrative) =>
    ReportScope(
      role: scope.role,
      kind: scope.kind,
      locationId: scope.locationId,
      lotId: scope.lotId,
      harvestId: scope.harvestId,
      itemIds: scope.itemIds,
      narrative: narrative,
    );

/// CSV / PDF export for one report scope. The file is written to
/// app-private storage by ReportService and then offered through the
/// system share sheet. When the on-phone assistant is ready, the user may
/// add an AI-drafted summary: it is previewed first, included only if the
/// user chooses, and never edited into the records.
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
  bool _addSummary = false;

  bool get _summaryAllowed => widget.scope.kind != ReportKind.sackLabels;

  /// Drafts and previews the narrative. Null means export without one
  /// (skipped, or the assistant could not produce a complete draft).
  Future<AdviceText?> _narrative() async {
    final AnalyticsSummary summary;
    try {
      summary = await ref.read(analyticsServiceProvider).summarize(widget.scope);
    } on Object {
      return null;
    }
    if (!mounted) return null;
    final input = ReportNarrativeInput(
      role: widget.scope.role,
      kind: widget.scope.kind,
      summary: summary,
    );
    return showNarrativePreview(context, input: input);
  }

  Future<void> _export(ReportFormat format) async {
    final l = context.l10n;
    final reports = ref.read(reportServiceProvider);
    final sharer = ref.read(reportSharerProvider);
    var scope = widget.scope;
    // The preview dialog is modal, so no second export can start meanwhile.
    if (_summaryAllowed && _addSummary && ref.read(adviceReadyProvider)) {
      final narrative = await _narrative();
      if (!mounted) return;
      scope = scopeWithNarrative(scope, narrative);
    }
    setState(() {
      _busy = format;
      _error = null;
    });
    try {
      final path = await reports.export(scope, format);
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
    final history = widget.scope.kind == ReportKind.history;
    final adviceReady = _summaryAllowed && ref.watch(adviceReadyProvider);
    return KernelCard(
      key: Key('export-panel-$kind'),
      tone: KernelCardTone.sage,
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle ?? l.exportPanelBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (adviceReady) ...[
            SwitchListTile(
              key: Key(history ? 'ai-summary' : 'ai-summary-$kind'),
              contentPadding: EdgeInsets.zero,
              value: _addSummary,
              onChanged: _busy == null
                  ? (v) => setState(() => _addSummary = v)
                  : null,
              title: Text(l.reportAiSummaryToggle),
              subtitle: Text(l.reportAiSummaryBody),
            ),
            const SizedBox(height: 8),
          ],
          ActionWrap(
            children: [
              for (final format in widget.formats)
                FilledButton.icon(
                  key: Key(
                    history ? 'export-${format.name}' : 'export-$kind-${format.name}',
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
