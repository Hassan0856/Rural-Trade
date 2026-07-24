import 'package:flutter/material.dart';

class AppTheme {
  // Earthy color palette
  static const Color earthBrown = Color(0xFF8B5A2B);
  static const Color earthGreen = Color(0xFF556B2F);
  static const Color earthBeige = Color(0xFFF5F5DC);
  static const Color earthTan = Color(0xFFD2B48C);
  static const Color earthDarkGreen = Color(0xFF2F4F4F);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: earthGreen,
        primary: earthGreen,
        secondary: earthBrown,
        surface: earthBeige,
      ),
      scaffoldBackgroundColor: earthBeige,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: earthGreen,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: earthGreen,
        unselectedItemColor: earthBrown,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: earthGreen,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: earthGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: earthGreen,
          side: const BorderSide(color: earthGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
