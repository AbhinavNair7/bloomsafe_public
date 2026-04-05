import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/services/security_service.dart';
import 'package:bloomsafe/core/services/security_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecurityService securityService;

  setUp(() {
    securityService = SecurityServiceImpl();
  });

  group('SecurityService', () {
    test('runSecurityScan returns vulnerabilities', () async {
      final vulnerabilities = await securityService.runSecurityScan();

      // We expect some vulnerabilities to be returned in the test environment
      expect(vulnerabilities, isNotEmpty);

      // Check that vulnerabilities have the expected structure
      for (final vulnerability in vulnerabilities) {
        expect(vulnerability.type, isNotEmpty);
        expect(vulnerability.description, isNotEmpty);
        expect(vulnerability.severity, isIn(['high', 'medium', 'low']));
      }
    });

    test('isRunningInEmulator works in test environment', () async {
      // This is testing in the test environment, so it should return a boolean
      final isEmulator = await securityService.isRunningInEmulator();

      // We can't assert true or false, but we can check it's a bool
      expect(isEmulator, isA<bool>());
    });

    test('getSecuritySummary returns summary', () async {
      final summary = await securityService.getSecuritySummary();

      // Check that summary has the expected keys
      expect(
        summary.keys,
        containsAll([
          'data_storage',
          'api_communication',
          'encryption',
          'device_security',
          'not_emulator',
        ]),
      );

      // Check that all values are booleans
      for (final value in summary.values) {
        expect(value, isA<bool>());
      }
    });

    test('validateDataStorageSecurity returns vulnerabilities', () async {
      final vulnerabilities =
          await securityService.validateDataStorageSecurity();

      // The implementation should return at least one vulnerability for code review purposes
      expect(vulnerabilities, isNotEmpty);

      // Check the types of vulnerabilities that might be present
      final vulnerabilityTypes = vulnerabilities.map((v) => v.type).toList();
      expect(
        vulnerabilityTypes,
        anyOf(contains('secure_storage'), contains('shared_preferences')),
      );
    });

    test(
      'validateApiCommunicationSecurity identifies security concerns',
      () async {
        final vulnerabilities =
            await securityService.validateApiCommunicationSecurity();

        // There should be vulnerabilities related to HTTPS and certificate pinning
        expect(vulnerabilities, isNotEmpty);

        // Check for HTTPS recommendation
        final httpsVulnerability = vulnerabilities.where(
          (v) => v.type == 'https',
        );
        expect(httpsVulnerability, isNotEmpty);

        // Check for certificate pinning recommendation
        final certVulnerability = vulnerabilities.where(
          (v) => v.type == 'certificate_pinning',
        );
        expect(certVulnerability, isNotEmpty);
      },
    );
  });
}
