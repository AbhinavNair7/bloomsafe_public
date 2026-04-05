import 'package:bloomsafe/core/constants/strings.dart';

// Error Types
enum ApiErrorType {
  connection, // General API connection errors
  validation, // Validation errors like invalid zipcode
  rateLimit, // Rate limit errors (10 requests per minute)
  network, // Network connectivity issues
}

// Error Response Mapping
const Map<ApiErrorType, String> errorMessages = {
  ApiErrorType.connection: apiConnectionErrorMessage,
  ApiErrorType.validation: invalidZipCodeLengthError,
  ApiErrorType.rateLimit: maxSearchesReachedMessage,
  ApiErrorType.network: noInternetConnectionMessage,
};

// Validation Regular Expressions
const String zipCodeRegexPattern = r'^[0-9]{5}$';
