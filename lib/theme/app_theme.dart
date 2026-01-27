import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF09090B);
  static const Color bgCard = Color(0xFF18181B);
  static const Color primary = Color(0xFFCFFAFE); // Cyan 100
  static const Color accent = Color(0xFFA78BFA); // Violet 400
  static const Color textMain = Color(0xFFFAFAFA);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color borderLight = Color(0x1AFFFFFF); // 10% white
  static const Color bgLight = Color(0xFFF4F4F5); // Zinc 100
  static const Color border = Color(0xFFE4E4E7); // Zinc 200

  // Text Styles
  static const TextStyle headingMedium = TextStyle(
    color: bgDark,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Manrope',
  );

  static const TextStyle bodyLarge = TextStyle(
    color: bgDark,
    fontSize: 16,
    fontFamily: 'Manrope',
  );

  static const TextStyle bodyMedium = TextStyle(
    color: bgDark,
    fontSize: 14,
    fontFamily: 'Manrope',
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        onPrimary: bgDark,
        onSecondary: Colors.white,
        onSurface: textMain,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textMain, fontFamily: 'Manrope'),
        bodyMedium: TextStyle(color: textMain, fontFamily: 'Manrope'),
        bodySmall: TextStyle(color: textMuted, fontFamily: 'Manrope'),
        headlineLarge: TextStyle(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
        headlineMedium: TextStyle(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
        headlineSmall: TextStyle(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
        titleLarge: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
        titleMedium: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w500,
          fontFamily: 'Manrope',
        ),
        labelLarge: TextStyle(color: textMuted, fontFamily: 'Manrope'),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
        iconTheme: IconThemeData(color: textMain),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDark,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
