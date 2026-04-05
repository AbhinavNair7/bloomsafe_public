import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// A utility class for responsive text styling across different screen sizes
class ResponsiveText {
  // Text styles with responsive scaling

  /// Regular text style with responsive sizing
  static TextStyle regular(
    BuildContext context, {
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: ResponsiveUtils.scaleText(context, fontSize),
      color: color,
      fontWeight: fontWeight ?? FontWeight.normal,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  /// Bold text style with responsive sizing
  static TextStyle bold(
    BuildContext context, {
    required double fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return regular(
      context,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  /// Medium text style with responsive sizing
  static TextStyle medium(
    BuildContext context, {
    required double fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return regular(
      context,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  /// Semi-bold text style with responsive sizing
  static TextStyle semiBold(
    BuildContext context, {
    required double fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return regular(
      context,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  // Predefined text styles

  /// Heading 1 style
  static TextStyle h1(BuildContext context, {Color? color}) {
    return bold(context, fontSize: 28.0, color: color, height: 1.2);
  }

  /// Heading 2 style
  static TextStyle h2(BuildContext context, {Color? color}) {
    return bold(context, fontSize: 24.0, color: color, height: 1.3);
  }

  /// Heading 3 style
  static TextStyle h3(BuildContext context, {Color? color}) {
    return semiBold(context, fontSize: 20.0, color: color, height: 1.4);
  }

  /// Subtitle style
  static TextStyle subtitle(BuildContext context, {Color? color}) {
    return medium(context, fontSize: 18.0, color: color, height: 1.4);
  }

  /// Body text style
  static TextStyle body(BuildContext context, {Color? color}) {
    return regular(context, fontSize: 16.0, color: color, height: 1.5);
  }

  /// Small text style
  static TextStyle small(BuildContext context, {Color? color}) {
    return regular(context, fontSize: 14.0, color: color, height: 1.5);
  }

  /// Caption text style
  static TextStyle caption(BuildContext context, {Color? color}) {
    return regular(context, fontSize: 12.0, color: color, height: 1.5);
  }
}
