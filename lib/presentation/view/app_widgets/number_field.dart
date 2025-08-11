import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? initialValue;
  final void Function(String?) onSaved;

  const NumberTextFormField({
    super.key,
    this.controller,
    required this.label,
    this.initialValue,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      validator: (value) {
        if (value == null || double.tryParse(value) == null) {
          return 'សូមបញ្ចូលលេខត្រឹមត្រូវ។'; 
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}
