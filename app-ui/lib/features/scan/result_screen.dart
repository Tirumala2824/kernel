import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';
import '../advice/explain_result.dart';
import '../inventory/item_detail_screen.dart';

/// F06 screening result for one stored scan. Never a confident verdict:
/// RETRY and notEvaluated show no class, and model provenance, the model's
/// own note and experimental status are always visible.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.itemId, required this.scanId});

  final String itemId;
  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scans = ref.watch(scansForItemProvider(itemId));
    return Scaffold(
      appBar: KernelAppBar(title: l.resultAppBarTitle),
      body: AsyncView<List<ScanRecord>>(
        value: scans,
        data: (scans) {
          final scan = scans.where((s) => s.id == scanId).firstOrNull;
          if (scan == null) return NotFoundNote(l.scanNotFound);
          return _ResultBody(scan: scan);
        },
      ),
    );
  }
}

enum _ResultKind { retry, notEvaluated, inspectionNeeded, clean }

_ResultKind _kindOf(ScanRecord scan) {
  if (scan.quality == ScanQuality.retry) return _ResultKind.retry;
  return switch (scan.result) {
    Classification.notEvaluated => _ResultKind.notEvaluated,
    Classification.infested ||
    Classification.uncertain => _ResultKind.inspectionNeeded,
    Classification.clean => _ResultKind.clean,
  };
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.scan});

  final ScanRecord scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final item = ref.watch(itemProvider(scan.itemId)).value;
    final info = ref.watch(engineInfoProvider).value;
    final kind = _kindOf(scan);
    final provenance = provenanceLine(
      l,
      modelVersion: scan.modelVersion,
      experimental: scan.experimental,
    );
    final headline = resultHeadline(
      l,
      quality: scan.quality,
      classification: scan.result,
      modelVersion: scan.modelVersion,
    );
    final micBlocked = scan.qualityReasons.contains(
      QualityReason.permissionDenied,
    );
    // The note describes the installed model; it applies to this scan only
    // when the scan used that same model version.
    final note = info?.modelNote?.trim();
    final noteApplies =
        note != null &&
        note.isNotEmpty &&
        scan.modelVersion != noModelVersion &&
        info?.modelVersion == scan.modelVersion;
    final noteMissing =
        scan.modelVersion != noModelVersion &&
        info != null &&
        info.modelVersion != scan.modelVersion;

    final (Color bg, Color fg, IconData icon) = switch (kind) {
      _ResultKind.retry => (
        KernelColors.amber,
        KernelColors.ink,
        Icons.replay_rounded,
      ),
      _ResultKind.inspectionNeeded => (
        KernelColors.amber,
        KernelColors.ink,
        Icons.person_search_rounded,
      ),
      _ResultKind.notEvaluated => (
        KernelColors.paper,
        KernelColors.ink,
        Icons.help_outline_rounded,
      ),
      _ResultKind.clean => (
        KernelColors.sage,
        KernelColors.ink,
        Icons.graphic_eq_rounded,
      ),
    };

    final headlineCard = Container(
      key: const Key('result-headline'),
      padding: const EdgeInsets.all(KernelSpace.xl - 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KernelRadii.xl),
        border: kind == _ResultKind.notEvaluated
            ? Border.all(color: KernelColors.outline)
            : null,
        boxShadow: KernelShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kind == _ResultKind.notEvaluated
                  ? KernelColors.sage
                  : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(KernelRadii.md),
            ),
            child: Icon(icon, color: fg, size: 30),
          ),
          const SizedBox(height: KernelSpace.md),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              headline,
              style: textTheme.headlineSmall?.copyWith(color: fg),
            ),
          ),
          if (kind == _ResultKind.retry) ...[
            const SizedBox(height: KernelSpace.md),
            for (final reason in scan.qualityReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: KernelSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.circle, size: 8, color: fg),
                    ),
                    const SizedBox(width: KernelSpace.sm),
                    Expanded(
                      child: Text(
                        reason.explanation(l),
                        style: textTheme.bodyMedium?.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              l.retryNothingSaved,
              style: textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (kind == _ResultKind.inspectionNeeded ||
              kind == _ResultKind.clean) ...[
            const SizedBox(height: KernelSpace.md),
            Text(
              l.predictedClassLine(scan.result.predictionLabel(l)),
              key: const Key('predicted-class'),
              style: textTheme.bodyLarge?.copyWith(color: fg),
            ),
            if (scan.confidence != null)
              Text(
                l.modelScoreLine(scan.confidence!.toStringAsFixed(2)),
                style: textTheme.bodyMedium?.copyWith(color: fg),
              ),
          ],
          const SizedBox(height: KernelSpace.md),
          Wrap(
            spacing: KernelSpace.sm,
            runSpacing: KernelSpace.sm,
            children: [
              StatusChip(
                key: const Key('provenance-chip'),
                label: provenance,
                tone: StatusTone.info,
                icon: Icons.memory_rounded,
              ),
              if (scan.experimental) const ExperimentalBadge(),
            ],
          ),
        ],
      ),
    );

    final sections = <Widget>[
      ScreenHeader(title: l.resultTitle, subtitle: provenance),
      headlineCard,
      if (noteApplies)
        NoticeBanner(
          key: const Key('model-note'),
          title: scan.experimental
              ? l.modelNoteTitleExperimental
              : l.modelNoteTitle,
          text: note,
          tone: StatusTone.attention,
          icon: Icons.science_rounded,
        ),
      if (noteMissing)
        NoticeBanner(
          key: const Key('model-note-missing'),
          text: l.modelNoteOtherVersion(scan.modelVersion),
          tone: StatusTone.neutral,
          icon: Icons.history_rounded,
        ),
      if (kind == _ResultKind.retry)
        FilledButton.icon(
          key: const Key('retry'),
          onPressed: () =>
              context.pushReplacement(Routes.scanItem(scan.itemId)),
          icon: const Icon(Icons.replay_rounded),
          label: Text(l.actionRetry),
        ),
      if (micBlocked)
        OutlinedButton.icon(
          onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
          icon: const Icon(Icons.settings_rounded),
          label: Text(l.actionOpenSettings),
        ),
      NoticeBanner(
        key: const Key('inspection-note'),
        text: l.physicalInspectionNote,
        tone: StatusTone.neutral,
        icon: Icons.person_search_rounded,
      ),
      ExplainResultSection(scan: scan),
      if (item != null)
        ItemSummaryCard(
          item: item,
          onTap: () => context.push(Routes.item(item.id)),
        ),
      ActionWrap(
        children: [
          if (kind == _ResultKind.inspectionNeeded)
            FilledButton.icon(
              key: const Key('record-inspection'),
              onPressed: () =>
                  context.push(Routes.inspect(scan.itemId, scanId: scan.id)),
              icon: const Icon(Icons.person_search_rounded),
              label: Text(l.actionRecordInspection),
            )
          else
            OutlinedButton.icon(
              key: const Key('record-inspection'),
              onPressed: () =>
                  context.push(Routes.inspect(scan.itemId, scanId: scan.id)),
              icon: const Icon(Icons.person_search_rounded),
              label: Text(l.actionRecordInspection),
            ),
          OutlinedButton.icon(
            key: const Key('scan-another'),
            onPressed: () => context.go(Routes.scan),
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(l.actionScanAnother),
          ),
        ],
      ),
      SectionTitle(l.recordingDetails),
      ScanRecordTile(scan: scan),
      FieldRow(
        label: l.fieldCaptured,
        value: formatDateTime(context, scan.capturedAt),
      ),
      FieldRow(label: l.fieldDuration, value: l.unitMs(scan.durationMs)),
      FieldRow(label: l.fieldSampleRate, value: l.unitHz(scan.sampleRate)),
      FieldRow(label: l.fieldAnalysisTime, value: l.unitMs(scan.latencyMs)),
      FieldRow(
        label: l.fieldDevice,
        value: l.deviceAndOs(scan.deviceModel, scan.osVersion),
      ),
    ];

    return _StaggeredReveal(children: sections);
  }
}

/// Fades and lifts the result in, one section after another. Skipped when
/// the platform asks for reduced motion.
class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({required this.children});

  final List<Widget> children;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: KernelMotion.reveal,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    return PageList(
      children: [
        for (var i = 0; i < count; i++)
          _RevealItem(
            animation: CurvedAnimation(
              parent: _controller,
              curve: Interval(
                (i * 0.08).clamp(0.0, 0.6),
                ((i * 0.08) + 0.4).clamp(0.4, 1.0),
                curve: KernelMotion.emphasized,
              ),
            ),
            // The headline gets a little scale for emphasis.
            emphasis: i == 1,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _RevealItem extends AnimatedWidget {
  const _RevealItem({
    required Animation<double> animation,
    required this.child,
    this.emphasis = false,
  }) : super(listenable: animation);

  final Widget child;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 18),
        child: emphasis
            ? Transform.scale(scale: 0.96 + 0.04 * t, child: child)
            : child,
      ),
    );
  }
}
