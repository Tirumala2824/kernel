import 'package:flutter/material.dart';

import '../app/copy.dart';

/// Quantity units offered in registration forms.
const quantityUnits = ['kg', 'quintal', 'tonne', 'bags'];

String? requiredText(String? value, String what) =>
    (value == null || value.trim().isEmpty) ? 'Enter $what' : null;

/// Parses a positive quantity, accepting a decimal comma.
double? parseQuantity(String? value) {
  if (value == null) return null;
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
    return null;
  }
  return parsed;
}

String? validateQuantity(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter the quantity';
  return parseQuantity(value) == null ? 'Enter a number above 0' : null;
}

/// Date picker field with a >=48dp target. Dates cannot be in the future.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value.isAfter(now) ? now : value,
          firstDate: firstDate ?? DateTime(now.year - 10),
          lastDate: now,
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatDate(context, value)),
      ),
    );
  }
}

/// Scrollable form body with a primary save button at the end.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.formKey,
    required this.children,
    required this.saveLabel,
    required this.onSave,
    this.saving = false,
    this.error,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String saveLabel;
  final VoidCallback onSave;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final child in children) ...[
              child,
              const SizedBox(height: 16),
            ],
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              key: const Key('save'),
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}
