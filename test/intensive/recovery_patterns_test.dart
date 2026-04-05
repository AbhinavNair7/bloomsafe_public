import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:bloomsafe/core/constants/api_endpoints.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';

/// Helper class for batch patterns
class _BatchPattern {

  _BatchPattern({
    required this.batchSize,
    required this.delayBetweenRequestsMs,
    required this.delayAfterBatchMs,
  });
  final int batchSize;
  final int delayBetweenRequestsMs;
  final int delayAfterBatchMs;

  @override
  String toString() =>
      'Batch size: $batchSize, '
      'Delay between requests: ${delayBetweenRequestsMs}ms, '
      'Delay after batch: ${delayAfterBatchMs}ms';
}

/// Test implementation of AppConfig for the test
class TestAppConfig implements AppConfig {
  bool _mockApiValue = false;
  String? _apiKeyValue = 'test_api_key';
  int _maxRequestsValue = 5;

  @override
  bool get useMockApi => _mockApiValue;

  @override
  String? get apiKey => _apiKeyValue;

  @override
  int get maxRequestsPerMinute => _maxRequestsValue;

  @override
  int get maxRequestsPerHour => 500;

  @override
  bool get disableRateLimit => false;

  void setMockApi(bool value) {
    _mockApiValue = value;
  }

  @override
  Future<bool> setApiKey(String apiKey) async {
    _apiKeyValue = apiKey;
    return true;
  }

  void setMaxRequests(int value) {
    _maxRequestsValue = value;
  }

  @override
  Future<void> initialize() async {
    // No-op for tests
    return Future.value();
  }

  @override
  Future<String?> getSecureApiKey() async {
    return _apiKeyValue;
  }

  @override
  bool toggleMockApi() {
    _mockApiValue = !_mockApiValue;
    return _mockApiValue;
  }

  @override
  void useMockApiMode() {
    _mockApiValue = true;
  }

  @override
  bool useRealApiMode() {
    _mockApiValue = false;
    return true;
  }

  @override
  Future<bool> useRealApiModeSecure() async {
    _mockApiValue = false;
    return true;
  }

  @override
  Future<void> useTestEnvironment({bool useTestEnv = true}) async {
    // Implementation for test environment setup
  }
}

