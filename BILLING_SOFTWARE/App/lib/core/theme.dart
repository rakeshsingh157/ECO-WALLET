import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool isDark = false;

  static Color get canvas => isDark ? const Color(0xFF111822) : const Color(0xFFFAF8F5);
  static Color get surface => isDark ? const Color(0xFF1A222E) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated => isDark ? const Color(0xFF242E3D) : const Color(0xFFF3EFEA);
  static Color get surfaceMuted => isDark ? const Color(0xFF2E3B4D) : const Color(0xFFE8E4DC);

  static Color get terracotta => isDark ? const Color(0xFFFF6E40) : const Color(0xFFE8592A);
  static Color get terracottaDark => isDark ? const Color(0xFFE8592A) : const Color(0xFFD0471A);
  static Color get forestMint => isDark ? const Color(0xFF2ECC71) : const Color(0xFF1E824C);
  static Color get chaiGold => isDark ? const Color(0xFFF1C40F) : const Color(0xFFE6A117);
  static Color get warmNavy => isDark ? const Color(0xFF90CAF9) : const Color(0xFF2C3E50);
  static Color get softIndigo => isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);

  static Color get primary => terracotta;
  static Color get primaryContainer => isDark ? const Color(0xFF382318) : const Color(0xFFFDECE6);
  static Color get secondary => forestMint;
  static Color get secondaryContainer => isDark ? const Color(0xFF153322) : const Color(0xFFE8F5E9);

  static Color get success => isDark ? const Color(0xFF2ECC71) : const Color(0xFF1E824C);
  static Color get warning => isDark ? const Color(0xFFF1C40F) : const Color(0xFFE6A117);
  static Color get error => isDark ? const Color(0xFFE74C3C) : const Color(0xFFD32F2F);
  static Color get info => isDark ? const Color(0xFF3498DB) : const Color(0xFF1976D2);

  static Color get textPrimary => isDark ? const Color(0xFFF5F7FA) : const Color(0xFF1F2421);
  static Color get textSecondary => isDark ? const Color(0xFF9EAAB7) : const Color(0xFF5A645A);
  static Color get textMuted => isDark ? const Color(0xFF6E7C8E) : const Color(0xFF9AA49A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static Color get borderSubtle => isDark ? const Color(0xFF293649) : const Color(0xFFE8E4DC);
  static Color get borderStrong => isDark ? const Color(0xFF3B4D66) : const Color(0xFFD8D2C4);
}

class MascotAssets {
  static const String shopkeeper = 'assets/mascots/mascot_shopkeeper.png';
  static const String delivery = 'assets/mascots/mascot_delivery.png';
  static const String box = 'assets/mascots/mascot_box.png';
  static const String calculator = 'assets/mascots/mascot_calculator.png';
  static const String receipt = 'assets/mascots/mascot_receipt.png';
  static const String coin = 'assets/mascots/mascot_coin.png';
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAF8F5),
      primaryColor: const Color(0xFFE8592A),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE8592A),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFDECE6),
        onPrimaryContainer: Color(0xFFD0471A),
        secondary: Color(0xFF1E824C),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE8F5E9),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1F2421),
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1F2421)),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
        headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
        titleSmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF5A645A)),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1F2421)),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF5A645A)),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF9AA49A)),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1F2421)),
        iconTheme: const IconThemeData(color: Color(0xFF1F2421)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8592A),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E4DC))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E4DC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8592A), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF9AA49A)),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF5A645A)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8E4DC), thickness: 1, space: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111822),
      primaryColor: const Color(0xFFFF6E40),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF6E40),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF382318),
        onPrimaryContainer: Color(0xFFFF8A65),
        secondary: Color(0xFF2ECC71),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF153322),
        surface: Color(0xFF1A222E),
        onSurface: Color(0xFFF5F7FA),
        error: Color(0xFFE74C3C),
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFFF5F7FA)),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
        headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
        titleSmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9EAAB7)),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFF5F7FA)),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF9EAAB7)),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF6E7C8E)),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A222E),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFF5F7FA)),
        iconTheme: const IconThemeData(color: Color(0xFFF5F7FA)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6E40),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A222E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF293649))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF293649))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6E40), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE74C3C))),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6E7C8E)),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF9EAAB7)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF293649), thickness: 1, space: 1),
    );
  }
}
