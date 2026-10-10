import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import 'sensor_providers.dart';

/// Where a node sits: a place from the inventory and, optionally, the sack
/// or container it is on. Uses the existing locations and items.
class SensorPlacementScreen extends ConsumerWidget {
  const SensorPlacementScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final node = ref.watch(sensorNodeProvider(nodeId));
    return Scaffold(
      appBar: KernelAppBar(title: l.sensorPlaceTitle),
      body: AsyncView<SensorNode?>(
        value: node,
        data: (node) => node == null
            ? NotFoundNote(l.sensorNotFound)
            : _PlacementForm(node: node),
      ),
    );
  }
}

class _PlacementForm extends ConsumerStatefulWidget {
  const _PlacementForm({required this.node});

  final SensorNode node;

  @override
  ConsumerState<_PlacementForm> createState() => _PlacementFormState();
}

class _PlacementFormState extends ConsumerState<_PlacementForm> {
  late String? _locationId = widget.node.locationId;
  late String? _itemId = widget.node.itemId;
  bool _saving = false;
  String? _error;

  void _done() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.sensor(widget.node.id));
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(sensorNodeRepositoryProvider)
          .setPlacement(
            widget.node.id,
            SensorPlacement(locationId: _locationId, itemId: _itemId),
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.sensorPlaceSaved)));
      _done();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.sensorPlaceFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locations = ref.watch(allLocationsProvider).value ?? const [];
    final role = ref.watch(activeRoleProvider).value;
    final items = _locationId != null
        ? ref.watch(itemsByLocationProvider(_locationId!)).value
        : role == null
        ? null
        : ref.watch(itemsByRoleProvider(role)).value;
    final activeItems = [
      for (final i in items ?? const <GrainItem>[])
        if (!i.isArchived) i,
    ];
    final locationValue = locations.any((x) => x.id == _locationId)
        ? _locationId
        : null;
    final itemValue = activeItems.any((x) => x.id == _itemId) ? _itemId : null;
    return PageList(
      children: [
        ScreenHeader(
          title: widget.node.name,
          subtitle: l.sensorPlaceSubtitle,
        ),
        if (locations.isEmpty)
          EmptyState(
            key: const Key('sensor-place-no-locations'),
            message: l.sensorPlaceNoLocations,
            actionLabel: l.addLocation,
            onAction: () => context.push(Routes.newLocation()),
          )
        else
          DropdownButtonFormField<String?>(
            key: const Key('sensor-place-location'),
            initialValue: locationValue,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.sensorPlaceLocation),
            items: [
              DropdownMenuItem<String?>(child: Text(l.sensorPlaceNone)),
              for (final loc in locations)
                DropdownMenuItem<String?>(
                  value: loc.id,
                  child: Text(
                    l.nameWithType(loc.name, loc.type.label(l)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() {
              _locationId = v;
              _itemId = null;
            }),
          ),
        KeyedSubtree(
          key: const Key('sensor-place-item'),
          child: DropdownButtonFormField<String?>(
            // Rebuilt when the place changes or the items arrive, so the
            // node's current item shows up once loaded.
            key: ValueKey('item-$_locationId-${items != null}'),
            initialValue: itemValue,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.sensorPlaceItem),
            items: [
              DropdownMenuItem<String?>(child: Text(l.sensorPlaceNone)),
              for (final item in activeItems)
                DropdownMenuItem<String?>(
                  value: item.id,
                  child: Text(
                    l.nameWithType(item.label, item.grainType),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _itemId = v),
          ),
        ),
        QuietNote(l.sensorPlaceNote, icon: Icons.info_outline_rounded),
        if (_error != null) ErrorNote(_error!),
        Wrap(
          spacing: KernelSpace.sm,
          runSpacing: KernelSpace.sm,
          children: [
            FilledButton.icon(
              key: const Key('sensor-place-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.place_rounded),
              label: Text(l.sensorPlaceSave),
            ),
            TextButton(
              key: const Key('sensor-place-skip'),
              onPressed: _saving ? null : _done,
              child: Text(l.sensorPlaceSkip),
            ),
          ],
        ),
      ],
    );
  }
}
