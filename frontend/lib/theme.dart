import 'package:flutter/material.dart';

class AppTheme {
  static const Color mint = Color(0xFFBDF7E7);
  static const Color paleMint = Color(0xFFEAFBF5);
  static const Color teal = Color(0xFF168A8F);
  static const Color deepTeal = Color(0xFF075E63);
  static const Color coral = Color(0xFFFF7E67);
  static const Color amber = Color(0xFFFFB84D);
  static const Color ink = Color(0xFF183A3D);
  static const Color cloud = Color(0xFFF7FFFC);
  static const Color line = Color(0xFFE0F0EA);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: coral,
      surface: cloud,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cloud,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: ink,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: ink,
          fontSize: 16,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF587275),
          fontSize: 14,
          height: 1.35,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepTeal,
          side: const BorderSide(color: line),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: coral,
        inactiveTrackColor: mint,
        thumbColor: Colors.white,
        overlayColor: coral.withValues(alpha: 0.16),
        valueIndicatorColor: deepTeal,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  static BoxDecoration explorerGradient({double opacity = 1}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          paleMint.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity),
          mint.withValues(alpha: opacity),
        ],
      ),
    );
  }

  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}
