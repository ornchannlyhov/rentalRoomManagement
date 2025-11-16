import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class NumberTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool enabled;

  const NumberTextFormField({
    super.key,
    this.controller,
    required this.label,
    this.initialValue,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface;
    final localizations = AppLocalizations.of(context)!; 

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? baseColor : baseColor.withOpacity(0.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: enabled
                ? theme.colorScheme.outline
                : theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      style: TextStyle(
        color: enabled ? baseColor : baseColor.withOpacity(0.5),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              // Use localized validation string
              return localizations.pleaseEnterValue;
            }
            if (double.tryParse(value) == null) {
              // Use localized validation string
              return localizations.pleaseEnterValidNumber;
            }
            return null;
          },
    );
  }
}
