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
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      validator: (value) {
        if (value == null || double.tryParse(value) == null) {
          return 'Please enter a valid number.';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}
