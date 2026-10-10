import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'pest_platform.dart';

/// Optional "Save location". The pin is shown only for a fix within
/// [maxPinAccuracyMeters]; otherwise only the room is saved.
class PestLocationPanel extends StatelessWidget {
  const PestLocationPanel({
    super.key,
    required this.fix,
    required this.locating,
    required this.onLocate,
  });

  final LocationFix? fix;
  final bool locating;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final fix = this.fix;
    return Container(
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.md),
        border: Border.all(color: KernelColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pestSaveLocationBody, style: textTheme.bodyMedium),
          const SizedBox(height: KernelSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('pest-save-location'),
              onPressed: locating ? null : onLocate,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(locating ? l.pestLocating : l.pestSaveLocation),
            ),
          ),
          if (fix != null) ...[
            const SizedBox(height: KernelSpace.sm),
            if (fix.isPrecise)
              Column(
                key: const Key('pest-pin'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    label: l.pestLocationPinned(fix.accuracyMeters!.round()),
                    tone: StatusTone.positive,
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: KernelSpace.xs),
                  Text(
                    '${fix.latitude!.toStringAsFixed(5)}, '
                    '${fix.longitude!.toStringAsFixed(5)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              )
            else
              QuietNote(
                switch (fix.status) {
                  LocationFixStatus.denied => l.pestLocationDenied,
                  LocationFixStatus.serviceOff => l.pestLocationOff,
                  LocationFixStatus.failed => l.pestLocationFailed,
                  _ => l.pestLocationImprecise,
                },
                key: Key('pest-location-${fix.status.name}'),
                icon: Icons.location_off_rounded,
              ),
          ],
        ],
      ),
    );
  }
}
