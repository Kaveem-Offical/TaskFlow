import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF3525cd);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color primaryContainer = Color(0xFF4f46e5);
  static const Color onPrimaryContainer = Color(0xFFdad7ff);
  
  static const Color secondary = Color(0xFF6b38d4);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color secondaryContainer = Color(0xFF8455ef);
  static const Color onSecondaryContainer = Color(0xFFfffbff);
  
  static const Color tertiary = Color(0xFF005338);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color tertiaryContainer = Color(0xFF006e4b);
  static const Color onTertiaryContainer = Color(0xFF67f4b7);
  
  static const Color error = Color(0xFFba1a1a);
  static const Color onError = Color(0xFFffffff);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onErrorContainer = Color(0xFF93000a);
  
  static const Color background = Color(0xFFf9f9ff);
  static const Color onBackground = Color(0xFF151c27);
  
  static const Color surface = Color(0xFFf9f9ff);
  static const Color onSurface = Color(0xFF151c27);
  static const Color surfaceVariant = Color(0xFFdce2f3);
  static const Color onSurfaceVariant = Color(0xFF464555);
  
  static const Color outline = Color(0xFF5A5869); // Darkened from 0xFF777587 for better contrast
  static const Color outlineVariant = Color(0xFFB0ADC0); // Darkened from 0xFFc7c4d8
  
  static const Color surfaceContainerHighest = Color(0xFFdce2f3);
  static const Color surfaceContainerHigh = Color(0xFFe2e8f8);
  static const Color surfaceContainer = Color(0xFFe7eefe);
  static const Color surfaceContainerLow = Color(0xFFf0f3ff);
  static const Color surfaceContainerLowest = Color(0xFFffffff);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
