import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';

/// App theme configuration
class AppTheme {
  /// Get the light theme
  static ThemeData getLightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: neutralWhite,
      ),
      fontFamily: 'System',
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputFieldBorderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
      ),
    );
  }
}
