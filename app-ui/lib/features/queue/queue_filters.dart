import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';

/// Model classes the queue can be narrowed to (ranked entries only).
const queueResultFilters = [
  Classification.infested,
  Classification.uncertain,
  Classification.clean,
];

/// "Scanned within" choices, in days.
const queueAgeFilters = [7, 14, 30];

/// Filter chips for the inspection queue: model result, place and how
/// recent the last usable scan is. Each row has a text label, and the
/// selected chip shows a check mark, so state never depends on colour.
class QueueFilterBar extends ConsumerWidget {
  const QueueFilterBar({
    super.key,
    required this.result,
    required this.locationId,
    required this.maxAgeDays,
    required this.onResult,
    required this.onLocation,
    required this.onMaxAge,
  });

  final Classification? result;
  final String? locationId;
  final int? maxAgeDays;
  final ValueChanged<Classification?> onResult;
  final ValueChanged<String?> onLocation;
  final ValueChanged<int?> onMaxAge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final places = ref.watch(allLocationsProvider).value ?? const <Location>[];
    return Column(
      key: const Key('queue-filters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterRow(
          label: l.queueFilterResult,
          chips: [
            _chip(
              const Key('filter-result-all'),
              l.queueFilterAllResults,
              result == null,
              () => onResult(null),
            ),
            for (final c in queueResultFilters)
              _chip(
                Key('filter-result-${c.name}'),
                c.predictionLabel(l),
                result == c,
                () => onResult(c),
              ),
          ],
        ),
        if (places.isNotEmpty)
          _FilterRow(
            label: l.queueFilterPlace,
            chips: [
              _chip(
                const Key('filter-location-all'),
                l.queueFilterAllPlaces,
                locationId == null,
                () => onLocation(null),
              ),
              for (final place in places)
                _chip(
                  Key('filter-location-${place.id}'),
                  place.name,
                  locationId == place.id,
                  () => onLocation(place.id),
                ),
            ],
          ),
        _FilterRow(
          label: l.queueFilterAge,
          chips: [
            _chip(
              const Key('filter-age-any'),
              l.queueFilterAnyAge,
              maxAgeDays == null,
              () => onMaxAge(null),
            ),
            for (final days in queueAgeFilters)
              _chip(
                Key('filter-age-$days'),
                l.queueFilterWithinDays(days),
                maxAgeDays == days,
                () => onMaxAge(days),
              ),
          ],
        ),
        if (maxAgeDays != null)
          Text(
            l.queueFilterAgeNote(maxAgeDays!),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: KernelColors.inkMuted),
          ),
      ],
    );
  }

  static Widget _chip(
    Key key,
    String label,
    bool selected,
    VoidCallback onTap,
  ) => ChoiceChip(
    key: key,
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.chips});

  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KernelSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: KernelColors.forest),
          ),
          const SizedBox(height: KernelSpace.xs),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}
