import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:bloomsafe/core/constants/api_endpoints.dart';

/// Test app config that provides actual API key for intensive testing
class TestAppConfig implements AppConfig {
  @override
  String? get apiKey => const String.fromEnvironment('API_KEY');

  @override
  bool get useMockApi => false;

  @override
  // Set a very high limit to prevent client-side limiting
  int get maxRequestsPerMinute => 100;

  @override
  int get maxRequestsPerHour => 1000;

  @override
  bool get disableRateLimit => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> setApiKey(String apiKey) async => true;

  @override
  Future<String?> getSecureApiKey() async => apiKey;

  @override
  bool toggleMockApi() => false;

  @override
  void useMockApiMode() {}

  @override
  bool useRealApiMode() => true;

  @override
  Future<bool> useRealApiModeSecure() async => true;

  @override
  Future<void> useTestEnvironment({bool useTestEnv = true}) async {}
}

/// This test is designed to aggressively hit the AirNow API hourly rate limit.
/// It makes direct API calls bypassing all client-side rate limiting.
///
/// The purpose is to document the exact API response when the hourly limit is reached.
///
/// WARNING: This test makes 500+ API calls and should ONLY be run when specifically
/// investigating the hourly rate limit behavior.
///
/// The test requires a valid API key passed via --dart-define=API_KEY=your_real_key
@Tags(['intensive'])
void main() {
  group('AirNow API hourly rate limit', () {
    test(
      'Documenting hourly rate limit exact response',
      () async {
        // Set test timeout to 30 minutes to allow for 500+ requests
        await runZoned(
          () async {
            // Setup report file
            final reportFile = File(
              'test/intensive/reports/hourly_limit_report.txt',
            );
            final reportDir = Directory('test/intensive/reports');
            if (!await reportDir.exists()) {
              await reportDir.create(recursive: true);
            }

            final report = StringBuffer();
            report.writeln('AIRNOW API HOURLY RATE LIMIT TEST REPORT');
            report.writeln('========================================');
            report.writeln('Test run on: ${DateTime.now()}');
            report.writeln();

            // Get API key
            final apiKey = const String.fromEnvironment('API_KEY');
            if (apiKey.isEmpty) {
              report.writeln(
                'ERROR: No API key provided. Use --dart-define=API_KEY=your_api_key',
              );
              await reportFile.writeAsString(report.toString());
              fail('No API key provided. Test requires a valid API key.');
            }

            // Basic format validation for API key (UUID format)
            final uuidPattern = RegExp(
              r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$',
              caseSensitive: false,
            );

            if (!uuidPattern.hasMatch(apiKey)) {
              report.writeln(
                'ERROR: Invalid API key format. AirNow API keys must be in UUID format.',
              );
              report.writeln(
                'Example valid format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              );
              report.writeln('You provided: $apiKey');
              await reportFile.writeAsString(report.toString());
              fail(
                'Invalid API key format. AirNow API keys must be in UUID format.',
              );
            }

            report.writeln('Using API key: $apiKey');
            report.writeln();

            // Create Dio with longer timeouts
            final dio = Dio(
              BaseOptions(
                baseUrl: aqiBaseUrl,
                connectTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
              ),
            );

            // Add detailed logging
            dio.interceptors.add(
              LogInterceptor(
                requestBody: true,
                responseBody: true,
                logPrint: (obj) {
                  if (obj.toString().contains('429')) {
                    // Highlight rate limit responses
                    print('🔴 RATE LIMIT DETECTED: $obj');
                    report.writeln('RATE LIMIT RESPONSE: $obj');
                    report.writeln();
                  }
                },
              ),
            );

            // Tracking variables
            int successCount = 0;
            int failureCount = 0;
            final DateTime startTime = DateTime.now();
            DateTime? endTime;
            String? hourlyLimitMessage;
            bool hourlyLimitReached = false;

            // Zip codes to cycle through (to make the test more realistic)
            final zipCodes = [
              '90210',
              '10001',
              '60601',
              '75001',
              '94102',
              '33101',
              '02108',
              '80202',
              '20001',
              '85001',
              '48201',
              '98101',
              '19103',
              '30303',
              '64101',
            ];

            // Make 520 requests (exceeding the 500/hour limit)
            final totalRequests = 520;
            print(
              'Starting test run - making $totalRequests requests to hit hourly limit',
            );
            report.writeln('Test parameters:');
            report.writeln('- Total requests planned: $totalRequests');
            report.writeln('- API endpoint: $aqiBaseUrl');
            report.writeln('- Testing ZIP codes: ${zipCodes.join(", ")}');
            report.writeln();

            for (int i = 0; i < totalRequests; i++) {
              if (hourlyLimitReached) {
                // Stop if we've already hit the limit
                break;
              }

              // Use a different ZIP code for each request
              final zipCode = zipCodes[i % zipCodes.length];

              // Log progress every 10 requests
              if (i % 10 == 0) {
                print(
                  'Making request $i of $totalRequests - Success so far: $successCount',
                );
              }

              try {
                // Make direct request to the API
                final Map<String, dynamic> params = {
                  'zipCode': zipCode,
                  'format': 'json',
                  'distance': 5,
                  'api_key': apiKey,
                };

                final response = await dio.get('', queryParameters: params);

                // Count successful request
                successCount++;

                // Minimal delay (100ms) between requests to be somewhat considerate
                await Future.delayed(const Duration(milliseconds: 100));
              } catch (e) {
                failureCount++;

                if (e is DioException) {
                  // Handle DioException
                  if (e.response?.statusCode == 429) {
                    // This is a rate limit response
                    final responseData =
                        e.response?.data.toString() ?? 'No response data';

                    // AirNow API returns this exact message for hourly limit
                    final expectedMessage =
                        'Web service request limit exceeded';
                    final isHourlyLimit = responseData.contains(
                      expectedMessage,
                    );

                    // All rate limit details
                    print(
                      '⚠️ Rate limit response status: ${e.response?.statusCode}',
                    );
                    print('⚠️ Rate limit response: $responseData');
                    print('⚠️ Request count when limit hit: $successCount');

                    report.writeln('RATE LIMIT TRIGGERED');
                    report.writeln('- Status code: ${e.response?.statusCode}');
                    report.writeln('- Response data: $responseData');
                    report.writeln('- Headers: ${e.response?.headers}');
                    report.writeln(
                      '- Request count when limit hit: $successCount',
                    );
                    report.writeln();

                    if (isHourlyLimit) {
                      // We've found the hourly limit!
                      hourlyLimitReached = true;
                      hourlyLimitMessage = responseData;
                      endTime = DateTime.now();

                      print(
                        '🔴 HOURLY RATE LIMIT DETECTED after $successCount successful requests',
                      );
                      print('🔴 Hourly limit message: $responseData');

                      report.writeln('🔴 HOURLY RATE LIMIT DETECTED');
                      report.writeln(
                        '- Successful requests before limit: $successCount',
                      );
                      report.writeln(
                        '- Exact rate limit message: $hourlyLimitMessage',
                      );

                      final duration = endTime.difference(startTime);
                      report.writeln(
                        '- Test duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s',
                      );
                      report.writeln(
                        '- Average request rate: ${(successCount / (duration.inSeconds / 60)).toStringAsFixed(2)} requests/minute',
                      );
                    
                      report.writeln();
                      // Found what we're looking for - break out of the loop
                      break;
                    } else {
                      // This is a minute-based rate limit, wait longer before continuing
                      print(
                        '⏱️ Minute-based rate limit encountered, waiting before continuing...',
                      );
                      await Future.delayed(const Duration(seconds: 10));
                    }
                  } else {
                    // Other error responses
                    print('❌ Error: ${e.response?.statusCode} - ${e.message}');

                    // Wait a bit to avoid overwhelming the API during errors
                    await Future.delayed(const Duration(milliseconds: 200));
                  }
                } else {
                  // Handle unexpected errors
                  print('❌ Unexpected error: $e');
                  await Future.delayed(const Duration(milliseconds: 200));
                }
              }
            }

            // Complete the report
            endTime = endTime ?? DateTime.now();
            report.writeln('TEST RESULTS SUMMARY');
            report.writeln('- Successful requests: $successCount');
            report.writeln('- Failed requests: $failureCount');

            final duration = endTime.difference(startTime);
            report.writeln(
              '- Test duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s',
            );
            report.writeln(
              '- Average request rate: ${(successCount / (duration.inSeconds / 60)).toStringAsFixed(2)} requests/minute',
            );
          
            if (hourlyLimitReached) {
              report.writeln('- Hourly limit detected: YES');
              report.writeln('- Rate limit message: $hourlyLimitMessage');
            } else {
              report.writeln('- Hourly limit detected: NO');
              report.writeln(
                '- Note: Test completed without triggering hourly rate limit',
              );
            }

            report.writeln();
            report.writeln('CONCLUSION');
            if (hourlyLimitReached) {
              report.writeln(
                '✅ Successfully detected and documented the hourly rate limit response',
              );
              report.writeln(
                '✅ The limit was reached after $successCount requests',
              );
              report.writeln(
                '✅ The exact error message will be used to update the error detection logic',
              );
            } else if (successCount >= 500) {
              report.writeln(
                '⚠️ Made $successCount requests without hitting hourly limit',
              );
              report.writeln(
                '⚠️ This suggests either the limit is higher than 500 or the API key has special permissions',
              );
            } else {
              report.writeln('❌ Test failed to reach the hourly limit');
              report.writeln(
                '❌ Only $successCount requests were successfully made',
              );
              report.writeln('❌ Review API key and try again');
            }

            // Write report to file
            await reportFile.writeAsString(report.toString());
            print('Test complete. Report written to: ${reportFile.path}');

            // Test assertions
            if (hourlyLimitReached) {
              expect(hourlyLimitMessage, isNotNull);
              expect(
                successCount,
                greaterThan(300),
                reason:
                    'Should make a substantial number of requests before hitting limit',
              );
            } else {
              // If we didn't hit the limit but made 500+ requests, that's unexpected
              if (successCount >= 500) {
                print(
                  '⚠️ Warning: Made 500+ requests without hitting hourly limit',
                );
              } else {
                fail('Failed to make enough requests to test hourly limit');
              }
            }
          },
          zoneSpecification: ZoneSpecification(
            print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
              // Print to console and also capture important logs
              parent.print(zone, line);
            },
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 30)),
      skip:
          'Intensive test that makes many API calls. Run with --run-skipped flag',
    );
  });
}
