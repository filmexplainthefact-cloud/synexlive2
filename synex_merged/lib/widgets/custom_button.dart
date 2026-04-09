import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum ButtonVariant { filled, outlined }

class CustomButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final Widget? icon;
  final Color? color;

  const CustomButton({
    super.key, required this.label, required this.isLoading,
    this.onPressed, this.variant = ButtonVariant.filled,
    this.icon, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primary;
    final child = isLoading
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(label),
        ]);

    if (variant == ButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bg, width: 1.5),
          foregroundColor: bg,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
      child: child,
    );
  }
}
