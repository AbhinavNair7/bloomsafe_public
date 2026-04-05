import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';

/// Screen displaying information about the BloomSafe app
class AboutScreen extends StatelessWidget {
  /// Creates a new AboutScreen
  const AboutScreen({super.key});

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
            const SizedBox(height: spacingMedium),

            // App logo
            Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/bloomsafe_logo.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ),

            const SizedBox(height: spacingLarge),

            // App information
            const Center(child: Text(appTitle, style: headingStyle)),

            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: spacingSmall),
                child: Text('Version 1.0.0', style: secondaryStyle),
              ),
            ),

            const SizedBox(height: spacingLarge * 1.5),

            // About BloomSafe content
            _buildSection(
              title: 'Our Mission',
              content:
                  'To empower women from pre-conception to birth to protect their reproductive health from environmental pollutants.',
            ),

            _buildSection(
              title: 'Our Vision',
              content:
                  'To build a world where women can avoid environmental hazards and have better reproductive health outcomes.',
            ),

            _buildSection(
              title: 'What We Do',
              content:
                  'BloomSafe provides real-time information about PM2.5 air quality levels in your area, specifically designed for women who are trying to conceive or are pregnant. By simply entering your zip code, you can receive:\n\n• Current PM2.5 Air Quality Index (AQI) levels\n• Severity assessment on our specialized reproductive health scale\n• Personalized recommendations based on air quality conditions\n• Educational resources on environmental impacts on fertility and pregnancy',
            ),

            _buildSection(
              title: 'Why It Matters',
              content:
                  'Research suggests that exposure to air pollution, particularly fine particulate matter (PM2.5), may impact fertility and pregnancy outcomes. BloomSafe empowers you with knowledge to make informed decisions about your environmental exposure during this critical time.',
            ),

            _buildSection(
              title: 'Data Accuracy & Timeliness',
              content:
                  'BloomSafe displays the most recent available PM2.5 data from AirNow.gov. '
                  'Readings update hourly and reflect measurements from the previous hour '
                  '(e.g., a 7:00 PM timestamp indicates data collected between 6:00-6:59 PM). '
                  'This slight delay ensures measurement accuracy and system processing time.',
            ),

            // Terms of Service section
            _buildTermsOfService(),

            const SizedBox(height: spacingLarge),

            const SizedBox(height: spacingMedium),
          ],
        ),
      ),
    );
  }

  /// Builds a section with title and content
  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: subheadingStyle.copyWith(color: primaryColor)),

        Container(
          height: 3,
          width: 60,
          margin: const EdgeInsets.only(
            top: spacingSmall,
            bottom: spacingMedium,
          ),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),

        Text(content, style: bodyStyle.copyWith(height: 1.5)),

        const SizedBox(height: spacingLarge),
      ],
    );
  }

  /// Builds the Terms of Service section
  Widget _buildTermsOfService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms of Service',
          style: subheadingStyle.copyWith(color: primaryColor, fontSize: 22),
        ),

        Container(
          height: 3,
          width: 100,
          margin: const EdgeInsets.only(
            top: spacingSmall,
            bottom: spacingMedium,
          ),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),

        const Text('Last Updated: May 7, 2025', style: secondaryStyle),

        const SizedBox(height: spacingLarge),

        _buildTermsSection(
          title: '1. Acceptance of Terms',
          content:
              'By downloading, installing, or using the BloomSafe application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you should not use the App.',
        ),

        _buildTermsSection(
          title: '2. App Description',
          content:
              'BloomSafe is a wellness information tool that provides air quality data and general educational content related to environmental factors and reproductive health. The App allows users to check PM2.5-specific air quality levels by entering their zip code.',
        ),

        _buildTermsSection(
          title: '3. Not Medical Advice',
          content:
              'IMPORTANT HEALTH DISCLAIMER: BloomSafe is a wellness information app, not a medical device or service. BloomSafe is classified as a general wellness product under FDA guidelines. The information provided by the App is for informational and educational purposes only and is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified healthcare provider with any questions you may have regarding a medical condition or health objectives. Never disregard professional medical advice or delay in seeking it because of something you have read or seen in this App.',
        ),

        _buildTermsSection(
          title: '4. App Usage',
          content:
              'You agree to use the App only for lawful purposes and in accordance with these Terms. You may not:\n• Use the App in any way that violates applicable laws or regulations\n• Attempt to gain unauthorized access to any portion of the App or any systems or networks connected to the App\n• Use any automated means to access or collect data from the App\n• Interfere with the proper working of the App\n• Circumvent, disable, or otherwise interfere with security-related features of the App',
        ),

        _buildTermsSection(
          title: '5. Intellectual Property',
          content:
              'The App, including all content, features, and functionality, is owned by BloomSafe and is protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store, or transmit any materials from the App without our prior written consent.',
        ),

        _buildTermsSection(
          title: '6. Privacy',
          content:
              'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect information that you provide to us through the App. By using the App, you consent to the data practices described in our Privacy Policy.',
        ),

        _buildTermsSection(
          title: '7. Third-Party Content and Services',
          content:
              'The App may display content from third parties, including AirNow API data. We are not responsible for the accuracy, reliability, or availability of third-party content or services. Your use of third-party content or services may be subject to additional terms and conditions.\n\nFirebase Analytics data collection follows Google\'s standard analytics terms.',
        ),

        _buildTermsSection(
          title: '8. Limitations of Liability',
          content:
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL BLOOMSAFE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM (i) YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APP; (ii) ANY CONDUCT OR CONTENT OF ANY THIRD PARTY ON THE APP; (iii) ANY CONTENT OBTAINED FROM THE APP; AND (iv) UNAUTHORIZED ACCESS, USE, OR ALTERATION OF YOUR TRANSMISSIONS OR CONTENT, WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), OR ANY OTHER LEGAL THEORY, WHETHER OR NOT WE HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE.',
        ),

        _buildTermsSection(
          title: '9. Indemnification',
          content:
              'You agree to defend, indemnify, and hold harmless BloomSafe and its affiliates from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses, or fees (including reasonable attorneys\' fees) arising out of or relating to your violation of these Terms or your use of the App.',
        ),

        _buildTermsSection(
          title: '10. Modification of Terms',
          content:
              'We reserve the right to modify these Terms at any time. Updated Terms will be posted within the App and will be effective immediately upon posting. Your continued use of the App after any modifications indicates your acceptance of the modified Terms.',
        ),

        _buildTermsSection(
          title: '11. Termination',
          content:
              'We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the App will immediately cease.',
        ),

        _buildTermsSection(
          title: '12. Governing Law',
          content:
              'These Terms shall be governed by California law, excluding conflict of law provisions.',
        ),

        _buildTermsSection(
          title: '13. Support Status',
          content:
              'BloomSafe is no longer actively distributed or supported. This repository preserves the shipped MVP for reference.',
        ),
      ],
    );
  }

  /// Builds a section of the Terms of Service
  Widget _buildTermsSection({
    required String title,
    required String content,
    bool isImportant = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: bodyStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: isImportant ? accentColor : null,
          ),
        ),

        const SizedBox(height: spacingSmall),

        Text(
          content,
          style: bodyStyle.copyWith(
            height: 1.5,
            fontWeight: isImportant ? FontWeight.w500 : null,
            color: isImportant ? accentColor : null,
          ),
        ),

        const SizedBox(height: spacingLarge),
      ],
    );
  }
}
