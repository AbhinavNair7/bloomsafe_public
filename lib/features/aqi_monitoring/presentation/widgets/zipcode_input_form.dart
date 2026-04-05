import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/validation_utils.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';

// UI Constants specific to this widget
const double baseLoaderSize = 24.0;
const double baseLoaderStrokeWidth = 2.0;

/// A form widget for zipcode input with validation
class ZipcodeInputForm extends StatefulWidget {

  /// Creates a new ZipcodeInputForm widget
  const ZipcodeInputForm({super.key, this.onSubmitted});
  /// Callback that's called when a valid zipcode is submitted
  final Function(String)? onSubmitted;

  @override
  State<ZipcodeInputForm> createState() => _ZipcodeInputFormState();
}

class _ZipcodeInputFormState extends State<ZipcodeInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _zipcodeController = TextEditingController();
  final _connectivityService = ConnectivityService();
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;
  String? _validationError;

  @override
  void dispose() {
    _zipcodeController.dispose();
    super.dispose();
  }

  /// Validates the zipcode input using the AQI validation utilities
  String? _validateZipcode(String? value) {
    return AQIValidationUtils.validateZipCode(value);
  }

  /// Updates validation status but doesn't show error messages during typing
  void _onZipcodeChanged(String value) {
    final error = AQIValidationUtils.validateZipCode(value);

    setState(() {
      _validationError = error;
      // Only update the UI if we've already attempted to submit once
      if (_hasAttemptedSubmit) {
        _formKey.currentState?.validate();
      }
    });
  }

  /// Handles the form submission
  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Check for internet connectivity before proceeding
    final hasConnection =
        await _connectivityService.hasInternetConnectionWithTimeout();

    // Check if widget is still in the tree before using context
    if (!mounted) return;

    if (!hasConnection) {
      // Show no internet connection error
      final provider = Provider.of<AQIProvider>(context, listen: false);
      provider.setError(noInternetConnectionMessage);
      return;
    }

    final zipcode = _zipcodeController.text;

    setState(() {
      _isSubmitting = true;
    });

    if (widget.onSubmitted != null) {
      widget.onSubmitted!(zipcode);
    } else {
      // Default behavior - use provider to fetch data
      final provider = Provider.of<AQIProvider>(context, listen: false);
      await provider.fetchData(zipcode);

      // Check if widget is still in the tree
      if (!mounted) return;
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  /// Builds an input border with the given color and width
  OutlineInputBorder _buildBorder({
    required Color color,
    double width = inputFieldBorderWidth,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.scaleWidth(context, inputFieldBorderRadius),
      ),
      borderSide: BorderSide(
        color: color,
        width: ResponsiveUtils.scaleWidth(context, width),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for updates from provider
    final provider = Provider.of<AQIProvider>(context);
    final isLoading = _isSubmitting || provider.isLoading;

    // Get the border color based on validation state
    Color borderColor = Colors.grey;
    if (_hasAttemptedSubmit && _validationError != null) {
      if (_validationError == invalidZipCodeLengthError) {
        borderColor = warningColor;
      } else if (_validationError == nonNumericZipCodeError) {
        borderColor = errorColor;
      }
    }

    return Form(
      key: _formKey,
      autovalidateMode:
          _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zipcode input field
          TextFormField(
            controller: _zipcodeController,
            decoration: InputDecoration(
              labelText: zipCodeInputLabel,
              hintText: zipCodeInputHint,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: _buildBorder(color: Colors.grey),
              enabledBorder: _buildBorder(color: borderColor),
              focusedBorder: _buildBorder(
                color: primaryColor,
                width: inputFieldBorderWidth * 2,
              ),
              errorBorder: _buildBorder(color: errorColor),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
                vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
              ),
              counterText: '',
              labelStyle: TextStyle(
                fontSize: ResponsiveUtils.scaleText(context, 16),
              ),
              hintStyle: TextStyle(
                fontSize: ResponsiveUtils.scaleText(context, 14),
                color: Colors.grey,
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveUtils.scaleText(context, bodyStyle.fontSize!),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 5,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: _onZipcodeChanged,
            validator: _validateZipcode,
            onFieldSubmitted: (_) {
              // Hide keyboard first
              FocusScope.of(context).unfocus();
              _submitForm();
            },
            enabled: !isLoading,
          ),

          // Fixed height container for error messages to prevent layout shifts
          Container(
            constraints: BoxConstraints(
              minHeight: ResponsiveUtils.scaleHeight(context, 32),
            ),
            alignment: Alignment.centerLeft,
            child:
                provider.error != null && _hasAttemptedSubmit
                    ? _buildErrorMessage(provider.error!)
                    : null,
          ),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

          // Submit button
          _buildSubmitButton(isLoading),
        ],
      ),
    );
  }

  /// Builds the error message widget
  Widget _buildErrorMessage(String errorText) {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveUtils.scaleHeight(context, spacingSmall),
        left: ResponsiveUtils.scaleWidth(context, spacingSmall),
      ),
      child: Text(
        errorText,
        style: errorTextStyle.copyWith(
          fontSize: ResponsiveUtils.scaleText(
            context,
            errorTextStyle.fontSize!,
          ),
        ),
      ),
    );
  }

  /// Builds the submit button with loading state
  Widget _buildSubmitButton(bool isLoading) {
    final double buttonHeightScaled = ResponsiveUtils.scaleHeight(
      context,
      buttonHeight,
    );
    final double loaderSize = ResponsiveUtils.scaleWidth(
      context,
      baseLoaderSize,
    );

    return SizedBox(
      height: buttonHeightScaled,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.scaleWidth(context, buttonBorderRadius),
            ),
          ),
          minimumSize: Size.fromHeight(buttonHeightScaled),
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.scaleHeight(context, paddingCompact),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: loaderSize,
                  height: loaderSize,
                  child: CircularProgressIndicator(
                    strokeWidth: ResponsiveUtils.scaleWidth(
                      context,
                      baseLoaderStrokeWidth,
                    ),
                    color: Colors.white,
                  ),
                )
                : Text(
                  checkAirQualityButtonText,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaleText(context, fontSizeBody),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
      ),
    );
  }
}
