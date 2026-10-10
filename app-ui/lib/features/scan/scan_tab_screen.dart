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
import '../pest_id/pest_hub.dart';

/// Scan tab: choose which sack or container to scan. Each scan is tied to
/// exactly one item (one sack per scan, never multi-sack). A segment
/// switches to Pest & Animal ID.
class ScanTabScreen extends ConsumerStatefulWidget {
  const ScanTabScreen({super.key, this.pestMode = false});

  /// Opens on the "Pest & animal" segment.
  final bool pestMode;

  @override
  ConsumerState<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends ConsumerState<ScanTabScreen> {
  late bool _pest = widget.pestMode;

  @override
  void didUpdateWidget(covariant ScanTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pestMode != widget.pestMode) _pest = widget.pestMode;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider).value;
    final segment = _ScanSegment(
      pest: _pest,
      onChanged: (pest) => setState(() => _pest = pest),
    );
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: role == null
          ? const SizedBox.shrink()
          : _pest
          ? PageList(
              children: [
                segment,
                ScreenHeader(
                  title: context.l10n.pestIdTitle,
                  subtitle: context.l10n.pestIdSubtitle,
                ),
                const PestHubPanel(),
              ],
            )
          : _ScanPicker(role: role, segment: segment),
    );
  }
}

/// "Grain sack | Pest & animal".
class _ScanSegment extends StatelessWidget {
  const _ScanSegment({required this.pest, required this.onChanged});

  final bool pest;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SegmentedButton<bool>(
      key: const Key('scan-mode-segment'),
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.graphic_eq_rounded),
          label: Text(l.pestSegmentGrain, key: const Key('scan-mode-grain')),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.pest_control_rounded),
          label: Text(l.pestSegmentPest, key: const Key('scan-mode-pest')),
        ),
      ],
      selected: {pest},
      showSelectedIcon: false,
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}

class _ScanPicker extends ConsumerWidget {
  const _ScanPicker({required this.role, required this.segment});

  final Role role;
  final Widget segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(itemsByRoleProvider(role));
    final kind = role.itemKind;
    return PageList(
      children: [
        segment,
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
