import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryNeon = Color(0xFF1B5CFF); // Icon blue
  static const Color secondaryNeon = Color(0xFFFFD84D); // Icon yellow
  static const Color backgroundDark =
      Color(0xFFF5F9FF); // Soft white-blue background
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFEAF1FF);
  static const Color textMain = Color(0xFF0D1B3D);
  static const Color textSecondary = Color(0xFF4E628D);

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNeon,
        brightness: Brightness.light,
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surfaceDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        Theme.of(context).textTheme,
      ).apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 4,
        shadowColor: primaryNeon.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side:
              BorderSide(color: primaryNeon.withValues(alpha: 0.12), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static BoxDecoration glassBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: primaryNeon.withValues(alpha: 0.12),
        width: 1,
      ),
    );
  }
}
