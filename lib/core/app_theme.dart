import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF10B981);
  static const Color secondaryColor = Color.fromARGB(255, 66, 255, 192);
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);
  static const Color surface = Color.fromARGB(255, 250, 250, 250);
  static const Color surfaceDark = Color.fromARGB(255, 40, 40, 40);
  static const Color backgroundColorDark = Color.fromARGB(255, 34, 34, 34);
  static const Color success = Color(0xFF37B954);
  static const Color dangerColor = Color(0xFFFF0606);
  static const Color secondaryDanger = Color(0xFFF4E1E1);
  static const Color warningColor = Color(0xFFFF9A0C);
  static const Color secondaryWarning = Color.fromARGB(255, 226, 205, 174);
  static const Color thirdaryColor = Color.fromARGB(255, 235, 232, 228);
  static const Color disable = Color.fromARGB(255, 116, 115, 114);

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.purple.shade50],
      );

  static LinearGradient get surfaceDarkGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceDark, Color.fromARGB(255, 50, 30, 60)],
      );

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        // ignore: deprecated_member_use
        background: backgroundColor,
        error: dangerColor,
      ),
      textTheme: _buildNiradeiTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.black, displayColor: Colors.black),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Make background transparent
        elevation: 0,
        shadowColor: Color.fromARGB(66, 50, 49, 49),
        titleTextStyle: TextStyle(
          fontFamily: 'niradei',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        // ignore: deprecated_member_use
        background: backgroundColorDark,
        error: dangerColor,
      ),
      textTheme: _buildNiradeiTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'niradei',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static TextTheme _buildNiradeiTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'niradei',
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'niradei',
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'niradei',
        fontWeight: FontWeight.w700,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'niradei',
        fontWeight: FontWeight.w700,
      ),
      titleMedium: const TextStyle(fontFamily: 'niradei'),
      titleSmall: const TextStyle(fontFamily: 'niradei'),
      bodyLarge: const TextStyle(fontFamily: 'niradei'),
      bodyMedium: const TextStyle(fontFamily: 'niradei'),
      bodySmall: const TextStyle(fontFamily: 'niradei'),
      labelLarge: const TextStyle(fontFamily: 'niradei'),
      labelMedium: const TextStyle(fontFamily: 'niradei'),
      labelSmall: const TextStyle(fontFamily: 'niradei'),
    );
  }
}
