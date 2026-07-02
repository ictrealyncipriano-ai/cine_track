import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primary = Color(0xFFFFC107);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _primary,
        surface: Color(0xFF161B22),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1117),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161B22),
        selectedItemColor: _primary,
        unselectedItemColor: Colors.white38,
      ),
      cardColor: const Color(0xFF161B22),
      dividerColor: Colors.white12,
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _primary,
        surface: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        foregroundColor: Color(0xFF1F1F1F),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFFB8860B),
        unselectedItemColor: Colors.black38,
      ),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: Colors.black12,
    );
  }
}
