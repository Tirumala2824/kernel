import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';

/// Scan tab: choose which sack or container to scan. Each scan is tied to
/// exactly one item (one sack per scan, never multi-sack).
class ScanTabScreen extends ConsumerWidget {
  const ScanTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: role == null ? const SizedBox.shrink() : _ScanPicker(role: role),
    );
  }
}

class _ScanPicker extends ConsumerWidget {
  const _ScanPicker({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final kind = role.itemKind;
    return PageList(
      children: [
        ScreenHeader(
          title: l.guidedScanTitle,
          subtitle: l.scanTabSubtitle(kind),
        ),
        if (role == Role.storageFpo)
          KernelCard(
            key: const Key('scan-tab-batch'),
            tone: KernelCardTone.sage,
            icon: Icons.playlist_play_rounded,
            title: l.batchScanTitle,
            subtitle: l.batchScanSubtitle,
            onTap: () => context.push(Routes.batchSetup),
          ),
        KernelCard(
          key: const Key('scan-tab-qr'),
          tone: KernelCardTone.ivory,
          icon: Icons.qr_code_scanner_rounded,
          title: l.qrCardTitle,
          subtitle: l.qrCardSubtitle(kind),
          onTap: () => context.push(Routes.qr),
        ),
        KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.touch_app_rounded,
          title: l.oneAtATimeTitle,
          subtitle: l.oneAtATimeBody,
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                illustration: role == Role.household
                    ? KernelIllustrations.container
                    : KernelIllustrations.sacks,
                message: l.emptyItemsMessage(kind),
                detail: l.scanTabEmptyDetail,
                actionLabel: l.emptyItemsAction(kind),
                onAction: () => context.push(Routes.newItem()),
              );
            }
            final sorted = [...items]
              ..sort(
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              );
            return Column(
              children: [
                for (final item in sorted)
                  ItemTile(
                    item: item,
                    trailing: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.graphic_eq_rounded),
                    ),
                    onTap: () => context.push(Routes.scanItem(item.id)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
