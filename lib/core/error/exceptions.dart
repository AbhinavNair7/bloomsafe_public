/// Base class for all application exceptions
class AppException implements Exception {
  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exception for general application errors
class GeneralException extends AppException {
  GeneralException(super.message);
}

/// Exception for validation errors in the application
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Exception for security-related errors
class SecurityException extends AppException {
  SecurityException(super.message);
}

/// Exception for file operation errors
class FileOperationException extends AppException {
  FileOperationException(super.message);
}

/// Exception for configuration errors
class ConfigurationException extends AppException {
  ConfigurationException(super.message);
}

/// Exception for data parsing errors
class DataParsingException extends AppException {
  DataParsingException(super.message);
}

/// Exception for cache-related errors
class CacheException extends AppException {
  CacheException(super.message);
}
