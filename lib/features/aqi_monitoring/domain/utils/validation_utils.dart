import 'package:bloomsafe/core/constants/strings.dart';

/// A class representing the result of a validation operation
class ValidationResult {

  ValidationResult({required this.isValid, this.message, this.normalizedValue});
  final bool isValid;
  final String? message;
  final String? normalizedValue;
}

/// AQI-specific validation utilities for the domain layer
class AQIValidationUtils {
  /// Validates a US ZIP code format for AQI lookup
  ///
  /// Returns null if valid, or an error message string if invalid
  static String? validateZipCode(String? zipCode) {
    // Check for null or empty
    if (zipCode == null || zipCode.isEmpty) {
      return emptyZipCodeError;
    }

    // Check for length
    if (zipCode.length != 5) {
      return invalidZipCodeLengthError;
    }

    // Check format (5 digits)
    final zipRegex = RegExp(r'^\d{5}$');
    if (!zipRegex.hasMatch(zipCode)) {
      return nonNumericZipCodeError;
    }

    return null;
  }

  /// Validates a ZIP code strictly for API usage
  ///
  /// Similar to validateZipCode but returns a boolean result
  /// to better match API validation paradigms
  static bool isValidZipCodeForApi(String? zipCode) {
    final validationResult = validateZipCode(zipCode);
    return validationResult == null;
  }

  /// Normalizes a ZIP code by trimming whitespace
  ///
  /// Useful for user input processing before validation
  static String normalizeZipCode(String zipCode) {
    return zipCode.trim();
  }

  /// Creates a validation result object containing both validity status and message
  ///
  /// This is useful for contexts where both the validation state and message are needed
  static ValidationResult validateZipCodeWithResult(String? zipCode) {
    // First normalize if not null
    final normalized = zipCode != null ? normalizeZipCode(zipCode) : null;

    // Then validate the normalized value
    final errorMessage = validateZipCode(normalized);

    return ValidationResult(
      isValid: errorMessage == null,
      message: errorMessage,
      normalizedValue: normalized,
    );
  }
}
