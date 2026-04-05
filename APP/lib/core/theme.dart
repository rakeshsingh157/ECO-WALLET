/// ECO Wallet — Cyan Horizon Design System Theme
/// Matches the "Digital Ether" design language from the UI mockups.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcoColors {
  // Surface hierarchy
  static const surface = Color(0xFF0B1326);
  static const surfaceDim = Color(0xFF0B1326);
  static const surfaceContainerLowest = Color(0xFF060E20);
  static const surfaceContainerLow = Color(0xFF131B2E);
  static const surfaceContainer = Color(0xFF171F33);
  static const surfaceContainerHigh = Color(0xFF222A3D);
  static const surfaceContainerHighest = Color(0xFF2D3449);
  static const surfaceBright = Color(0xFF31394D);
  static const surfaceVariant = Color(0xFF2D3449);

  // Primary — Cyan/Teal Neon
  static const primary = Color(0xFFE9FEFF);
  static const primaryContainer = Color(0xFF00F5FF);
  static const primaryFixed = Color(0xFF63F7FF);
  static const primaryFixedDim = Color(0xFF00DCE5);
  static const onPrimary = Color(0xFF003739);
  static const onPrimaryContainer = Color(0xFF006C71);
  static const inversePrimary = Color(0xFF00696E);

  // Secondary
  static const secondary = Color(0xFFBCC7DE);
  static const secondaryContainer = Color(0xFF3E495D);
  static const onSecondary = Color(0xFF263143);

  // Tertiary
  static const tertiary = Color(0xFFF6FAFF);
  static const tertiaryContainer = Color(0xFFB8E3FF);

  // On-Surface
  static const onSurface = Color(0xFFDAE2FD);
  static const onSurfaceVariant = Color(0xFFB9CACA);
  static const onBackground = Color(0xFFDAE2FD);

  // Error
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);

  // Outline
  static const outline = Color(0xFF849495);
  static const outlineVariant = Color(0xFF3A494A);

  // Surface tint
  static const surfaceTint = Color(0xFF00DCE5);

  // Inverse
  static const inverseSurface = Color(0xFFDAE2FD);
  static const inverseOnSurface = Color(0xFF283044);

  // Success green
  static const success = Color(0xFF4CAF50);
}

class EcoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: EcoColors.surface,
      primaryColor: EcoColors.primaryContainer,
      colorScheme: const ColorScheme.dark(
        primary: EcoColors.primaryContainer,
        onPrimary: EcoColors.onPrimary,
        primaryContainer: EcoColors.primaryContainer,
        onPrimaryContainer: EcoColors.onPrimaryContainer,
        secondary: EcoColors.secondary,
        onSecondary: EcoColors.onSecondary,
        secondaryContainer: EcoColors.secondaryContainer,
        surface: EcoColors.surface,
        onSurface: EcoColors.onSurface,
        error: EcoColors.error,
        onError: Color(0xFF690005),
        outline: EcoColors.outline,
        outlineVariant: EcoColors.outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: EcoColors.primary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: EcoColors.primary,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: EcoColors.primary,
          letterSpacing: 4,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: EcoColors.primary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: EcoColors.primary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: EcoColors.primary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: EcoColors.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: EcoColors.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: EcoColors.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: EcoColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: EcoColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: EcoColors.surface.withOpacity(0.6),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: EcoColors.primaryContainer,
        ),
      ),
      cardTheme: CardThemeData(
        color: EcoColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EcoColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: EcoColors.primaryContainer.withOpacity(0.3),
            width: 1,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          color: EcoColors.onSurfaceVariant.withOpacity(0.5),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EcoColors.primaryContainer,
          foregroundColor: EcoColors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: EcoColors.surface.withOpacity(0.9),
        selectedItemColor: EcoColors.primaryContainer,
        unselectedItemColor: EcoColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EcoColors.surfaceContainerHighest,
        contentTextStyle: GoogleFonts.inter(color: EcoColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
