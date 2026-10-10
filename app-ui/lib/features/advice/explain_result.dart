import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import 'advice_card.dart';

/// Builds the advice input from stored record fields only (scan, item and
/// latest inspection). Primitives and enums; no audio, paths or records.
ResultAdviceInput resultAdviceInput({
  required ScanRecord scan,
  required GrainItem item,
  Inspection? latestInspection,
  DateTime? now,
}) => ResultAdviceInput(
  role: item.ownerRole,
  grainType: item.grainType,
  classification: scan.result,
  confidence: scan.confidence,
  quality: scan.quality,
  qualityReasons: List.unmodifiable(scan.qualityReasons),
  storageDays: daysSince(item.storageDate, now: now),
  pestModelExperimental: scan.experimental,
  latestVerifiedFinding: latestInspection?.verifiedFinding,
);

/// The static explanation shown when on-phone advice is unavailable.
String staticResultExplanation(AppLocalizations l, ScanRecord scan) {
  if (scan.quality == ScanQuality.retry) return l.adviceStaticRetry;
  return switch (scan.result) {
    Classification.notEvaluated => l.adviceStaticNotEvaluated,
    Classification.infested ||
    Classification.uncertain => l.adviceStaticInspection,
    Classification.clean => l.adviceStaticClean,
  };
}

/// "Explain this result": only offered when the user opted in to the
/// on-phone assistant and its model is ready. Once requested, the card
/// stays (the engine reports busy while it writes).
class ExplainResultSection extends ConsumerStatefulWidget {
  const ExplainResultSection({super.key, required this.scan});

  final ScanRecord scan;

  @override
  ConsumerState<ExplainResultSection> createState() =>
      _ExplainResultSectionState();
}

class _ExplainResultSectionState extends ConsumerState<ExplainResultSection> {
  ResultAdviceInput? _input;
  String? _languageTag;

  void _request(GrainItem item) {
    final inspections =
        ref.read(inspectionsForItemProvider(item.id)).value ??
        const <Inspection>[];
    setState(() {
      _languageTag = adviceLanguageTag(context);
      _input = resultAdviceInput(
        scan: widget.scan,
        item: item,
        latestInspection: inspections.firstOrNull,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final input = _input;
    if (input != null) {
      return AdviceStreamCard(
        key: const Key('explain-card'),
        title: l.adviceExplainTitle,
        request: () => ref
            .read(adviceEngineProvider)
            .explainResult(input, languageTag: _languageTag),
        fallback: QuietNote(
          staticResultExplanation(l, widget.scan),
          key: const Key('explain-static'),
          icon: Icons.info_outline_rounded,
        ),
      );
    }
    if (!ref.watch(adviceReadyProvider)) return const SizedBox.shrink();
    final item = ref.watch(itemProvider(widget.scan.itemId)).value;
    // Keep the latest inspection loaded for the request.
    ref.watch(inspectionsForItemProvider(widget.scan.itemId));
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        key: const Key('explain-result'),
        onPressed: item == null ? null : () => _request(item),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(l.adviceExplainAction),
      ),
    );
  }
}
