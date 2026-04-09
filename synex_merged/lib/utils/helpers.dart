import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppHelpers {
  static void showSnackBar(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppTheme.danger : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  static void showToast(BuildContext ctx, String msg, {bool isError = false}) =>
      showSnackBar(ctx, msg, isError: isError);

  static Future<bool> showConfirmDialog(BuildContext ctx, {
    required String title, required String message,
    String confirmText = 'Confirm', String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final res = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText, style: const TextStyle(color: AppTheme.textSec))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: TextStyle(
              color: isDestructive ? AppTheme.danger : AppTheme.cyan,
              fontWeight: FontWeight.w700))),
        ],
      ),
    );
    return res ?? false;
  }

  static String formatMoney(num amount) {
    if (amount >= 10000000) return '${(amount/10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000)   return '${(amount/100000).toStringAsFixed(1)}L';
    if (amount >= 1000)     return '${(amount/1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  static String formatCount(int n) {
    if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n/1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  static Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1565C0), const Color(0xFF00E5FF),
      const Color(0xFF7C4DFF), const Color(0xFFFFD700),
      const Color(0xFF00E676), const Color(0xFFFF3D00),
    ];
    int hash = 0;
    for (var c in name.runes) hash = c + ((hash << 5) - hash);
    return colors[hash.abs() % colors.length];
  }
}
