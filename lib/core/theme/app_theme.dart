import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF10B981);
  static const Color secondaryColor = Color.fromARGB(255, 66, 255, 192);
  static const Color backgroundColor = Color.fromARGB(255, 245, 245, 245);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color.fromARGB(255, 40, 40, 40);
  static const Color backgroundColorDark = Color.fromARGB(255, 41, 40, 40);
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
      textTheme: _buildKantumruyProTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.black, displayColor: Colors.black),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Color.fromARGB(66, 50, 49, 49),
        titleTextStyle: TextStyle(
          fontFamily: 'KantumruyPro',
          fontSize: 20,
          fontWeight: FontWeight.w800,
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
      textTheme: _buildKantumruyProTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'KantumruyPro',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static TextTheme _buildKantumruyProTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'KantumruyPro',
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'KantumruyPro',
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'KantumruyPro',
        fontWeight: FontWeight.w800,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'KantumruyPro',
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(fontFamily: 'KantumruyPro'),
      titleSmall: const TextStyle(fontFamily: 'KantumruyPro'),
      bodyLarge: const TextStyle(fontFamily: 'KantumruyPro'),
      bodyMedium: const TextStyle(fontFamily: 'KantumruyPro'),
      bodySmall: const TextStyle(fontFamily: 'KantumruyPro'),
      labelLarge: const TextStyle(fontFamily: 'KantumruyPro'),
      labelMedium: const TextStyle(fontFamily: 'KantumruyPro'),
      labelSmall: const TextStyle(fontFamily: 'KantumruyPro'),
    );
  }
}