/// This test examines how the AirNow API recovers after rate limiting events.
/// It tests exact recovery times, various request patterns, and partial recovery patterns.
///
/// DO NOT run this test regularly as it will consume significant API quota.
/// To run this test explicitly: flutter test test/intensive/recovery_patterns_test.dart --run-skipped
@Tags(['intensive'])
void main() {
  group('RECOVERY PATTERNS TEST - Testing API recovery after rate limiting', () {
    test(
      'Testing how the API recovers after rate limit events',
      () async {
        // Print instructions for running the test
        debugPrint('⚠️ Running intensive recovery patterns test');
        debugPrint(
          'This test consumes significant API quota and should only be run when specifically testing rate limiting',
        );

        final appConfig = AppConfig();
        await appConfig.initialize();

        // Create a plain Dio instance with minimal configuration
        final dio = Dio(
          BaseOptions(
            baseUrl: aqiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        // Add logging for debugging
        dio.interceptors.add(
          LogInterceptor(
            requestBody: false,
            responseBody: false,
            logPrint: (obj) => debugPrint(obj.toString()),
          ),
        );

        // Create an API client that bypasses the client-side rate limiter
        final testConfig = TestAppConfig();
        await testConfig.setApiKey(appConfig.apiKey ?? 'test_api_key');
        testConfig.setMaxRequests(100); // Very high to bypass client limits

        final apiClient = ApiClient.forTesting(dio: dio, appConfig: testConfig);

        // Reset the rate limiter to ensure clean test state
        RateLimiter.resetForTesting();
        apiClient.rateLimiter.setMaxRequestsForTest(100);

        // Test with multiple zip codes to distribute load
        final zipCodes = [
          '90210', // Beverly Hills, CA
          '10001', // New York, NY
          '60601', // Chicago, IL
          '77002', // Houston, TX
          '98101', // Seattle, WA
        ];

        // Create report file
        final directory = Directory('test/intensive/reports');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final resultsFile = File(
          'test/intensive/reports/recovery_patterns_results.txt',
        );
        final reportBuffer = StringBuffer();
        final testStartTime = DateTime.now();
        reportBuffer.writeln('RECOVERY PATTERNS TEST RESULTS');
        reportBuffer.writeln('==============================');
        reportBuffer.writeln('Test started at: $testStartTime\n');

        // Track test data
        int successCount = 0;
        int errorCount = 0;
        int rateLimitErrors = 0;
        String? rateLimitMessage;

        try {
          // ========================================================================
          // Test 1: Basic Recovery Time
          // ========================================================================
          reportBuffer.writeln('TEST 1: Basic Recovery Time');
          reportBuffer.writeln('-------------------------');
          reportBuffer.writeln(
            'Goal: Trigger the rate limit and test recovery at different time intervals\n',
          );

          // Reset counters
          successCount = 0;
          errorCount = 0;
          rateLimitErrors = 0;

          // Trigger rate limit with rapid requests
          debugPrint('PART 1: Triggering rate limit with rapid requests...');
          reportBuffer.writeln(
            'PART 1: Triggering rate limit with rapid requests',
          );

          bool rateLimitTriggered = false;
          int triggerAttempts = 0;

          while (!rateLimitTriggered && triggerAttempts < 15) {
            triggerAttempts++;

            try {
              final zipCode = zipCodes[triggerAttempts % zipCodes.length];
              debugPrint(
                'Request $triggerAttempts: Sending request for ZIP $zipCode',
              );

              final response = await apiClient.getAirQualityByZipCode(
                zipCode,
                'json',
                25,
                testConfig.apiKey,
              );

              successCount++;

              // No delay to try triggering rate limit
            } catch (e) {
              errorCount++;
              debugPrint('❌ Request $triggerAttempts failed with error: $e');

              if (e is RateLimitException ||
                  (e is DioException && e.response?.statusCode == 429)) {
                rateLimitErrors++;
                rateLimitTriggered = true;
                rateLimitMessage = e.toString();
                reportBuffer.writeln(
                  'Rate limit triggered after $triggerAttempts requests',
                );
                reportBuffer.writeln('Error: $rateLimitMessage');
                break;
              }
            }
          }

          if (!rateLimitTriggered) {
            reportBuffer.writeln(
              'Failed to trigger rate limit after $triggerAttempts attempts.',
            );
            reportBuffer.writeln(
              'Test will continue but recovery pattern results may not be meaningful.',
            );
          }

          // PART 2: Test recovery after different wait periods
          reportBuffer.writeln(
            '\nPART 2: Testing recovery after different wait periods',
          );

          // Wait periods to test (in seconds)
          final waitPeriods = [10, 20, 30];

          for (final waitPeriod in waitPeriods) {
            // Wait for the specified period
            debugPrint('\nWaiting $waitPeriod seconds to test recovery...');
            reportBuffer.writeln(
              '\nWaiting $waitPeriod seconds to test recovery...',
            );
            await Future.delayed(Duration(seconds: waitPeriod));

            // Try a request after waiting
            bool recovered = false;
            try {
              final zipCode = zipCodes[0];
              debugPrint(
                'Testing recovery after $waitPeriod seconds for ZIP $zipCode',
              );

              final response = await apiClient.getAirQualityByZipCode(
                zipCode,
                'json',
                25,
                testConfig.apiKey,
              );

              recovered = true;
              successCount++;

              debugPrint('✅ Recovery successful after $waitPeriod seconds');
              reportBuffer.writeln(
                '✅ Recovery successful after $waitPeriod seconds',
              );
            } catch (e) {
              errorCount++;
              debugPrint('❌ Recovery failed after $waitPeriod seconds: $e');
              reportBuffer.writeln(
                '❌ Recovery failed after $waitPeriod seconds: $e',
              );

              if (e is RateLimitException ||
                  (e is DioException && e.response?.statusCode == 429)) {
                rateLimitErrors++;
                reportBuffer.writeln(
                  '  Rate limit still in effect after $waitPeriod seconds',
                );
              }
            }

            // If recovered, try a quick burst to see if partial recovery
            if (recovered) {
              debugPrint('Testing if recovery is complete or partial...');
              reportBuffer.writeln(
                'Testing if recovery is complete or partial...',
              );

              int quickSuccesses = 0;
              int quickErrors = 0;

              // Try 3 quick requests to see if fully recovered
              for (int i = 0; i < 3; i++) {
                try {
                  final zipCode = zipCodes[i % zipCodes.length];

                  final response = await apiClient.getAirQualityByZipCode(
                    zipCode,
                    'json',
                    25,
                    testConfig.apiKey,
                  );

                  quickSuccesses++;
                  successCount++;
                } catch (e) {
                  quickErrors++;
                  errorCount++;

                  if (e is RateLimitException ||
                      (e is DioException && e.response?.statusCode == 429)) {
                    rateLimitErrors++;
                    reportBuffer.writeln(
                      '  Partial recovery detected - hit rate limit again after $quickSuccesses requests',
                    );
                    break;
                  }
                }

                // Small delay between quick requests
                if (i < 2) {
                  await Future.delayed(const Duration(milliseconds: 200));
                }
              }

              reportBuffer.writeln(
                '  After $waitPeriod seconds: $quickSuccesses of 3 quick requests succeeded',
              );
              if (quickSuccesses == 3) {
                reportBuffer.writeln(
                  '  Full recovery detected after $waitPeriod seconds',
                );
              }
            }
          }

          // ========================================================================
          // Test 2: Adaptive Request Patterns
          // ========================================================================
          reportBuffer.writeln('\n\nTEST 2: Adaptive Request Patterns');
          reportBuffer.writeln('-----------------------------');
          reportBuffer.writeln(
            'Goal: Test different batch patterns for sending requests\n',
          );

          // Reset rate limit state with a longer wait
          debugPrint(
            '\nWaiting 60 seconds to ensure full recovery for Test 2...',
          );
          reportBuffer.writeln(
            'Waiting 60 seconds to ensure full recovery for Test 2...',
          );
          await Future.delayed(const Duration(seconds: 60));

          // Different batch patterns to test
          final batchPatterns = [
            _BatchPattern(
              batchSize: 3,
              delayBetweenRequestsMs: 500,
              delayAfterBatchMs: 2000,
            ),
            _BatchPattern(
              batchSize: 5,
              delayBetweenRequestsMs: 200,
              delayAfterBatchMs: 5000,
            ),
            _BatchPattern(
              batchSize: 2,
              delayBetweenRequestsMs: 1000,
              delayAfterBatchMs: 1000,
            ),
          ];

          // Test each pattern
          for (
            int patternIndex = 0;
            patternIndex < batchPatterns.length;
            patternIndex++
          ) {
            final pattern = batchPatterns[patternIndex];

            debugPrint('\nTesting pattern ${patternIndex + 1}: $pattern');
            reportBuffer.writeln('\nPattern ${patternIndex + 1}:');
            reportBuffer.writeln('$pattern');

            // Reset counters for this pattern
            int patternSuccesses = 0;
            int patternErrors = 0;
            int patternRateLimits = 0;
            bool patternRateLimitTriggered = false;

            // Run 3 batches with this pattern
            for (
              int batch = 0;
              batch < 3 && !patternRateLimitTriggered;
              batch++
            ) {
              reportBuffer.writeln('  Batch ${batch + 1}:');

              // Send requests in this batch
              for (
                int i = 0;
                i < pattern.batchSize && !patternRateLimitTriggered;
                i++
              ) {
                try {
                  final zipCode =
                      zipCodes[(patternIndex + batch + i) % zipCodes.length];

                  final response = await apiClient.getAirQualityByZipCode(
                    zipCode,
                    'json',
                    25,
                    testConfig.apiKey,
                  );

                  patternSuccesses++;
                  successCount++;
                  reportBuffer.writeln('    Request ${i + 1}: Success');
                } catch (e) {
                  patternErrors++;
                  errorCount++;
                  reportBuffer.writeln('    Request ${i + 1}: Error - $e');

                  if (e is RateLimitException ||
                      (e is DioException && e.response?.statusCode == 429)) {
                    patternRateLimits++;
                    rateLimitErrors++;
                    patternRateLimitTriggered = true;
                    reportBuffer.writeln(
                      '    Rate limit triggered in batch ${batch + 1}, request ${i + 1}',
                    );
                    break;
                  }
                }

                // Delay between requests in batch
                if (i < pattern.batchSize - 1 && !patternRateLimitTriggered) {
                  await Future.delayed(
                    Duration(milliseconds: pattern.delayBetweenRequestsMs),
                  );
                }
              }

              // Delay after batch
              if (batch < 2 && !patternRateLimitTriggered) {
                await Future.delayed(
                  Duration(milliseconds: pattern.delayAfterBatchMs),
                );
              }
            }

            // Report results for this pattern
            reportBuffer.writeln(
              '  Pattern results: $patternSuccesses successes, $patternErrors errors, $patternRateLimits rate limits',
            );

            if (patternRateLimitTriggered) {
              reportBuffer.writeln('  ⚠️ This pattern triggered rate limiting');
            } else {
              reportBuffer.writeln(
                '  ✓ This pattern completed without triggering rate limiting',
              );
            }

            // If we hit a rate limit, wait to recover before next pattern
            if (patternRateLimitTriggered) {
              debugPrint(
                'Waiting 40 seconds to recover before next pattern...',
              );
              reportBuffer.writeln(
                '  Waiting 40 seconds to recover before next pattern...',
              );
              await Future.delayed(const Duration(seconds: 40));
            }
          }
        } finally {
          // Finalize report
          final testEndTime = DateTime.now();
          final testDuration = testEndTime.difference(testStartTime);

          reportBuffer.writeln('\nSUMMARY:');
          reportBuffer.writeln('--------');
          reportBuffer.writeln('Test completed at: $testEndTime');
          reportBuffer.writeln(
            'Total test duration: ${testDuration.inMinutes} minutes, ${testDuration.inSeconds % 60} seconds',
          );
          reportBuffer.writeln('Successful requests: $successCount');
          reportBuffer.writeln('Failed requests: $errorCount');
          reportBuffer.writeln(
            'Rate limit errors encountered: $rateLimitErrors',
          );

          // Recommendations based on test results
          reportBuffer.writeln('\nRECOMMENDATIONS:');
          if (rateLimitErrors > 0) {
            reportBuffer.writeln('✓ Rate limits were successfully detected');

            // Write out any rate limit messages
            if (rateLimitMessage != null) {
              reportBuffer.writeln('\nRate limit error message:');
              reportBuffer.writeln(rateLimitMessage);
            }

            reportBuffer.writeln('\nBased on the recovery tests:');
            // Add recommendations based on the test results
            // This would typically be based on the specific patterns tested
            reportBuffer.writeln('- Implement progressive backoff strategy');
            reportBuffer.writeln(
              '- Consider using smaller batch sizes with delays between requests',
            );
            reportBuffer.writeln(
              '- After hitting a rate limit, wait at least 30 seconds before retrying',
            );
            reportBuffer.writeln(
              '- Distribute requests across different API keys if possible',
            );
          } else {
            reportBuffer.writeln(
              '! No rate limit errors were encountered during testing',
            );
            reportBuffer.writeln('! This may indicate:');
            reportBuffer.writeln(
              '  - Test may not have been aggressive enough to trigger rate limits',
            );
            reportBuffer.writeln('  - Rate limits may be higher than expected');
            reportBuffer.writeln(
              '  - Network errors may have prevented proper testing',
            );
          }

          // Write report
          await resultsFile.writeAsString(reportBuffer.toString());
          debugPrint('📝 Results saved to: ${resultsFile.path}');
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip:
          'Intensive test that makes many API calls. Run with --run-skipped flag.',
    ); // Skip by default
  });
}
