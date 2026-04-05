import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';

/// A reusable disclaimer widget that displays a medical disclaimer message
/// Used across the app to provide consistent messaging about the app being
/// for wellness information only and not medical advice
class DisclaimerWidget extends StatelessWidget {
  /// Creates a disclaimer widget
  const DisclaimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.scaleHeight(context, spacingSmall),
        horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
      ),
      child: Text(
        'For informational purposes only. Seek a healthcare professional for medical advice.',
        textAlign: TextAlign.center,
        style: secondaryStyle.copyWith(
          fontSize: ResponsiveUtils.scaleText(context, fontSizeSecondary - 1),
          color: Colors.black54,
        ),
      ),
    );
  }
}
