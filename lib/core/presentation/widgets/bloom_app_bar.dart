import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/presentation/screens/about_screen.dart';
import 'package:bloomsafe/core/presentation/screens/privacy_policy_screen.dart';
import 'package:bloomsafe/core/presentation/screens/feedback_screen.dart';

/// A consistent app bar widget for use across the application
class BloomAppBar extends StatelessWidget implements PreferredSizeWidget {

  /// Creates a new BloomAppBar
  const BloomAppBar({
    super.key,
    this.showBackButton = false,
    this.actions,
    this.onBackPressed,
    this.transparentMode = false,
  });
  /// Optional actions to display
  final List<Widget>? actions;

  /// Optional callback for when back button is pressed
  final VoidCallback? onBackPressed;

  /// Whether to show a back button
  final bool showBackButton;

  /// Whether to show a transparent app bar with only the more options button
  final bool transparentMode;

  @override
  Widget build(BuildContext context) {
    // If in transparent mode, just return the more options button in an empty app bar
    if (transparentMode) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        // Set status bar to dark icons (black) consistently
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: primaryColor),
            onPressed: () {
              // Show more options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildMoreOptionsMenu(context),
              );
            },
          ),
        ],
      );
    }

    // Standard AppBar
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 4,
      centerTitle: true,
      // Set status bar to dark icons (black) consistently
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(
              'assets/images/bloomsafe_logo_outline.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: spacingSmall),
          // App name
          const Text(
            'BloomSafe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions:
          actions ??
          [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Show more options menu
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildMoreOptionsMenu(context),
                );
              },
            ),
          ],
    );
  }

  Widget _buildMoreOptionsMenu(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              size: 28,
              color: primaryColor,
            ),
            title: const Text(aboutBloomSafeText, style: bodyStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.shield_outlined,
              size: 28,
              color: primaryColor,
            ),
            title: const Text(privacyPolicyText, style: bodyStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.rate_review_outlined,
              size: 28,
              color: primaryColor,
            ),
            title: const Text(sendFeedbackText, style: bodyStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
