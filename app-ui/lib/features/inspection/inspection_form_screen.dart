import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

/// F09 record a physical inspection. The verified finding is entered by a
/// person and is never pre-filled from, or merged with, the AI prediction.
class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({super.key, required this.itemId, this.scanId});

  final String itemId;

  /// Scan that prompted this inspection, if any.
  final String? scanId;

  @override
  ConsumerState<InspectionFormScreen> createState() =>
      _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inspector = TextEditingController();
  final _observations = TextEditingController();
  DateTime _inspectedAt = DateTime.now();
  VerifiedFinding? _finding;
  FollowUpStatus _followUp = FollowUpStatus.open;
  bool _findingMissing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _inspector.dispose();
    _observations.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _findingMissing = _finding == null);
    if (!valid || _finding == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(inspectionRepositoryProvider)
          .create(
            InspectionDraft(
              itemId: widget.itemId,
              scanId: widget.scanId,
              inspectedAt: _inspectedAt,
              inspector: _inspector.text.trim(),
              observations: _observations.text.trim(),
              verifiedFinding: _finding!,
              followUpStatus: _followUp,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Inspection saved')));
      context.pop();
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final scans = ref.watch(scansForItemProvider(widget.itemId)).value;
    final scanId = widget.scanId;
    final linkedScan = scanId == null
        ? null
        : scans?.where((s) => s.id == scanId).firstOrNull;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const KernelAppBar(title: 'Record inspection'),
      body: FormPage(
        formKey: _formKey,
        saveLabel: 'Save inspection',
        saving: _saving,
        error: _error,
        onSave: _save,
        children: [
          ScreenHeader(
            title: 'Physical inspection',
            subtitle: item == null ? null : '${item.grainType} • ${item.label}',
          ),
          _AiPredictionPanel(scan: linkedScan, linked: scanId != null),
          Container(
            key: const Key('verified-finding-panel'),
            padding: const EdgeInsets.all(KernelSizes.pagePadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KernelSizes.cardRadius),
              border: Border.all(color: KernelColors.forest, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_search, color: KernelColors.forest),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your verified finding',
                        style: textTheme.titleMedium?.copyWith(
                          color: KernelColors.forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'What you saw yourself when you checked the grain. This is '
                  'stored separately from the AI prediction.',
                ),
                const SizedBox(height: 12),
                for (final finding in VerifiedFinding.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FindingOption(
                      finding: finding,
                      selected: _finding == finding,
                      onTap: () => setState(() {
                        _finding = finding;
                        _findingMissing = false;
                      }),
                    ),
                  ),
                if (_findingMissing)
                  Text(
                    'Choose what you found',
                    key: const Key('finding-missing'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          TextFormField(
            key: const Key('field-inspector'),
            controller: _inspector,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Inspector name'),
            validator: (v) => requiredText(v, 'who inspected'),
          ),
          DateField(
            key: const Key('field-inspected-at'),
            label: 'Inspection date',
            value: _inspectedAt,
            onChanged: (d) => setState(() {
              final now = DateTime.now();
              _inspectedAt = DateUtils.isSameDay(d, now)
                  ? now
                  : DateTime(d.year, d.month, d.day, 12);
            }),
          ),
          TextFormField(
            key: const Key('field-observations'),
            controller: _observations,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observations',
              helperText: 'What you saw, where, and how much',
              alignLabelWithHint: true,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Follow-up status', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in FollowUpStatus.values)
                    ChoiceChip(
                      key: Key('follow-up-${status.name}'),
                      label: Text(status.label),
                      selected: _followUp == status,
                      onSelected: (_) => setState(() => _followUp = status),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FindingOption extends StatelessWidget {
  const _FindingOption({
    required this.finding,
    required this.selected,
    required this.onTap,
  });

  final VerifiedFinding finding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? KernelColors.forest : KernelColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KernelColors.forest),
        ),
        child: InkWell(
          key: Key('finding-${finding.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: KernelSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? KernelColors.onForest
                        : KernelColors.forest,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finding.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? KernelColors.onForest
                                : KernelColors.ink,
                          ),
                        ),
                        Text(
                          finding.help,
                          style: TextStyle(
                            color: selected
                                ? KernelColors.onForest
                                : KernelColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only AI output, visually distinct from the human finding: sage
/// background, grey outline, "AI prediction (not verified)" label and the
/// experimental badge, versus the white, forest-bordered finding panel.
class _AiPredictionPanel extends StatelessWidget {
  const _AiPredictionPanel({required this.scan, required this.linked});

  final ScanRecord? scan;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scan = this.scan;
    return Container(
      key: const Key('ai-prediction-panel'),
      padding: const EdgeInsets.all(KernelSizes.pagePadding),
      decoration: BoxDecoration(
        color: KernelColors.sage,
        borderRadius: BorderRadius.circular(KernelSizes.cardRadius),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: KernelColors.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI prediction (not verified)',
                  style: textTheme.titleSmall?.copyWith(
                    color: KernelColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (scan == null)
            Text(
              linked
                  ? 'Loading the linked scan…'
                  : 'No scan linked. This inspection stands on its own.',
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ScanResultChip(quality: scan.quality, result: scan.result),
                if (scan.experimental) const ExperimentalBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provenanceLine(
                modelVersion: scan.modelVersion,
                experimental: scan.experimental,
              ),
            ),
            Text('Scanned ${formatDateTime(context, scan.capturedAt)}'),
          ],
          const SizedBox(height: 8),
          const StatusChip(
            label: 'Not used to fill in your finding',
            tone: StatusTone.neutral,
            icon: Icons.link_off,
          ),
        ],
      ),
    );
  }
}
