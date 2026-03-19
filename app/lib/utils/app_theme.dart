import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryNeon = Color(0xFF00FFA3); // Neon Green/Cyan
  static const Color secondaryNeon = Color(0xFF00C2FF); // Bright Blue
  static const Color backgroundDark = Color(0xFF0A0A0B);
  static const Color cardDark = Color(0xFF161618);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color textMain = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNeon,
        brightness: Brightness.dark,
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
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
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(24),
      border: BorderSide(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }
}
