import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';

/// F02: register a sack or container for the active role.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.locationId, this.lotId});

  final String? locationId;
  final String? lotId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _grain = TextEditingController();
  final _quantity = TextEditingController();
  String _unit = quantityUnits.first;
  DateTime _storageDate = DateUtils.dateOnly(DateTime.now());
  String? _locationId;
  String? _lotId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locationId = widget.locationId;
    _lotId = widget.lotId;
  }

  @override
  void dispose() {
    _label.dispose();
    _grain.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save(Role role) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final item = await ref
          .read(itemRepositoryProvider)
          .create(
            GrainItemDraft(
              ownerRole: role,
              label: _label.text.trim(),
              grainType: _grain.text.trim(),
              quantity: parseQuantity(_quantity.text)!,
              quantityUnit: _unit,
              storageDate: _storageDate,
              locationId: _locationId,
              lotId: _lotId,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved ${item.label}')));
      context.pushReplacement(Routes.item(item.id));
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider).value ?? Role.farmer;
    // Pickers are built only once their options have loaded, so a
    // preselected location or lot shows up as the initial value.
    final locationsAsync = ref.watch(allLocationsProvider);
    final lotsAsync = ref.watch(lotsProvider);
    final locations = locationsAsync.value ?? const <Location>[];
    final lots = lotsAsync.value ?? const <Lot>[];
    final noun = role.itemNoun;
    final showLots = role == Role.buyer || _lotId != null;

    return Scaffold(
      appBar: KernelAppBar(title: role.registerItemAction),
      body: FormPage(
        formKey: _formKey,
        saveLabel: 'Save $noun',
        saving: _saving,
        error: _error,
        onSave: () => _save(role),
        children: [
          TextFormField(
            key: const Key('field-label'),
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: '${noun[0].toUpperCase()}${noun.substring(1)} label',
              helperText: 'The name written on the $noun',
            ),
            validator: (v) => requiredText(v, 'a label'),
          ),
          TextFormField(
            key: const Key('field-grain'),
            controller: _grain,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Grain type'),
            validator: (v) => requiredText(v, 'the grain type'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: const Key('field-quantity'),
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: validateQuantity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: const Key('field-unit'),
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    for (final unit in quantityUnits)
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                ),
              ),
            ],
          ),
          DateField(
            key: const Key('field-storage-date'),
            label: 'Storage date',
            value: _storageDate,
            onChanged: (d) => setState(() => _storageDate = d),
          ),
          if (!locationsAsync.hasValue)
            const Text('Loading places…')
          else
            DropdownButtonFormField<String?>(
              key: const Key('field-location'),
              initialValue: locations.any((l) => l.id == _locationId)
                  ? _locationId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Location (optional)',
                helperText: locations.isEmpty
                    ? 'No places yet. You can add them from ${role.inventoryLabel}.'
                    : null,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                for (final location in locations)
                  DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text('${location.name} (${location.type.label})'),
                  ),
              ],
              onChanged: (v) => setState(() => _locationId = v),
            ),
          if (showLots && !lotsAsync.hasValue)
            const Text('Loading lots…')
          else if (showLots)
            DropdownButtonFormField<String?>(
              key: const Key('field-lot'),
              initialValue: lots.any((l) => l.id == _lotId) ? _lotId : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Lot (optional)',
                helperText: lots.isEmpty ? 'No lots registered yet.' : null,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                for (final lot in lots)
                  DropdownMenuItem<String?>(
                    value: lot.id,
                    child: Text('${lot.code} (${lot.grainType})'),
                  ),
              ],
              onChanged: (v) => setState(() => _lotId = v),
            ),
        ],
      ),
    );
  }
}
