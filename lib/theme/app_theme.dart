import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Base Colors
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
  
  static const Color outline = Color(0xFF5A5869); 
  static const Color outlineVariant = Color(0xFFB0ADC0); 
  
  static const Color surfaceContainerHighest = Color(0xFFdce2f3);
  static const Color surfaceContainerHigh = Color(0xFFe2e8f8);
  static const Color surfaceContainer = Color(0xFFe7eefe);
  static const Color surfaceContainerLow = Color(0xFFf0f3ff);
  static const Color surfaceContainerLowest = Color(0xFFffffff);

  // Dark Mode Base Colors (Rich Stitch dark theme)
  static const Color _darkPrimary = Color(0xFFa4a2ff);
  static const Color _darkOnPrimary = Color(0xFF0a006c);
  static const Color _darkPrimaryContainer = Color(0xFF3525cd);
  static const Color _darkOnPrimaryContainer = Color(0xFFdad7ff);
  
  static const Color _darkSecondary = Color(0xFFcbb0ff);
  static const Color _darkOnSecondary = Color(0xFF3b0091);
  static const Color _darkSecondaryContainer = Color(0xFF531bc0);
  static const Color _darkOnSecondaryContainer = Color(0xFFebdcff);
  
  static const Color _darkTertiary = Color(0xFF47d79c);
  static const Color _darkOnTertiary = Color(0xFF003824);
  static const Color _darkTertiaryContainer = Color(0xFF005338);
  static const Color _darkOnTertiaryContainer = Color(0xFF67f4b7);
  
  static const Color _darkError = Color(0xFFffb4ab);
  static const Color _darkOnError = Color(0xFF690005);
  static const Color _darkErrorContainer = Color(0xFF93000a);
  static const Color _darkOnErrorContainer = Color(0xFFffdad6);
  
  static const Color _darkBackground = Color(0xFF151c27);
  static const Color _darkOnBackground = Color(0xFFe0e2e9);
  
  static const Color _darkSurface = Color(0xFF151c27);
  static const Color _darkOnSurface = Color(0xFFe0e2e9);
  static const Color _darkSurfaceVariant = Color(0xFF464555);
  static const Color _darkOnSurfaceVariant = Color(0xFFc7c4d8);
  
  static const Color _darkOutline = Color(0xFF918f9e);
  static const Color _darkOutlineVariant = Color(0xFF464555);

  static const Color _darkSurfaceContainerHighest = Color(0xFF333541);
  static const Color _darkSurfaceContainerHigh = Color(0xFF282a35);
  static const Color _darkSurfaceContainer = Color(0xFF1e2029);
  static const Color _darkSurfaceContainerLow = Color(0xFF181921);
  static const Color _darkSurfaceContainerLowest = Color(0xFF0d0f15);

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
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
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
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        primaryContainer: _darkPrimaryContainer,
        onPrimaryContainer: _darkOnPrimaryContainer,
        secondary: _darkSecondary,
        onSecondary: _darkOnSecondary,
        secondaryContainer: _darkSecondaryContainer,
        onSecondaryContainer: _darkOnSecondaryContainer,
        tertiary: _darkTertiary,
        onTertiary: _darkOnTertiary,
        tertiaryContainer: _darkTertiaryContainer,
        onTertiaryContainer: _darkOnTertiaryContainer,
        error: _darkError,
        onError: _darkOnError,
        errorContainer: _darkErrorContainer,
        onErrorContainer: _darkOnErrorContainer,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerHighest: _darkSurfaceContainerHighest,
        surfaceContainerHigh: _darkSurfaceContainerHigh,
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerLow: _darkSurfaceContainerLow,
        surfaceContainerLowest: _darkSurfaceContainerLowest,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        outlineVariant: _darkOutlineVariant,
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        elevation: 0,
      ),
    );
  }
}
