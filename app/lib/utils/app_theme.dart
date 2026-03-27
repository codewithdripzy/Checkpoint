import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === Core Palette (pulled from icon) ===
  static const Color royalBlue = Color(0xFF1454C4); // Icon background blue
  static const Color deepBlue = Color(0xFF0D3A8C); // Darker blue for depth
  static const Color midnight = Color(0xFF071A45); // Near-black deep navy
  static const Color amber = Color(0xFFF5C518); // Icon golden dot
  static const Color amberLight = Color(0xFFFFD84D); // Lighter amber for glow
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFE8EFFF); // Slightly blue-tinted white
  static const Color surfaceBlue = Color(0xFF1A3A7A); // Card surface
  static const Color borderBlue = Color(0xFF2A5AAE); // Border/divider

  // Semantic aliases
  static const Color primaryNeon = royalBlue;
  static const Color secondaryNeon = amber;
  static const Color backgroundDark = midnight;
  static const Color cardDark = surfaceBlue;
  static const Color textMain = white;
  static const Color textSecondary = offWhite;

  static ThemeData darkTheme(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnight,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: royalBlue,
        onPrimary: white,
        secondary: amber,
        onSecondary: midnight,
        error: Colors.redAccent,
        onError: white,
        surface: surfaceBlue,
        onSurface: white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        Theme.of(context).textTheme,
      ).apply(
        bodyColor: white,
        displayColor: white,
      ),
      cardTheme: CardTheme(
        color: surfaceBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderBlue, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: white),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Color(0xFF0D3A8C),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: offWhite),
      dividerColor: borderBlue,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceBlue,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: amber,
        foregroundColor: midnight,
        shape: const CircleBorder(),
        elevation: 6,
      ),
    );
  }

  /// A glassy card surface for overlay panels
  static BoxDecoration glassBoxDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceBlue.withValues(alpha: 0.95),
          deepBlue.withValues(alpha: 0.90),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: borderBlue,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: royalBlue.withValues(alpha: 0.30),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Standard gradient for backgrounds and hero sections
  static LinearGradient backgroundGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [deepBlue, midnight],
    );
  }
}
