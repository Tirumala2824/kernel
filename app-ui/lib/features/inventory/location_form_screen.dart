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

/// Add a home, container, warehouse, room or stack, optionally inside a
/// parent location.
class LocationFormScreen extends ConsumerStatefulWidget {
  const LocationFormScreen({super.key, this.parentId});

  final String? parentId;

  @override
  ConsumerState<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends ConsumerState<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  LocationType? _type;
  String? _parentId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parentId = widget.parentId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  LocationType _defaultType(Role role, List<Location> all) {
    final parent = all.where((x) => x.id == _parentId).firstOrNull;
    return switch (parent?.type) {
      LocationType.warehouse => LocationType.room,
      LocationType.room => LocationType.stack,
      LocationType.home => LocationType.container,
      _ => role.defaultLocationType,
    };
  }

  Future<void> _save(LocationType type) async {
    final l = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .create(
            LocationDraft(
              type: type,
              name: _name.text.trim(),
              parentId: _parentId,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.savedNamed(location.name))));
      context.pushReplacement(Routes.location(location.id));
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
    final allAsync = ref.watch(allLocationsProvider);
    final all = allAsync.value ?? const <Location>[];
    final type = _type ?? _defaultType(role, all);

    return Scaffold(
      appBar: KernelAppBar(title: l.addLocation),
      body: FormPage(
        formKey: _formKey,
        saveLabel: l.saveLocation,
        saving: _saving,
        error: _error,
        onSave: () => _save(type),
        children: [
          DropdownButtonFormField<LocationType>(
            key: ValueKey('field-type-${type.name}'),
            initialValue: type,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.typeField),
            items: [
              for (final t in LocationType.values)
                DropdownMenuItem(value: t, child: Text(t.label(l))),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          TextFormField(
            key: const Key('field-name'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.nameField),
            validator: (v) => requiredText(v, l.validationName),
          ),
          if (!allAsync.hasValue)
            Text(l.loading)
          else
            DropdownButtonFormField<String?>(
              key: const Key('field-parent'),
              initialValue: all.any((x) => x.id == _parentId)
                  ? _parentId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.parentFieldOptional,
                helperText: l.parentFieldHelper,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.parentTopLevel),
                ),
                for (final location in all)
                  DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text(
                      l.nameWithType(location.name, location.type.label(l)),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
        ],
      ),
    );
  }
}
