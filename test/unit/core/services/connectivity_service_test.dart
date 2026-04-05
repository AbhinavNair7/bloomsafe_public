import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityServiceInterface connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    test('hasInternetConnection returns true in test environment', () async {
      // In test environment, hasInternetConnection should always return true
      // as defined in the implementation
      final result = await connectivityService.hasInternetConnection();
      expect(result, true);
    });

    test(
      'hasInternetConnectionWithTimeout returns true in test environment',
      () async {
        // In test environment, this should also return true
        final result =
            await connectivityService.hasInternetConnectionWithTimeout();
        expect(result, true);
      },
    );
  });
}
