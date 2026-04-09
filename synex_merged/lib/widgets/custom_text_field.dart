import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key, required this.controller, required this.label, required this.hint,
    this.keyboardType = TextInputType.text, this.obscureText = false,
    this.prefixIcon, this.suffixIcon, this.validator, this.maxLines = 1,
    this.textInputAction = TextInputAction.next, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSec, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        obscureText: obscureText, maxLines: maxLines,
        textInputAction: textInputAction, validator: validator, onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPri, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textSec, size: 18) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    ]);
  }
}
