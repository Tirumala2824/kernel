import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/platform_providers.dart';
import '../app/routes.dart';
import '../brand/kernel_brand.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Informational connectivity status. Nothing in the core flows needs the
/// network, so this never blocks anything.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final offline = ref.watch(isOfflineProvider);
    if (offline == null) return const SizedBox.shrink();
    return Semantics(
      label: offline ? l.offlineSemantics : l.onlineSemantics,
      excludeSemantics: true,
      child: Container(
        key: const Key('offline-indicator'),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: offline ? KernelColors.sage : KernelColors.paper,
          borderRadius: BorderRadius.circular(KernelRadii.pill),
          border: Border.all(color: KernelColors.forestSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: 16,
              color: KernelColors.forest,
            ),
            const SizedBox(width: 6),
            Text(
              offline ? l.offlineLabel : l.onlineLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: KernelColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { switchRole, settings }

/// App bar used on every screen: title (the brand lockup on tab screens),
/// the persistent connectivity indicator and, on tab screens, the QR
/// shortcut plus the Switch role / Settings menu.
class KernelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KernelAppBar({
    super.key,
    this.title,
    this.showMenu = false,
    this.actions = const [],
  });

  /// Null shows the Kernel logo.
  final String? title;
  final bool showMenu;

  /// Extra actions before the connectivity indicator.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = this.title;
    return AppBar(
      toolbarHeight: kToolbarHeight + 4,
      title: title == null
          ? KernelLogo(height: 26, label: l.appTitle)
          : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        ...actions,
        const Center(child: OfflineIndicator()),
        if (showMenu) ...[
          IconButton(
            key: const Key('open-chat'),
            tooltip: 'Agent Screening Chat',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => context.push(Routes.chat),
          ),
          IconButton(
            key: const Key('open-qr'),
            tooltip: l.qrTooltip,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push(Routes.qr),
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: l.menuTooltip,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => switch (action) {
              _MenuAction.switchRole => context.push(Routes.switchRole),
              _MenuAction.settings => context.push(Routes.settings),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.switchRole,
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(l.menuSwitchRole),
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.settings,
                child: ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: Text(l.menuSettings),
                ),
              ),
            ],
          ),
        ] else
          const SizedBox(width: KernelSpace.sm),
      ],
    );
  }
}
