import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../home/buyer_home.dart';

/// Buyer: incoming lots.
class LotsSection extends ConsumerWidget {
  const LotsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lots = ref.watch(lotsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.navInventoryBuyer),
        const SizedBox(height: 8),
        AsyncView<List<Lot>>(
          value: lots,
          data: (lots) => lots.isEmpty
              ? QuietNote(l.lotsSectionEmpty)
              : Column(
                  children: [
                    for (final lot in lots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LotCard(lot: lot),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Household / FPO: top-level places.
class PlacesSection extends ConsumerWidget {
  const PlacesSection({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final places = ref.watch(childLocationsProvider(null));
    final household = role == Role.household;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(household ? l.placesTitle : l.locationsTitle),
        const SizedBox(height: 8),
        AsyncView<List<Location>>(
          value: places,
          data: (places) => places.isEmpty
              ? QuietNote(household ? l.placesEmpty : l.locationsEmpty)
              : Column(
                  children: [
                    for (final place in places)
                      LocationTile(
                        location: place,
                        onTap: () => context.push(Routes.location(place.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Farmer: harvests with their sack counts.
class HarvestsSection extends ConsumerWidget {
  const HarvestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final harvests = ref.watch(harvestsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.harvestsTitle),
        const SizedBox(height: 8),
        AsyncView<List<Harvest>>(
          value: harvests,
          data: (harvests) {
            if (harvests.isEmpty) return QuietNote(l.harvestsSectionEmpty);
            final sorted = [...harvests]
              ..sort((a, b) => b.harvestedAt.compareTo(a.harvestedAt));
            return Column(
              children: [
                for (final harvest in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HarvestCard(harvest: harvest),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class HarvestCard extends ConsumerWidget {
  const HarvestCard({super.key, required this.harvest});

  final Harvest harvest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sacks = ref.watch(itemsByHarvestProvider(harvest.id)).value;
    return KernelCard(
      key: Key('harvest-${harvest.id}'),
      tone: KernelCardTone.ivory,
      icon: Icons.grass_rounded,
      title: harvest.name,
      subtitle: l.harvestCardSubtitle(
        harvest.grainType,
        formatDate(context, harvest.harvestedAt),
      ),
      onTap: () => context.push(Routes.harvest(harvest.id)),
      child: Text(sacks == null ? l.loading : l.sackCount(sacks.length)),
    );
  }
}
