import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/core/constants/strings.dart';

/// Base class for all API-related exceptions
abstract class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Generic API exception for general API-related errors
class GenericApiException extends ApiException {
  GenericApiException(super.message);
}

/// Thrown when a network connectivity issue prevents API access
class NetworkException extends ApiException {
  NetworkException(super.message);
}

/// Thrown when the API returns no data for a requested zipcode
class NoDataForZipcodeException extends ApiException {
  NoDataForZipcodeException(super.message);
}

/// Thrown when the API rate limit is exceeded
class RateLimitException extends ApiException {

  RateLimitException(
    super.message, {
    this.type = RateLimitType.clientSide,
    this.remainingSeconds,
  });
  final RateLimitType type;
  final int? remainingSeconds;

  /// Get a user-friendly time remaining string
  String get timeRemainingText {
    if (remainingSeconds == null || remainingSeconds! <= 0) {
      return '';
    }

    final minutes = remainingSeconds! ~/ 60;
    final seconds = remainingSeconds! % 60;

    if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}';
    } else {
      return '$seconds second${seconds != 1 ? 's' : ''}';
    }
  }
}

/// Thrown when there's a server-side error with the API
class ServerException extends ApiException {
  ServerException(super.message);
}

/// Exception thrown for bad request errors (400 status code)
class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

/// Exception thrown for unauthorized errors (401 status code)
class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Unauthorized access']);
}

/// Exception thrown for forbidden errors (403 status code)
class ForbiddenException extends ApiException {
  ForbiddenException([super.message = 'Access forbidden']);
}

/// Exception thrown for not found errors (404 status code)
class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Resource not found']);
}

/// Exception thrown when the rate limit is exceeded (429 status code)
class RateLimitExceededException extends RateLimitException {
  RateLimitExceededException([
    super.message = 'Rate limit exceeded. Please try again later.',
    RateLimitType type = RateLimitType.clientSide,
    int? remainingSeconds,
  ]) : super(type: type, remainingSeconds: remainingSeconds);
}

/// Exception thrown for timeout errors
class TimeoutException extends ApiException {
  TimeoutException([super.message = apiConnectionErrorMessage]);
}

/// Exception thrown for connectivity errors
class ConnectivityException extends ApiException {
  ConnectivityException([super.message = 'No internet connection']);
}
