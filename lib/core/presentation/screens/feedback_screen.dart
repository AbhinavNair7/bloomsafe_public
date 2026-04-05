import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:bloomsafe/core/services/discord_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// Screen for users to send feedback about the app
class FeedbackScreen extends StatefulWidget {
  /// Creates a new FeedbackScreen
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedFeedbackType;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _feedbackTypes = [
    {
      'value': 'Bug Report',
      'icon': Icons.bug_report_outlined,
      'description': 'Report an issue or error in the app',
    },
    {
      'value': 'Feature Request',
      'icon': Icons.lightbulb_outline,
      'description': 'Suggest a new feature or improvement',
    },
    {
      'value': 'User Experience',
      'icon': Icons.touch_app_outlined,
      'description': 'Share thoughts about app usability',
    },
    {
      'value': 'Fertility or Pregnancy Information',
      'icon': Icons.favorite_outline,
      'description': 'Comment on health-related content',
    },
    {
      'value': 'General Feedback / Other',
      'icon': Icons.chat_outlined,
      'description': 'Any other thoughts or comments',
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: const BloomAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacingLarge),
        child: Form(
          key: _formKey,
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
                    const Text(sendFeedbackText, style: headingStyle),

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
                      'Help us improve BloomSafe by sharing your thoughts, reporting bugs, or suggesting new features.',
                      style: bodyStyle,
                    ),
                  ],
                ),
              ),

              // Feedback type dropdown
              _buildSectionTitle('Feedback Type'),

              _buildFeedbackTypeSelector(),

              const SizedBox(height: spacingLarge),

              // Feedback text field
              _buildSectionTitle('Your Feedback'),

              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 2.0,
                    ),
                  ),
                  hintText: 'Tell us what you think...',
                  contentPadding: const EdgeInsets.all(spacingMedium),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your feedback';
                  }
                  if (value.length < 10) {
                    return 'Feedback must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: spacingLarge),

              // Email field (optional)
              _buildSectionTitle('Your Email (Optional)'),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 2.0,
                    ),
                  ),
                  hintText: 'email@example.com',
                  contentPadding: const EdgeInsets.all(spacingMedium),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic email validation
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: spacingLarge * 1.5),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: spacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            submitFeedbackText,
                            style: TextStyle(fontSize: fontSizeBody),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a section title with consistent styling
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: spacingSmall),
      child: Text(title, style: subheadingStyle.copyWith(color: primaryColor)),
    );
  }

  /// Build a custom feedback type selector with improved UI/UX
  Widget _buildFeedbackTypeSelector() {
    return FormField<String>(
      initialValue: _selectedFeedbackType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a feedback type';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: state.hasError ? errorColor : Colors.grey.shade300,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children:
                    _feedbackTypes.map((type) {
                      final bool isSelected =
                          _selectedFeedbackType == type['value'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFeedbackType = type['value'];
                            state.didChange(type['value']);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                            border: Border(
                              bottom:
                                  type != _feedbackTypes.last
                                      ? BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      )
                                      : BorderSide.none,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacingMedium,
                            vertical: spacingMedium,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                color: isSelected ? primaryColor : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: spacingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['value'] as String,
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? primaryColor
                                                : Colors.black87,
                                        fontSize: fontSizeBody,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      type['description'] as String,
                                      style: const TextStyle(
                                        fontSize: fontSizeSecondary,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                  )
                                  : const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: errorColor, fontSize: 12.0),
                ),
              ),
          ],
        );
      },
    );
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final discordService = di.sl<DiscordService>();
      final hasWebhook = discordService.isWebhookConfigured();

      if (!hasWebhook) {
        // If webhook URL not configured, show error
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Discord webhook not configured. Please contact support.',
            ),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      // Send feedback to Discord
      final success = await discordService.sendFeedback(
        feedbackType: _selectedFeedbackType!,
        feedbackContent: _feedbackController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send feedback. Please try again later.'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }
}
