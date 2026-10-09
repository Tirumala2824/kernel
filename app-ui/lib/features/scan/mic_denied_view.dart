import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform_providers.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final blocked = access != PermissionAccess.denied;
    return PageList(
      key: const Key('mic-denied'),
      children: [
        const Icon(Icons.mic_off, size: 56, color: KernelColors.forest),
        const ScreenHeader(
          title: 'Microphone access is off',
          subtitle: 'Kernel needs the microphone to listen to grain.',
        ),
        Text(
          'A scan records 2 seconds of sound and checks it on this phone. '
          'The sound is never uploaded, and it is deleted after the check '
          'unless you choose to keep recordings in Settings.',
          style: textTheme.bodyLarge,
        ),
        Text(
          blocked
              ? 'Microphone access is blocked for Kernel. Open the phone '
                    'settings, choose Permissions, then allow Microphone.'
              : 'You can allow it the next time Kernel asks, or in the phone '
                    'settings.',
          style: textTheme.bodyLarge,
        ),
        Text(
          'Without the microphone you can still register items, browse your '
          'inventory, record physical inspections and export reports.',
          style: textTheme.bodyLarge,
        ),
        FilledButton.icon(
          key: const Key('open-settings'),
          onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
          icon: const Icon(Icons.settings),
          label: const Text('Open settings'),
        ),
        OutlinedButton.icon(
          key: const Key('try-again'),
          onPressed: onTryAgain,
          icon: const Icon(Icons.mic),
          label: const Text('Try again'),
        ),
        OutlinedButton.icon(
          key: const Key('browse-inventory'),
          onPressed: () => context.go(Routes.inventory),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Browse inventory'),
        ),
      ],
    );
  }
}
