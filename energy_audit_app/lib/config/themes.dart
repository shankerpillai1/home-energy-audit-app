import 'package:flutter/material.dart';

class AppThemes {
  /// Commercial SIM-style light theme for Flutter 3+
  static final light = ThemeData(
    // Use explicit ColorScheme constructor for full control
    colorScheme: const ColorScheme(
      brightness: Brightness.light,        // Light mode
      primary: Color(0xFF0066CC),          // Main brand color
      onPrimary: Colors.white,             // Text/icon color on primary
      secondary: Color(0xFF00CC99),        // Accent color
      onSecondary: Colors.white,           // Text/icon on accent
      surface: Color(0xFFFFFFFF),          // Card/Sheet backgrounds
      onSurface: Color(0xFF222222),        // Text on surfaces
      error: Color(0xFFCC0000),            // Error color
      onError: Colors.white,               // Text on error backgrounds
    ),

    // Text styles using new Flutter 3 naming
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ), // Primary large headings
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ), // Section titles
      bodyLarge: TextStyle(
        fontSize: 14,
      ), // Main body text
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ), // Button and label text
    ),

    // ElevatedButton global style
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Input fields decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      filled: true,
      fillColor: const Color(0xFFEFEFEF),
    ),

    // AppBar styling
    appBarTheme: const AppBarTheme(
      elevation: 1,
      centerTitle: true,
      backgroundColor: Color(0xFF0066CC),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),

    // Scaffold background
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    // Platform adaptive density
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
