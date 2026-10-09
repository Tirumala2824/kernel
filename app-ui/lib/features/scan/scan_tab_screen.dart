import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
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
    final items = ref.watch(itemsByRoleProvider(role));
    return PageList(
      children: [
        ScreenHeader(
          title: 'Guided acoustic scan',
          subtitle: 'Choose the ${role.itemNoun} to listen to',
        ),
        const KernelCard(
          tone: KernelCardTone.ivory,
          icon: Icons.touch_app_outlined,
          title: 'One at a time',
          subtitle:
              'Each recording belongs to one item. Scan items one after '
              'another; a scan never covers several at once.',
        ),
        AsyncView<List<GrainItem>>(
          value: items,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const Key('empty-items'),
                message: 'No ${role.itemNounPlural} yet',
                detail: 'Register one first, then come back to scan it.',
                actionLabel: role == Role.household
                    ? 'Add your first container'
                    : 'Register your first sack',
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
                    trailing: const Icon(Icons.graphic_eq),
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
