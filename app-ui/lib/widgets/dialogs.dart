import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Asks the user to confirm an action. Resolves to true only on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: icon == null ? null : Icon(icon, color: KernelColors.forest),
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
          key: const Key('confirm-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('confirm-ok'),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: KernelColors.danger,
                  foregroundColor: KernelColors.onForest,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// What is being archived; picks the matching explanation.
enum ArchiveKind { item, lot, location, harvest }

/// Archive confirm: explains that archiving hides the record but keeps its
/// scan history and inspections.
Future<bool> confirmArchive(
  BuildContext context, {
  required ArchiveKind kind,
  required String name,
}) {
  final l = context.l10n;
  return confirmAction(
    context,
    icon: Icons.inventory_rounded,
    title: l.archiveConfirmTitle(name),
    body: switch (kind) {
      ArchiveKind.item => l.archiveConfirmItemBody,
      ArchiveKind.lot => l.archiveConfirmLotBody,
      ArchiveKind.location => l.archiveConfirmLocationBody,
      ArchiveKind.harvest => l.archiveConfirmHarvestBody,
    },
    confirmLabel: l.archiveAction,
  );
}

/// Single-line text prompt (e.g. who an inspection is assigned to).
/// Resolves to the trimmed text, an empty string to clear, or null when
/// cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String? initial,
  String? helper,
  List<String> suggestions = const [],
  String? clearLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPrompt(
      title: title,
      label: label,
      initial: initial,
      helper: helper,
      suggestions: suggestions,
      clearLabel: clearLabel,
    ),
  );
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.initial,
    required this.helper,
    required this.suggestions,
    required this.clearLabel,
  });

  final String title;
  final String label;
  final String? initial;
  final String? helper;
  final List<String> suggestions;
  final String? clearLabel;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('prompt-field'),
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.label,
                helperText: widget.helper,
              ),
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: KernelSpace.md),
              Wrap(
                spacing: KernelSpace.sm,
                runSpacing: KernelSpace.sm,
                children: [
                  for (final s in widget.suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _controller.text = s),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.clearLabel != null)
          TextButton(
            key: const Key('prompt-clear'),
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(widget.clearLabel!),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          key: const Key('prompt-ok'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l.actionSave),
        ),
      ],
    );
  }
}
