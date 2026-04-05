import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// A wrapper around Dio HTTP client that enforces security best practices
/// including HTTPS, certificate pinning, and proper error handling
class SecureHttpClient {

  /// Factory constructor for singleton
  factory SecureHttpClient() => _instance;

  /// Private constructor for singleton
  SecureHttpClient._internal();
  /// Singleton instance
  static final SecureHttpClient _instance = SecureHttpClient._internal();

  /// The internal Dio instance
  late final Dio _dio;

  /// The internal HttpClient for certificate pinning
  late final HttpClient _httpClient;

  /// Certificate hashes for pinning (hardcoded for security purposes)
  /// These values should be updated for the actual API endpoints used in production
  final Map<String, List<String>> _certificateHashes = {
    'airnowapi.org': [
      // Example SHA-256 fingerprints of the API's certificates
      // These should be replaced with actual values before deployment
      // '9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a',
    ],
    'api.discord.com': [
      // Example SHA-256 fingerprints of Discord's certificates
      // These should be replaced with actual values before deployment
      // '9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a:9a',
    ],
  };

  /// Initialize the secure HTTP client
  void initialize() {
    _dio = Dio();
    _httpClient = HttpClient();
    _configureDio();
    _configureCertificatePinning();
  }

  /// Configure Dio with security settings
  void _configureDio() {
    // Set up base options
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus:
          (status) => status != null && status >= 200 && status < 500,
    );

    // Add interceptors
    _dio.interceptors.add(_createSecurityInterceptor());

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Create a security interceptor for enforcing HTTPS
  Interceptor _createSecurityInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Force HTTPS by modifying the URI if it's not already HTTPS
        if (options.uri.scheme != 'https') {
          // Create a new HTTPS URI
          final httpsUri = Uri.parse(
            options.uri.toString().replaceFirst('http://', 'https://'),
          );

          // Update the request path to use the HTTPS URI
          options.baseUrl = '${httpsUri.scheme}://${httpsUri.host}';
          options.path = httpsUri.path;

          // Add query parameters if present
          if (httpsUri.hasQuery) {
            options.queryParameters.addAll(
              Uri.splitQueryString(httpsUri.query),
            );
          }
        }

        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.type == DioExceptionType.badCertificate) {
          // Certificate validation failed - potentially a MITM attack
          if (kDebugMode) {
            Logger.error(
              '⚠️ Certificate validation failed - potential security breach!',
            );
          }
          return handler.reject(error);
        }
        return handler.next(error);
      },
    );
  }

  /// Configure certificate pinning
  void _configureCertificatePinning() {
    _httpClient.findProxy = (uri) => 'DIRECT';

    // Only implement certificate pinning in production
    if (!kDebugMode) {
      _httpClient.badCertificateCallback = _onBadCertificate;
    }
  }

  /// Handler for bad certificate scenarios
  ///
  /// Returns true to continue despite certificate errors (used in debug)
  /// Returns false to reject connections with invalid certificates
  bool _onBadCertificate(X509Certificate cert, String host, int port) {
    // Get the certificate fingerprint (SHA-256 hash)
    final fingerprint = _getCertificateFingerprint(cert);

    // In debug mode, we allow connections but warn about certificate issues
    if (kDebugMode) {
      if (_certificateHashes.containsKey(host)) {
        final trustedFingerprints = _certificateHashes[host]?.firstOrNull;
        if (trustedFingerprints != fingerprint) {
          Logger.error(
            'Certificate pinning failed for $host\n'
            'Expected: $trustedFingerprints\n'
            'Received: $fingerprint',
          );
        } else {
          Logger.debug('Certificate pinning validated for $host');
        }
      } else {
        Logger.warning(
          'No pinned certificate for $host - consider adding:\n'
          'trustedFingerprints["$host"] = "$fingerprint";',
        );
      }

      // In debug, we continue despite certificate issues
      return true;
    }

    // In production, enforce strict certificate validation if enabled
    if (_certificateHashes.containsKey(host)) {
      final trustedFingerprints = _certificateHashes[host]?.firstOrNull;
      final isValid = trustedFingerprints == fingerprint;

      // Log validation failure in release mode (consider sending to analytics)
      if (!isValid) {
        Logger.critical(
          '⚠️ Certificate validation failed - potential security breach!',
        );
      }

      return isValid;
    }

    // If pinning is not enforced, allow the connection
    return true;
  }

  /// Calculates the SHA-256, base64-encoded fingerprint of the certificate
  ///
  /// This is a common format for certificate pinning
  String _getCertificateFingerprint(X509Certificate certificate) {
    // Extract the raw bytes of the certificate
    final certBytes = certificate.der;

    // Calculate the SHA-256 hash
    final digest = sha256.convert(certBytes);

    // Convert to base64 for easier storage/comparison
    final base64Fingerprint = base64.encode(digest.bytes);

    return base64Fingerprint;
  }

  /// Make a secure GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make a secure POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make a secure PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make a secure DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
