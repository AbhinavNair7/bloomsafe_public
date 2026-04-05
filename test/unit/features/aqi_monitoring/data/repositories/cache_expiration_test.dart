import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/services/cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../../helpers/timezone_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService<AQIData> cache;

  setUpAll(() {
    initializeTimeZonesForTest();
    cache = CacheService<AQIData>();
  });

  test(
    'Cache Validity Tests isValid method correctly identifies valid and invalid data',
    () async {
      // Create data that will be valid (in the future)
      final now = tz.TZDateTime.now(tz.getLocation('America/New_York'));
      final validExpiryTime = now.add(const Duration(hours: 1));

      final validTestData = _createTestData(
        'valid',
        now.subtract(const Duration(minutes: 30)),
        validExpiryTime,
      );

      // Create data that will be expired (in the past)
      final pastExpiryTime = now.subtract(const Duration(minutes: 5));
      final expiredTestData = _createTestData(
        'expired',
        now.subtract(const Duration(hours: 2)),
        pastExpiryTime,
      );

      // Test setting valid data
      await cache.set('valid', validTestData, expiresAt: validExpiryTime);

      // Test setting already expired data
      await cache.set('expired', expiredTestData, expiresAt: pastExpiryTime);

      // Check valid data is available
      final validResult = await cache.get('valid');
      expect(validResult, isNotNull);

      // Check expired data is not available
      final expiredResult = await cache.get('expired');
      expect(expiredResult, isNull);
    },
  );
}

// Helper function to create test AQI data
AQIData _createTestData(
  String reportingArea,
  tz.TZDateTime observationTime,
  tz.TZDateTime validUntil,
) {
  // Format the date and hour for AQIData constructor
  final dateObserved =
      '${observationTime.year}-${observationTime.month.toString().padLeft(2, '0')}-${observationTime.day.toString().padLeft(2, '0')}';
  final hourObserved = observationTime.hour;

  // Create test pollutant
  final pollutant = PollutantData(
    parameterName: 'PM2.5',
    aqi: 42,
    category: AQICategory(number: 1, name: 'Good'),
  );

  return AQIData(
    reportingArea: reportingArea,
    stateCode: 'TS',
    dateObserved: dateObserved,
    hourObserved: hourObserved,
    localTimeZone: observationTime.location.name,
    latitude: 0,
    longitude: 0,
    pollutants: [pollutant],
  );
}
