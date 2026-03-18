import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema Material 3 para PianoScribe.
///
/// Paleta de colores inspirada en un piano:
/// negro/blanco con acentos dorados y azules.
class AppTheme {
  AppTheme._();

  // Colores primarios (Material Orange Palette)
  static const _primaryColor = Color(0xFF121212); // Gris fondo oscuro
  static const _secondaryColor = Color(0xFF333333); // Gris neutro oscuro
  static const _accentColor = Color(0xFFFF9800); // Naranja 500
  static const _goldAccent = Color(0xFFE65100); // Naranja 900
  static const _surfaceColor = Color(0xFF222222); // Gris superficie muy oscuro

  // Textos
  static const _textLight = Color(0xFFF8F9FA); // Texto claro (modo oscuro)
  static const _textNeutral = Color(0xFFE8F0F5); // Gris azulado neutro

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _accentColor,
        secondary: _goldAccent,
        surface: _secondaryColor,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        error: Colors.red.shade400,
      ),
      scaffoldBackgroundColor: _primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _secondaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textLight,
        ),
        iconTheme: const IconThemeData(color: _textLight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _primaryColor,
        selectedItemColor: _accentColor,
        unselectedItemColor: _textNeutral.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: _secondaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _textLight,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textLight,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _textLight,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: _textNeutral,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: _textNeutral,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _accentColor,
        ),
      ),
      iconTheme: const IconThemeData(color: _accentColor),
      dividerTheme: DividerThemeData(
        color: _textNeutral.withValues(alpha: 0.1),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceColor,
        contentTextStyle: GoogleFonts.inter(color: _textLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
