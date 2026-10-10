import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/status_chip.dart';

/// Human verified finding, separate from the AI analysis. Set once by a
/// person who checked physically; never overwritten.
class SightingFindingSection extends ConsumerStatefulWidget {
  const SightingFindingSection({super.key, required this.sighting});

  final Sighting sighting;

  @override
  ConsumerState<SightingFindingSection> createState() =>
      _SightingFindingSectionState();
}

class _SightingFindingSectionState
    extends ConsumerState<SightingFindingSection> {
  VerifiedFinding? _choice;
  bool _saving = false;
  bool _failed = false;

  Future<void> _record(VerifiedFinding finding) async {
    final l = context.l10n;
    final ok = await confirmAction(
      context,
      title: l.pestDetailRecordFinding,
      body: l.pestDetailConfirmFinding(finding.label(l)),
      confirmLabel: l.pestDetailRecordFinding,
      icon: Icons.fact_check_rounded,
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(sightingRepositoryProvider)
          .setVerifiedFinding(widget.sighting.id, finding);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final finding = widget.sighting.verifiedFinding;
    return Container(
      key: const Key('sighting-finding'),
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.forest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pestDetailVerified,
            style: textTheme.titleMedium?.copyWith(
              color: KernelColors.forest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KernelSpace.xs),
          Text(l.pestDetailVerifiedBody, style: textTheme.bodyMedium),
          const SizedBox(height: KernelSpace.md),
          if (finding != null)
            StatusChip(
              key: const Key('sighting-finding-value'),
              label: finding.label(l),
              tone: StatusTone.positive,
              icon: Icons.fact_check_rounded,
            )
          else ...[
            Wrap(
              spacing: KernelSpace.sm,
              runSpacing: KernelSpace.sm,
              children: [
                for (final option in VerifiedFinding.values)
                  ChoiceChip(
                    key: Key('sighting-finding-${option.name}'),
                    label: Text(option.label(l)),
                    selected: _choice == option,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _choice = option),
                  ),
              ],
            ),
            if (_choice case final choice?) ...[
              const SizedBox(height: KernelSpace.xs),
              Text(choice.help(l), style: textTheme.bodySmall),
            ],
            const SizedBox(height: KernelSpace.md),
            if (_failed) ...[
              ErrorNote(l.pestSaveFailed),
              const SizedBox(height: KernelSpace.sm),
            ],
            FilledButton.icon(
              key: const Key('sighting-finding-save'),
              onPressed: _choice == null || _saving
                  ? null
                  : () => _record(_choice!),
              icon: const Icon(Icons.check_rounded),
              label: Text(l.pestDetailRecordFinding),
            ),
          ],
        ],
      ),
    );
  }
}
