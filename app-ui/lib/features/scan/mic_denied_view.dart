import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Shown when microphone access is refused. Explains why the mic is needed
/// and keeps the rest of the app (inventory, history, reports) usable.
class MicDeniedView extends ConsumerWidget {
  const MicDeniedView({
    super.key,
    required this.access,
    required this.onTryAgain,
  });

  final PermissionAccess access;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final blocked = access != PermissionAccess.denied;
    return PageList(
      key: const Key('mic-denied'),
      children: [
        KernelIllustration(KernelIllustrations.recordings, height: 120),
        ScreenHeader(title: l.micDeniedTitle, subtitle: l.micDeniedSubtitle),
        Text(l.micDeniedPrivacy, style: textTheme.bodyLarge),
        Text(
          blocked ? l.micDeniedBlocked : l.micDeniedAskAgain,
          style: textTheme.bodyLarge,
        ),
        Text(l.micDeniedStillUsable, style: textTheme.bodyLarge),
        FilledButton.icon(
          key: const Key('open-settings'),
          onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
          icon: const Icon(Icons.settings_rounded),
          label: Text(l.actionOpenSettings),
        ),
        OutlinedButton.icon(
          key: const Key('try-again'),
          onPressed: onTryAgain,
          icon: const Icon(Icons.mic_rounded),
          label: Text(l.actionTryAgain),
        ),
        OutlinedButton.icon(
          key: const Key('browse-inventory'),
          onPressed: () => context.go(Routes.inventory),
          icon: const Icon(Icons.inventory_2_rounded),
          label: Text(l.actionBrowseInventory),
        ),
      ],
    );
  }
}
