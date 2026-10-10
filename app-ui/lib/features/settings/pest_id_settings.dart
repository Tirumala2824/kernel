import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kernel_card.dart';
import 'settings_sections.dart';

/// Maps consent (guardrails §7). Default false.
final settingsMapsConsentProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchMapsConsent(),
  name: 'settingsMapsConsentProvider',
);

/// Keep validated stills and clips with saved sightings. Default false.
final settingsKeepSightingMediaProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchKeepSightingMedia(),
  name: 'settingsKeepSightingMediaProvider',
);

/// Settings → Pest ID, maps and sensors: the maps consent and keep-media
/// toggles, and entries to the Model Hub and Sensors screens.
class PestIdSettingsSection extends ConsumerWidget {
  const PestIdSettingsSection({super.key});

  Future<void> _setMaps(BuildContext context, WidgetRef ref, bool on) async {
    final l = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    if (!on) {
      await settings.setMapsConsent(false);
      return;
    }
    final agreed = await confirmAction(
      context,
      icon: Icons.map_rounded,
      title: l.hubMapsConfirmTitle,
      body: l.hubMapsConfirmBody,
      confirmLabel: l.hubMapsConfirmAgree,
    );
    if (agreed) await settings.setMapsConsent(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final maps = ref.watch(settingsMapsConsentProvider);
    final keepMedia = ref.watch(settingsKeepSightingMediaProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            SwitchListTile(
              key: const Key('maps-consent-toggle'),
              secondary: const Icon(Icons.map_rounded),
              value: maps.value ?? false,
              onChanged: maps.hasValue
                  ? (v) => _setMaps(context, ref, v)
                  : null,
              title: Text(l.hubMapsToggle),
              subtitle: Text(l.hubMapsToggleBody),
            ),
            SwitchListTile(
              key: const Key('keep-media-toggle'),
              secondary: const Icon(Icons.perm_media_rounded),
              value: keepMedia.value ?? false,
              onChanged: keepMedia.hasValue
                  ? ref.read(settingsRepositoryProvider).setKeepSightingMedia
                  : null,
              title: Text(l.hubKeepMediaToggle),
              subtitle: Text(l.hubKeepMediaToggleBody),
            ),
          ],
        ),
        const SizedBox(height: KernelSpace.md),
        KernelCard(
          key: const Key('open-model-hub'),
          tone: KernelCardTone.ivory,
          icon: Icons.hub_rounded,
          title: l.hubTitle,
          subtitle: l.hubSettingsCard,
          onTap: () => context.push(Routes.models),
        ),
        const SizedBox(height: KernelSpace.md),
        KernelCard(
          key: const Key('open-sensors'),
          tone: KernelCardTone.ivory,
          icon: Icons.sensors_rounded,
          title: l.sensorTitle,
          subtitle: l.sensorSettingsCard,
          onTap: () => context.push(Routes.sensors),
        ),
      ],
    );
  }
}
