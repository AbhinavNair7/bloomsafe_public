import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';

// Font Family
const String fontFamily =
    'System'; // Uses San Francisco on iOS, Roboto on Android

// Font Sizes
const double fontSizeH1 = 24.0; // Main headings
const double fontSizeH2 = 20.0; // Secondary headings
const double fontSizeH3 = 18.0; // Small headings
const double fontSizeBody = 16.0; // Body text
const double fontSizeSecondary = 14.0; // Secondary information

// Line Heights
const double lineHeightMultiplier = 1.5;

// Text Styles
const TextStyle headingStyle = TextStyle(
  fontSize: fontSizeH1,
  fontWeight: FontWeight.bold,
  fontFamily: fontFamily,
  height: lineHeightMultiplier,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: fontSizeH2,
  fontWeight: FontWeight.w600,
  fontFamily: fontFamily,
  height: lineHeightMultiplier,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: fontSizeBody,
  fontFamily: fontFamily,
  height: lineHeightMultiplier,
);

const TextStyle secondaryStyle = TextStyle(
  fontSize: fontSizeSecondary,
  fontFamily: fontFamily,
  height: lineHeightMultiplier,
);

// Error Text Style
const TextStyle errorTextStyle = TextStyle(
  fontSize: fontSizeBody,
  color: errorColor,
  fontFamily: fontFamily,
  height: lineHeightMultiplier,
);
