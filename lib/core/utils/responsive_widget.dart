import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// A stateless widget that automatically scales based on screen size
class ResponsiveWidget extends StatelessWidget {

  /// Creates a responsive widget that provides scaling factors to its builder
  const ResponsiveWidget({super.key, required this.builder});
  final Widget Function(
    BuildContext context,
    double widthScale,
    double heightScale,
    double textScale,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    // Calculate scale factors
    final double widthScale = ResponsiveUtils.getWidthScaleFactor(context);
    final double heightScale = ResponsiveUtils.getHeightScaleFactor(context);
    final double textScale =
        widthScale; // Usually text scales with width but we could customize this

    // Call builder with scale factors
    return builder(context, widthScale, heightScale, textScale);
  }

  /// Creates a container with responsive dimensions
  static Widget container({
    required BuildContext context,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Alignment? alignment,
    Color? color,
    BoxDecoration? decoration,
    Widget? child,
  }) {
    return Container(
      width: width != null ? ResponsiveUtils.scaleWidth(context, width) : null,
      height:
          height != null ? ResponsiveUtils.scaleHeight(context, height) : null,
      margin: margin != null ? _scaleEdgeInsets(context, margin) : null,
      padding: padding != null ? _scaleEdgeInsets(context, padding) : null,
      alignment: alignment,
      color: color,
      decoration: decoration,
      child: child,
    );
  }

  /// Creates a SizedBox with responsive dimensions
  static Widget box({
    required BuildContext context,
    double? width,
    double? height,
    Widget? child,
  }) {
    return SizedBox(
      width: width != null ? ResponsiveUtils.scaleWidth(context, width) : null,
      height:
          height != null ? ResponsiveUtils.scaleHeight(context, height) : null,
      child: child,
    );
  }

  /// Creates responsive padding
  static Widget padding({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    Widget? child,
  }) {
    return Padding(padding: _scaleEdgeInsets(context, padding), child: child);
  }

  /// Creates responsive text
  static Widget text({
    required BuildContext context,
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    TextStyle? scaledStyle;
    if (style != null) {
      final double? fontSize = style.fontSize;
      scaledStyle = style.copyWith(
        fontSize:
            fontSize != null
                ? ResponsiveUtils.scaleText(context, fontSize)
                : null,
      );
    }

    return Text(
      text,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Helper method to scale EdgeInsets
  static EdgeInsetsGeometry _scaleEdgeInsets(
    BuildContext context,
    EdgeInsetsGeometry edgeInsets,
  ) {
    if (edgeInsets is EdgeInsets) {
      return EdgeInsets.only(
        left: ResponsiveUtils.scaleWidth(context, edgeInsets.left),
        top: ResponsiveUtils.scaleHeight(context, edgeInsets.top),
        right: ResponsiveUtils.scaleWidth(context, edgeInsets.right),
        bottom: ResponsiveUtils.scaleHeight(context, edgeInsets.bottom),
      );
    } else if (edgeInsets is EdgeInsetsDirectional) {
      return EdgeInsetsDirectional.only(
        start: ResponsiveUtils.scaleWidth(context, edgeInsets.start),
        top: ResponsiveUtils.scaleHeight(context, edgeInsets.top),
        end: ResponsiveUtils.scaleWidth(context, edgeInsets.end),
        bottom: ResponsiveUtils.scaleHeight(context, edgeInsets.bottom),
      );
    }
    return edgeInsets;
  }
}
