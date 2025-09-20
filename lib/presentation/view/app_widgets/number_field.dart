import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? initialValue;
  final void Function(String?) onSaved;
  final String? Function(String?)? validator;
  final bool enabled;

  const NumberTextFormField({
    super.key,
    this.controller,
    required this.label,
    this.initialValue,
    required this.onSaved,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled
              ? baseColor
              : baseColor.withOpacity(0.5), // faded label when disabled
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: enabled
                ? theme.colorScheme.outline
                : theme.colorScheme.outline.withOpacity(0.5), // faded border
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      style: TextStyle(
        color: enabled
            ? baseColor
            : baseColor.withOpacity(0.5), // faded text when disabled
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'សូមបញ្ចូលតម្លៃ។';
            }
            if (double.tryParse(value) == null) {
              return 'សូមបញ្ចូលលេខត្រឹមត្រូវ។';
            }
            return null;
          },
      onSaved: onSaved,
    );
  }
}
