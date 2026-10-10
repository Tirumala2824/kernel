import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import 'pest_providers.dart';

/// Pest & Animal ID start screen: look, listen, sightings and the map.
class PestHubScreen extends StatelessWidget {
  const PestHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: KernelAppBar(title: l.pestIdTitle),
      body: PageList(
        children: [
          ScreenHeader(title: l.pestIdTitle, subtitle: l.pestIdSubtitle),
          const PestHubPanel(),
        ],
      ),
    );
  }
}

/// The Pest ID actions, shared by the hub screen and the Scan tab segment.
class PestHubPanel extends ConsumerWidget {
  const PestHubPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final count = ref.watch(recentSightingsProvider(role)).value?.length;
    return Column(
      key: const Key('pest-hub'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KernelCard(
          key: const Key('pest-hub-camera'),
          tone: KernelCardTone.hero,
          icon: Icons.photo_camera_rounded,
          title: l.pestCameraCardTitle,
          subtitle: l.pestCameraCardBody,
          onTap: () => context.push(Routes.pestCamera),
        ),
        const SizedBox(height: 12),
        KernelCard(
          key: const Key('pest-hub-listen'),
          tone: KernelCardTone.sage,
          icon: Icons.hearing_rounded,
          title: l.pestListenCardTitle,
          subtitle: l.pestListenCardBody,
          onTap: () => context.push(Routes.pestListen),
        ),
        const SizedBox(height: 12),
        KernelCard(
          key: const Key('pest-hub-sightings'),
          tone: KernelCardTone.ivory,
          icon: Icons.list_alt_rounded,
          title: l.pestSightingsCardTitle,
          subtitle: count == null ? null : l.pestSightingsCount(count),
          onTap: () => context.push(Routes.sightings),
        ),
        const SizedBox(height: 12),
        KernelCard(
          key: const Key('pest-hub-map'),
          tone: KernelCardTone.ivory,
          icon: Icons.map_rounded,
          title: l.mapTitle,
          subtitle: l.mapCardBody,
          onTap: () => context.push(Routes.sightingsMap()),
        ),
        const SizedBox(height: 12),
        QuietNote(l.pestOnPhoneNote, icon: Icons.phone_android_rounded),
        const SizedBox(height: 12),
        QuietNote(l.pestNotCertainNote, icon: Icons.info_outline_rounded),
      ],
    );
  }
}

/// Entry card for the Farmer, FPO and Buyer homes.
class PestIdActionCard extends StatelessWidget {
  const PestIdActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KernelCard(
      key: const Key('pest-id-action'),
      tone: KernelCardTone.ivory,
      icon: Icons.pest_control_rounded,
      title: l.pestIdTitle,
      subtitle: l.pestHomeActionBody,
      onTap: () => context.push(Routes.pestHub),
    );
  }
}

/// Hero entry on the Household home.
class PestIdHeroCard extends StatelessWidget {
  const PestIdHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KernelCard(
      key: const Key('pest-id-hero'),
      tone: KernelCardTone.hero,
      icon: Icons.pest_control_rounded,
      title: l.pestIdTitle,
      subtitle: l.pestHomeActionBody,
      onTap: () => context.push(Routes.pestHub),
    );
  }
}
