import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/platform_providers.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';

/// Informational connectivity status. Nothing in the core flows needs the
/// network, so this never blocks anything.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    if (offline == null) return const SizedBox.shrink();
    final label = offline ? 'Offline' : 'Online';
    return Semantics(
      label: offline
          ? 'Offline. Everything keeps working on this phone.'
          : 'Online. Kernel does not need the network.',
      excludeSemantics: true,
      child: Container(
        key: const Key('offline-indicator'),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: offline ? KernelColors.sage : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: KernelColors.forest),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.cloud_done_outlined,
              size: 18,
              color: KernelColors.forest,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: KernelColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { switchRole, settings }

/// App bar used on every screen: title, persistent connectivity indicator
/// and (on the tab screens) the Switch role / Settings menu.
class KernelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KernelAppBar({super.key, this.title = 'Kernel', this.showMenu = false});

  final String title;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        const Center(child: OfflineIndicator()),
        if (showMenu)
          PopupMenuButton<_MenuAction>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _MenuAction.switchRole => context.push(Routes.switchRole),
              _MenuAction.settings => context.push(Routes.settings),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.switchRole,
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Switch role'),
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                ),
              ),
            ],
          )
        else
          const SizedBox(width: 8),
      ],
    );
  }
}
