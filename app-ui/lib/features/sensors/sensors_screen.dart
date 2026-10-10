import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import 'sensor_copy.dart';
import 'sensor_providers.dart';
import 'sensor_widgets.dart';

/// Paired sensor nodes with type, battery, link state and health chips.
class SensorsScreen extends ConsumerWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(sensorEventRecorderProvider);
    final nodes = ref.watch(sensorNodesProvider);
    return Scaffold(
      appBar: KernelAppBar(title: l.sensorTitle),
      body: AsyncView<List<SensorNode>>(
        value: nodes,
        data: (nodes) => PageList(
          children: [
            ScreenHeader(title: l.sensorTitle, subtitle: l.sensorSubtitle),
            if (nodes.isEmpty)
              EmptyState(
                key: const Key('sensors-empty'),
                message: l.sensorEmpty,
                detail: l.sensorEmptyDetail,
                actionLabel: l.sensorPairAction,
                actionIcon: Icons.qr_code_scanner_rounded,
                onAction: () => context.push(Routes.sensorPair),
              )
            else ...[
              for (final node in nodes) _NodeTile(node: node),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const Key('sensors-pair'),
                  onPressed: () => context.push(Routes.sensorPair),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(l.sensorPairAction),
                ),
              ),
            ],
            QuietNote(l.sensorPrivacyNote, icon: Icons.phonelink_lock_rounded),
          ],
        ),
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.node});

  final SensorNode node;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: KernelColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        side: const BorderSide(color: KernelColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('sensor-node-${node.id}'),
        onTap: () => context.push(Routes.sensor(node.id)),
        child: Padding(
          padding: const EdgeInsets.all(KernelSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(node.type.icon, color: KernelColors.forest),
              const SizedBox(width: KernelSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(node.name, style: textTheme.titleMedium),
                    Text(
                      node.type.label(l),
                      style: textTheme.bodyMedium?.copyWith(
                        color: KernelColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: KernelSpace.sm),
                    SensorStatusChips(node: node),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KernelColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
