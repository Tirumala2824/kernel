import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';

/// F02: register a sack or container for the active role, optionally into a
/// place, lot or (farmer) harvest.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({
    super.key,
    this.locationId,
    this.lotId,
    this.harvestId,
  });

  final String? locationId;
  final String? lotId;
  final String? harvestId;

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
  String? _harvestId;
  bool _grainFromHarvest = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locationId = widget.locationId;
    _lotId = widget.lotId;
    _harvestId = widget.harvestId;
  }

  @override
  void dispose() {
    _label.dispose();
    _grain.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save(Role role) async {
    final l = context.l10n;
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
              harvestId: role == Role.farmer ? _harvestId : null,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.savedNamed(item.label))));
      context.pushReplacement(Routes.item(item.id));
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value ?? Role.farmer;
    final kind = role.itemKind;
    // Pickers are built only once their options have loaded, so a
    // preselected location, lot or harvest shows up as the initial value.
    final locationsAsync = ref.watch(allLocationsProvider);
    final lotsAsync = ref.watch(lotsProvider);
    final harvestsAsync = role == Role.farmer
        ? ref.watch(harvestsProvider)
        : const AsyncData(<Harvest>[]);
    final locations = locationsAsync.value ?? const <Location>[];
    final lots = lotsAsync.value ?? const <Lot>[];
    final harvests = harvestsAsync.value ?? const <Harvest>[];
    final showLots = role == Role.buyer || _lotId != null;

    // Prefill the grain type from a preselected harvest once.
    final preset = harvests.where((h) => h.id == _harvestId).firstOrNull;
    if (!_grainFromHarvest && preset != null && _grain.text.isEmpty) {
      _grainFromHarvest = true;
      _grain.text = preset.grainType;
    }

    return Scaffold(
      appBar: KernelAppBar(title: l.registerItemAction(kind)),
      body: FormPage(
        formKey: _formKey,
        saveLabel: l.saveItem(kind),
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
              labelText: l.itemLabelField(kind),
              helperText: l.itemLabelHelper(kind),
            ),
            validator: (v) => requiredText(v, l.validationLabel),
          ),
          TextFormField(
            key: const Key('field-grain'),
            controller: _grain,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.grainTypeField),
            validator: (v) => requiredText(v, l.validationGrain),
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
                  decoration: InputDecoration(labelText: l.quantityField),
                  validator: (v) => validateQuantity(l, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: const Key('field-unit'),
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.unitField),
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
            label: l.storageDateField,
            value: _storageDate,
            onChanged: (d) => setState(() => _storageDate = d),
          ),
          if (role == Role.farmer)
            if (!harvestsAsync.hasValue)
              Text(l.loading)
            else
              DropdownButtonFormField<String?>(
                key: const Key('field-harvest'),
                initialValue: harvests.any((h) => h.id == _harvestId)
                    ? _harvestId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.harvestFieldOptional,
                  helperText: harvests.isEmpty ? l.harvestFieldNone : null,
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                  for (final harvest in harvests)
                    DropdownMenuItem<String?>(
                      value: harvest.id,
                      child: Text(harvest.name),
                    ),
                ],
                onChanged: (v) => setState(() => _harvestId = v),
              ),
          if (!locationsAsync.hasValue)
            Text(l.loading)
          else
            DropdownButtonFormField<String?>(
              key: const Key('field-location'),
              initialValue: locations.any((x) => x.id == _locationId)
                  ? _locationId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.locationFieldOptional,
                helperText: locations.isEmpty
                    ? l.locationFieldNone(role.inventoryLabel(l))
                    : null,
              ),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                for (final location in locations)
                  DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text(
                      l.nameWithType(location.name, location.type.label(l)),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _locationId = v),
            ),
          if (showLots && !lotsAsync.hasValue)
            Text(l.loading)
          else if (showLots)
            DropdownButtonFormField<String?>(
              key: const Key('field-lot'),
              initialValue: lots.any((x) => x.id == _lotId) ? _lotId : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.lotFieldOptional,
                helperText: lots.isEmpty ? l.lotFieldNone : null,
              ),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                for (final lot in lots)
                  DropdownMenuItem<String?>(
                    value: lot.id,
                    child: Text(l.nameWithType(lot.code, lot.grainType)),
                  ),
              ],
              onChanged: (v) => setState(() => _lotId = v),
            ),
        ],
      ),
    );
  }
}
