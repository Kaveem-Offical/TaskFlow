import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Modern Monochrome + Vibrant Accent Palette
  static const Color accentLight = Color(0xFF5E6AD2); // Elegant Purple/Blue
  static const Color accentDark = Color(0xFF6B79ED);

  // Light Mode Colors
  static const Color _lightBackground = Color(0xFFF9FAFB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightBorder = Color(0xFFE5E7EB);
  static const Color _lightError = Color(0xFFEF4444);

  // Dark Mode Colors
  static const Color _darkBackground = Color(0xFF111111);
  static const Color _darkSurface = Color(0xFF1C1C1C);
  static const Color _darkSurfaceVariant = Color(0xFF262626);
  static const Color _darkTextPrimary = Color(0xFFF9FAFB);
  static const Color _darkTextSecondary = Color(0xFFA1A1AA);
  static const Color _darkBorder = Color(0xFF27272A);
  static const Color _darkError = Color(0xFFF87171);

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -1.0, fontSize: 32),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5, fontSize: 24),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.5, fontSize: 20),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.5, fontSize: 18),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.2, fontSize: 16),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.2, fontSize: 14),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0, fontSize: 14),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, letterSpacing: 0, fontSize: 12),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0, fontSize: 16),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0, fontSize: 14),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, letterSpacing: 0, fontSize: 12),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0, fontSize: 14), // Buttons
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accentLight,
        onPrimary: Colors.white,
        secondary: _lightSurfaceVariant,
        onSecondary: _lightTextPrimary,
        surface: _lightSurface,
        onSurface: _lightTextPrimary,
        error: _lightError,
        onError: Colors.white,
        outline: _lightBorder,
        outlineVariant: _lightBorder,
        surfaceContainerHighest: _lightSurfaceVariant,
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: _lightTextPrimary,
        displayColor: _lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightError, width: 1),
        ),
        labelStyle: const TextStyle(color: _lightTextSecondary),
        hintStyle: const TextStyle(color: _lightTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentDark,
        onPrimary: Colors.white,
        secondary: _darkSurfaceVariant,
        onSecondary: _darkTextPrimary,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: _darkError,
        onError: Colors.white,
        outline: _darkBorder,
        outlineVariant: _darkBorder,
        surfaceContainerHighest: _darkSurfaceVariant,
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: _darkTextPrimary,
        displayColor: _darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkError, width: 1),
        ),
        labelStyle: const TextStyle(color: _darkTextSecondary),
        hintStyle: const TextStyle(color: _darkTextSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
