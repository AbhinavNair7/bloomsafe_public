import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';

/// A standardized content card widget used across the app
class ContentCard extends StatelessWidget {

  /// Creates a new ContentCard widget
  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(spacingMedium),
    this.margin = const EdgeInsets.only(bottom: spacingMedium),
    this.borderColor = secondaryColor,
    this.backgroundColor = neutralWhite,
  });
  /// The child widget to display inside the card
  final Widget child;

  /// Optional padding for the card content
  final EdgeInsetsGeometry padding;

  /// Optional margin for the card
  final EdgeInsetsGeometry margin;

  /// Optional border color
  final Color borderColor;

  /// Optional background color
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(contentCardBorderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
