import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';

/// Buyer: register an incoming delivery (lot).
class LotFormScreen extends ConsumerStatefulWidget {
  const LotFormScreen({super.key});

  @override
  ConsumerState<LotFormScreen> createState() => _LotFormScreenState();
}

class _LotFormScreenState extends ConsumerState<LotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _supplier = TextEditingController();
  final _grain = TextEditingController();
  final _quantity = TextEditingController();
  String _unit = quantityUnits.first;
  DateTime _receivedAt = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _supplier.dispose();
    _grain.dispose();
    _quantity.dispose();
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
      final supplier = _supplier.text.trim();
      final lot = await ref
          .read(lotRepositoryProvider)
          .create(
            LotDraft(
              code: _code.text.trim(),
              supplierName: supplier.isEmpty ? null : supplier,
              grainType: _grain.text.trim(),
              declaredQuantity: parseQuantity(_quantity.text)!,
              quantityUnit: _unit,
              receivedAt: _receivedAt,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.savedLot(lot.code))));
      context.pushReplacement(Routes.lot(lot.id));
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
      appBar: KernelAppBar(title: l.buyerHeroTitle),
      body: FormPage(
        formKey: _formKey,
        saveLabel: l.saveLot,
        saving: _saving,
        error: _error,
        onSave: _save,
        children: [
          TextFormField(
            key: const Key('field-code'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: l.lotCodeField,
              helperText: l.lotCodeHelper,
            ),
            validator: (v) => requiredText(v, l.validationLotCode),
          ),
          TextFormField(
            key: const Key('field-supplier'),
            controller: _supplier,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.supplierFieldOptional),
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
                  decoration: InputDecoration(labelText: l.declaredQuantityField),
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
            key: const Key('field-received'),
            label: l.receivedOnField,
            value: _receivedAt,
            onChanged: (d) => setState(() => _receivedAt = d),
          ),
        ],
      ),
    );
  }
}
