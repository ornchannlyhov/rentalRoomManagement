import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(
                    0x0D000000), // Replaced Colors.black.withOpacity(0.05)
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFBDBDBD), // Replaced Colors.grey.shade400
                fontSize: 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: const Color(0xFF757575), // Replaced Colors.grey.shade600
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0)), // Replaced Colors.grey.shade200
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFE0E0E0)), // Replaced Colors.grey.shade200
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFF44336), width: 1), // Replaced Colors.red
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFFF44336), width: 2), // Replaced Colors.red
              ),
              filled: true,
              fillColor:
                  const Color(0xFFFAFAFA), // Replaced Colors.grey.shade50
              contentPadding: const EdgeInsets.all(20),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}
