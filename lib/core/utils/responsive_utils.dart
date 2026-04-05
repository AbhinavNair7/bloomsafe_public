import 'package:flutter/material.dart';

/// A utility class for responsive design across different screen sizes
class ResponsiveUtils {
  // Base device dimensions - iPhone 16 Pro
  static const double baseWidth = 393.0;
  static const double baseHeight = 852.0;

  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Calculate horizontal scale factor based on width
  static double getWidthScaleFactor(BuildContext context) {
    final double screenWidth = getScreenWidth(context);
    return screenWidth / baseWidth;
  }

  // Calculate vertical scale factor based on height
  static double getHeightScaleFactor(BuildContext context) {
    final double screenHeight = getScreenHeight(context);
    return screenHeight / baseHeight;
  }

  // Scale width dimension
  static double scaleWidth(BuildContext context, double width) {
    return width * getWidthScaleFactor(context);
  }

  // Scale height dimension
  static double scaleHeight(BuildContext context, double height) {
    return height * getHeightScaleFactor(context);
  }

  // Scale text (with minimum and maximum bounds for readability)
  static double scaleText(BuildContext context, double fontSize) {
    final double scaleFactor = getWidthScaleFactor(context);
    final double scaledSize = fontSize * scaleFactor;

    // Ensure text doesn't get too small or too large
    return scaledSize.clamp(fontSize * 0.8, fontSize * 1.2);
  }

  // Scale padding/margin (with minimum to ensure elements don't touch)
  static double scaleSpacing(BuildContext context, double spacing) {
    final double scaleFactor = getWidthScaleFactor(context);
    return (spacing * scaleFactor).clamp(spacing * 0.7, spacing * 1.3);
  }

  // Check if device is small
  static bool isSmallDevice(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  // Check if device is medium
  static bool isMediumDevice(BuildContext context) {
    final double width = getScreenWidth(context);
    return width >= 360 && width < 400;
  }

  // Check if device is large
  static bool isLargeDevice(BuildContext context) {
    final double width = getScreenWidth(context);
    return width >= 400;
  }

  // Get appropriate padding based on screen size
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double small = 8.0,
    double medium = 16.0,
    double large = 24.0,
  }) {
    if (isSmallDevice(context)) {
      return EdgeInsets.all(small);
    } else if (isMediumDevice(context)) {
      return EdgeInsets.all(medium);
    } else {
      return EdgeInsets.all(large);
    }
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Get responsive horizontal spacing
  static SizedBox horizontalSpace(BuildContext context, double width) {
    return SizedBox(width: scaleWidth(context, width));
  }

  // Get responsive vertical spacing
  static SizedBox verticalSpace(BuildContext context, double height) {
    return SizedBox(height: scaleHeight(context, height));
  }
}
