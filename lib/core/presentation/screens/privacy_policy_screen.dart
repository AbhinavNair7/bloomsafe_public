import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';

/// Screen displaying the Privacy Policy
class PrivacyPolicyScreen extends StatelessWidget {
  /// Creates a new PrivacyPolicyScreen
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: const BloomAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with decorative element
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(privacyPolicyText, style: headingStyle),

                  const SizedBox(height: spacingSmall),

                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),

                  const SizedBox(height: spacingMedium),

                  const Text(
                    'Last updated: May 7, 2025',
                    style: secondaryStyle,
                  ),
                ],
              ),
            ),

            _buildPolicySection(
              title: '1. Introduction',
              content:
                  'BloomSafe ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application BloomSafe (the "App").\n\nPlease read this Privacy Policy carefully. By using the App, you agree to the collection and use of information in accordance with this policy.',
            ),

            _buildPolicySection(
              title: '2. Information We Collect',
              content:
                  '2.1 Information You Provide\nWe collect information that you voluntarily provide when using our App:\n• Zip Codes: When you enter a zip code to check air quality, we temporarily process this information to retrieve relevant AQI data.\n• Feedback: If you choose to submit feedback through the App, we collect the information you provide, such as your comments and feedback category selection.\n\n2.2 Information Collected Automatically\nWhen you use our App, we may automatically collect certain information:\n• Usage Data: We collect anonymous usage data via Firebase Analytics, including how you interact with the App, which features you use, and the frequency of use.\n• Device Information: We may collect information about your mobile device, including device type, operating system, unique device identifiers, mobile network information, and device settings.\n• Performance Data: We collect data related to App performance, such as crash reports and system activity.',
            ),

            _buildPolicySection(
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect for various purposes:\n• To provide and maintain the App\n• To retrieve air quality data based on provided zip codes\n• To improve the App\'s functionality and user experience\n• To monitor and analyze usage patterns and trends\n• To detect, prevent, and address technical issues\n• To respond to your feedback and inquiries',
            ),

            _buildPolicySection(
              title: '4. Data Storage and Security',
              content:
                  '4.1 Local Storage\n• Zip Code Data: Zip codes you enter are only used for immediate processing and are not permanently stored.\n• Cached Data: AQI results are temporarily cached locally on your device for up to 2 hours to improve performance and reduce unnecessary API calls.\n• No Cloud Storage: We do not store your personal data on cloud servers.\n\n4.2 Security Measures\nWe implement appropriate technical and organizational security measures to protect your information, including:\n• AES-256 encryption for sensitive data\n• Secure local storage using platform-specific implementations (iOS Keychain with first_unlock accessibility, Android EncryptedSharedPreferences)\n• HTTPS enforcement and certificate pinning for all network communications\n• Detection of compromised/rooted devices',
            ),

            _buildPolicySection(
              title: '5. Third-Party Services',
              content:
                  'We use the following third-party services in our App:\n\n5.1 AirNow API\nWe use the AirNow API to retrieve air quality data based on the zip code you provide. Your zip code is sent to AirNow to process this request. Please review AirNow\'s privacy policy for more information on how they handle data.',
              children: [
                const SizedBox(height: spacingMedium),
                const Text('5.2 Firebase Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text(
                  'We use Firebase Analytics to collect anonymous usage data to help us understand how users interact with our App. Firebase Analytics may collect device information and App usage statistics. This information is used in an aggregated format following Firebase\'s Data Processing Terms. Please review Google\'s privacy policy for more information on how Firebase handles data.',
                  style: bodyStyle,
                ),
                const SizedBox(height: spacingMedium),
                const Text('5.3 Discord Webhook (for Feedback)', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text(
                  'When you submit feedback through the App, we process this information through a Discord webhook. Your feedback is not associated with any personal identifiers unless you specifically include them in your message.',
                  style: bodyStyle,
                ),
              ],
            ),

            _buildPolicySection(
              title: '6. Your Privacy Rights',
              content:
                  '6.1 Access and Control\n• You can stop all collection of information by the App by uninstalling the App from your device.\n• To opt out of analytics, uninstall the app. An in-app toggle will be available in future updates.\n\n6.2 Data Retention\nWe retain information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy. Cached AQI data is automatically deleted after 2 hours. Firebase Analytics anonymised user data maybe retained for up to 2-14 months before automatic deletion.\n\n6.3 Children\'s Privacy\nThe App is not directed to anyone under the age of 16. We do not knowingly collect personally identifiable information from children under 16. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us.',
            ),

            _buildPolicySection(
              title: '7. Changes to This Privacy Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App and updating the "Last Updated" date at the top of this policy. You are advised to review this Privacy Policy periodically for any changes.',
            ),

            _buildPolicySection(
              title: '8. Support Status',
              content:
                  'BloomSafe is no longer actively distributed or supported. This repository preserves the shipped MVP for reference.\n\nBy using the App, you acknowledge that you have read and understand this Privacy Policy.\n',
              isLast: true,
            ),

            const SizedBox(height: spacingLarge),

            const SizedBox(height: spacingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
    bool isLast = false,
    List<Widget> children = const [],
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: subheadingStyle.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: spacingMedium),

          Text(content, style: bodyStyle.copyWith(height: 1.5)),

          ...children,
        ],
      ),
    );
  }
}
