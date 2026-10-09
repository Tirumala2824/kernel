import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';

/// Farmer: create a harvest that groups the sacks registered from it.
class HarvestFormScreen extends ConsumerStatefulWidget {
  const HarvestFormScreen({super.key});

  @override
  ConsumerState<HarvestFormScreen> createState() => _HarvestFormScreenState();
}

class _HarvestFormScreenState extends ConsumerState<HarvestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grain = TextEditingController();
  final _notes = TextEditingController();
  DateTime _harvestedAt = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _grain.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notes = _notes.text.trim();
      final harvest = await ref
          .read(harvestRepositoryProvider)
          .create(
            HarvestDraft(
              name: _name.text.trim(),
              grainType: _grain.text.trim(),
              harvestedAt: _harvestedAt,
              notes: notes.isEmpty ? null : notes,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.savedNamed(harvest.name))));
      context.pushReplacement(Routes.harvest(harvest.id));
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: KernelAppBar(title: l.newHarvestAction),
      body: FormPage(
        formKey: _formKey,
        saveLabel: l.saveHarvest,
        saving: _saving,
        error: _error,
        onSave: _save,
        children: [
          TextFormField(
            key: const Key('field-harvest-name'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: l.harvestNameField,
              helperText: l.harvestNameHelper,
            ),
            validator: (v) => requiredText(v, l.validationName),
          ),
          TextFormField(
            key: const Key('field-grain'),
            controller: _grain,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.grainTypeField),
            validator: (v) => requiredText(v, l.validationGrain),
          ),
          DateField(
            key: const Key('field-harvested-at'),
            label: l.harvestedOnField,
            value: _harvestedAt,
            onChanged: (d) => setState(() => _harvestedAt = d),
          ),
          TextFormField(
            key: const Key('field-notes'),
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.notesFieldOptional,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
