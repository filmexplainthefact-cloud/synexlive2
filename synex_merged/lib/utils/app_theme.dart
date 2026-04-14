import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF060D1B);
  static const bg2 = Color(0xFF081528);
  static const card = Color(0xFF0B1F3D);
  static const card2 = Color(0xFF0E2650);
  static const border = Color(0xFF1B3C6E);
  static const blue1 = Color(0xFF1565C0);
  static const blue2 = Color(0xFF1976D2);
  static const blue3 = Color(0xFF42A5F5);
  static const cyan = Color(0xFF00E5FF);
  static const white = Color(0xFFE8F4FF);
  static const muted = Color(0xFF5A80B0);
  static const success = Color(0xFF00E676);
  static const danger = Color(0xFFFF4444);
  static const warn = Color(0xFFFFAA00);
  static const gold = Color(0xFFFFD700);
  static const purple = Color(0xFF7C4DFF);
  static const pink = Color(0xFFF50057);
  static const live = Color(0xFFFF3D00);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.blue3,
      surface: AppColors.card,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.w900),
      displayMedium: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg2,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.orbitron(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      iconTheme: const IconThemeData(color: AppColors.blue3),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.cyan,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}

class AppConstants {
  static const appName = 'SYNEX';
  static const appTagline = 'The Arena for Champions';
  static const welcomeBonus = 10;
  static const referralBonus = 10;
  static const xpPerMatch = 50;
  static const xpPerWin = 150;
}
