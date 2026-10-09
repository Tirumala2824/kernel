import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';

/// Sack materials offered in the label form. Stored as these codes so the
/// dataset stays consistent across languages.
const sackMaterials = [
  'jute',
  'woven_polypropylene',
  'cotton',
  'plastic_container',
  'metal_container',
  'other',
];

String sackMaterialLabel(AppLocalizations l, String code) => switch (code) {
  'jute' => l.materialJute,
  'woven_polypropylene' => l.materialWovenPp,
  'cotton' => l.materialCotton,
  'plastic_container' => l.materialPlastic,
  'metal_container' => l.materialMetal,
  _ => l.materialOther,
};

/// One selectable research label. Disabled labels explain what evidence is
/// missing instead of hiding.
class LabelOption extends StatelessWidget {
  const LabelOption({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SampleLabel label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final fg = selected ? KernelColors.onForest : KernelColors.ink;
    final help = switch (label) {
      SampleLabel.clean =>
        enabled ? l.labelCleanHelp : l.labelCleanNeedsInspection,
      SampleLabel.infested =>
        enabled ? l.labelInfestedHelp : l.labelInfestedNeedsInspection,
      SampleLabel.unknown => l.labelUnknownHelp,
    };
    return Semantics(
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Material(
          color: selected ? KernelColors.forest : KernelColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KernelRadii.md),
            side: BorderSide(
              color: enabled ? KernelColors.forest : KernelColors.outline,
            ),
          ),
          child: InkWell(
            key: Key('label-${label.name}'),
            borderRadius: BorderRadius.circular(KernelRadii.md),
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: KernelSizes.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      !enabled
                          ? Icons.lock_rounded
                          : selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
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
                            label.label(l),
                            style: textTheme.titleSmall?.copyWith(color: fg),
                          ),
                          Text(
                            help,
                            style: textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}

/// Picks the inspection that confirms a clean/infested label.
class EvidencePicker extends StatelessWidget {
  const EvidencePicker({
    super.key,
    required this.inspections,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Inspection> inspections;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RadioGroup<String>(
      groupValue: selectedId,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.evidenceTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(l.evidenceBody),
          for (final inspection in inspections)
            RadioListTile<String>(
              key: Key('evidence-${inspection.id}'),
              value: inspection.id,
              title: Text(
                l.verifiedFindingLine(inspection.verifiedFinding.label(l)),
              ),
              subtitle: Text(
                l.inspectorLine(
                  inspection.inspector,
                  formatDateTime(context, inspection.inspectedAt),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
