import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/flavors.dart';
import 'package:timezone/data/latest.dart' as tz;

// Import test helper
import '../helpers/mock_service_locator.dart';

// Import all E2E test files with different aliases
import 'aqi_monitoring/complete_user_journey_test.dart' as complete_journey;
import 'aqi_monitoring/error_scenarios_test.dart' as error_scenarios;
import 'aqi_monitoring/cache_mechanism_test.dart' as cache_mechanism;
import 'aqi_monitoring/e2e_rate_limit_test.dart' as rate_limit;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // Initialize the timezone database
    tz.initializeTimeZones();
    
    // Initialize the flavor for testing - only needs to happen once
    F.appFlavor = Flavor.dev;
    
    // Initialize mock service locator
    MockServiceLocator.init();
  });
  
  tearDownAll(() {
    // Clean up after all tests
    MockServiceLocator.tearDown();
  });
  
  // Modify the imported test files to not initialize flavors again
  group('E2E Tests: AQI Monitoring', () {
    group('Complete User Journey', () => complete_journey.main(skipSetup: true));
    group('Error Scenarios', () => error_scenarios.main(skipSetup: true));
    group('Cache Mechanism', () => cache_mechanism.main(skipSetup: true));
    group('Rate Limit Tests', () => rate_limit.main(skipSetup: true));
  });
} 