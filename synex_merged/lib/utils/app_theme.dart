import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary   = Color(0xFF1565C0);
  static const Color cyan      = Color(0xFF00E5FF);
  static const Color gold      = Color(0xFFFFD700);
  static const Color liveRed   = Color(0xFFFF3D00);
  static const Color success   = Color(0xFF00E676);
  static const Color danger    = Color(0xFFFF4444);
  static const Color purple    = Color(0xFF7C4DFF);
  static const Color bgDark    = Color(0xFF060D1B);
  static const Color bg2       = Color(0xFF081528);
  static const Color card      = Color(0xFF0B1F3D);
  static const Color card2 = Color(0xFF1A2235);
  static const Color card2     = Color(0xFF0E2650);
  static const Color border    = Color(0xFF1B3C6E);
  static const Color textPri   = Color(0xFFE8F4FF);
  static const Color textSec   = Color(0xFF5A80B0);
  static const Color textHint  = Color(0xFF3A5A8A);

  // Aliases
  static const Color primaryColor   = primary;
  static const Color accentColor    = cyan;
  static const Color backgroundDark = bgDark;
  static const Color cardColor      = card;
  static const Color borderColor    = border;
  static const Color textPrimary    = textPri;
  static const Color textSecondary  = textSec;
  static const Color speakerGreen   = success;

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary, secondary: cyan,
      surface: card, background: bgDark, error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg2, elevation: 0, centerTitle: true,
      iconTheme: IconThemeData(color: textPri),
      titleTextStyle: TextStyle(color: textPri, fontSize: 17, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: card2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cyan, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: danger)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: danger, width: 1.5)),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
      labelStyle: const TextStyle(color: textSec),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: card, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: textPri),
  );
}
