import 'package:flutter/material.dart';

/// App theme configuration using blue, white, and black color palette
class AppTheme {
  // Color palette
  static const Color primaryBlue = Color(0xFF1976D2); // Medium blue
  static const Color darkBlue = Color(0xFF0D47A1); // Dark blue
  static const Color lightBlue = Color(0xFF42A5F5); // Light blue
  static const Color accentBlue = Color(0xFF2196F3); // Accent blue
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white
  static const Color textBlack = Color(0xFF212121); // Near black
  static const Color textGray = Color(0xFF757575); // Gray for secondary text
  static const Color successGreen = Color(0xFF4CAF50); // For correct answers
  static const Color errorRed = Color(0xFFF44336); // For incorrect answers

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceWhite,
        error: errorRed,
        onPrimary: surfaceWhite,
        onSecondary: surfaceWhite,
        onSurface: textBlack,
        onError: surfaceWhite,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: surfaceWhite,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: surfaceWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: surfaceWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: textGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: textGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textBlack,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textBlack,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textBlack,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textBlack,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textBlack,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textBlack,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textBlack,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textGray,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue.withOpacity(0.1),
        labelStyle: const TextStyle(color: textBlack),
        secondaryLabelStyle: const TextStyle(color: surfaceWhite),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
