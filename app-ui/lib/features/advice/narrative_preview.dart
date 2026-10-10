import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import 'advice_card.dart';

/// Drafts a report narrative on this phone and lets the user Include or
/// Skip it. There is no editing. Completes with the approved text, or null
/// for Skip; also null (silently) when no complete draft could be written.
Future<AdviceText?> showNarrativePreview(
  BuildContext context, {
  required ReportNarrativeInput input,
}) => showDialog<AdviceText>(
  context: context,
  barrierDismissible: false,
  builder: (_) => NarrativePreviewDialog(
    input: input,
    languageTag: adviceLanguageTag(context),
  ),
);

class NarrativePreviewDialog extends ConsumerStatefulWidget {
  const NarrativePreviewDialog({
    super.key,
    required this.input,
    required this.languageTag,
  });

  final ReportNarrativeInput input;
  final String languageTag;

  @override
  ConsumerState<NarrativePreviewDialog> createState() =>
      _NarrativePreviewDialogState();
}

class _NarrativePreviewDialogState
    extends ConsumerState<NarrativePreviewDialog> {
  AdviceText? _draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final draft = _draft;
    return AlertDialog(
      key: const Key('narrative-preview'),
      title: Text(l.reportAiPreviewTitle),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.reportAiPreviewBody),
          const SizedBox(height: 12),
          AdviceStreamCard(
            title: l.reportAiSummaryTitle,
            request: () => ref
                .read(adviceEngineProvider)
                .draftReportNarrative(
                  widget.input,
                  languageTag: widget.languageTag,
                ),
            onComplete: (text) {
              if (text.text.trim().isNotEmpty) setState(() => _draft = text);
            },
            fallback: const _CloseWithoutDraft(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('narrative-skip'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.reportAiSkip),
        ),
        FilledButton(
          key: const Key('narrative-include'),
          onPressed: draft == null
              ? null
              : () => Navigator.of(context).pop(draft),
          child: Text(l.reportAiInclude),
        ),
      ],
    );
  }
}

/// Closes the preview without a draft: the report is exported as usual.
class _CloseWithoutDraft extends StatefulWidget {
  const _CloseWithoutDraft();

  @override
  State<_CloseWithoutDraft> createState() => _CloseWithoutDraftState();
}

class _CloseWithoutDraftState extends State<_CloseWithoutDraft> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
