import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';

/// Thrown when the API returns no data for a requested zipcode
class NoDataForZipcodeException extends ApiException {
  NoDataForZipcodeException(super.message);
}

/// Thrown when the zipcode format is invalid
class InvalidZipcodeException extends ApiException {
  InvalidZipcodeException(super.message);
}

/// Thrown for general AQI-related errors
class AQIException extends ApiException {
  AQIException(super.message);
}
