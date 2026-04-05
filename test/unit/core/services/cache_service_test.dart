import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/services/cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import '../../../helpers/test_factories.dart';
import '../../../helpers/time_utils.dart';

void main() {
  group('CacheService', () {
    late CacheService<AQIData> cacheService;
    final mockTime = DateTime(2023, 1, 1, 12, 0, 0);

    setUp(() {
      // Initialize timezone database
      TimeTestUtils.initializeTimeZones();

      // Set mock time for consistent testing
      CacheService.setMockTimeForTesting(mockTime);

      // Create a fresh cache service in test mode for each test
      cacheService = CacheService.forTesting<AQIData>();
    });

    tearDown(() {
      // Clean up cache service
      cacheService.dispose();

      // Reset mock time
      CacheService.setMockTimeForTesting(null);
    });

    test('stores and retrieves data by key', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'test_zipcode';

      // Act
      await cacheService.set(key, testData);
      final retrieved = await cacheService.get(key);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved?.reportingArea, equals(testData.reportingArea));
    });

    test('returns null for non-existent key', () async {
      // Act
      final result = await cacheService.get('non_existent_key');

      // Assert
      expect(result, isNull);
    });

    test('honors expiry time when retrieving data', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'expire_test';

      // Set an already-expired time
      final expiredTime = mockTime.subtract(const Duration(hours: 1));

      // Act
      await cacheService.set(key, testData, expiresAt: expiredTime);
      final retrieved = await cacheService.get(key);

      // Assert
      expect(retrieved, isNull);
    });

    test('isValid callback can override expiry logic', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'custom_valid_test';

      // Set an expired time
      final expiredTime = mockTime.subtract(const Duration(hours: 1));

      // Set data with expired time
      await cacheService.set(key, testData, expiresAt: expiredTime);

      // Act - get with a custom isValid function that always returns true
      final retrieved = await cacheService.get(key, isValid: (data) => true);

      // Assert
      expect(retrieved, isNotNull);
    });

    test('cache can have items manually removed from internal cache', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key1 = 'key1';
      const key2 = 'key2';

      // Add two items
      await cacheService.set(key1, testData);
      await cacheService.set(key2, testData);

      // Act - manually remove from internal cache
      cacheService.internalCache.remove(key1);

      // Assert
      final item1 = await cacheService.get(key1);
      final item2 = await cacheService.get(key2);

      expect(item1, isNull);
      expect(item2, isNotNull);
    });

    test('clear removes all items from cache', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      await cacheService.set('key1', testData);
      await cacheService.set('key2', testData);

      // Act
      await cacheService.clear();

      // Assert
      final item1 = await cacheService.get('key1');
      final item2 = await cacheService.get('key2');

      expect(item1, isNull);
      expect(item2, isNull);
    });

    test(
      'getFallback returns usable items for fallback even if expired',
      () async {
        // Arrange
        final testData = TestFactories.createAQIData();
        const key = 'fallback_test';

        // Set with already expired time, but recent timestamp
        final expiredTime = mockTime.subtract(const Duration(hours: 1));
        final itemTimestamp = mockTime.subtract(
          const Duration(minutes: 30),
        ); // Make it more recent for maxAge check

        print('Test debug: mockTime = $mockTime');
        print('Test debug: expiredTime = $expiredTime');
        print('Test debug: itemTimestamp = $itemTimestamp');

        // Add item directly to internal cache, bypassing set()
        cacheService.internalCache[key] = CachedItem(
          data: testData,
          expiresAt: expiredTime,
          timestamp: itemTimestamp,
        );

        // Verify the item is in the cache
        print(
          'Test debug: internalCache has key? ${cacheService.internalCache.containsKey(key)}',
        );

        // Call getFallback directly without calling get() first
        final fallbackGet = await cacheService.getFallback(
          key,
          maxAge: const Duration(hours: 2),
          isStillUsable: (data) => true,
        );

        // Assert
        expect(fallbackGet, isNotNull);
      },
    );

    test('getFallback returns null if data is too old', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'too_old_test';

      // Set with very old expired time and timestamp
      final veryOldTime = mockTime.subtract(const Duration(hours: 24));
      final oldTimestamp = mockTime.subtract(const Duration(hours: 3));

      // Add item directly to internal cache, bypassing set()
      cacheService.internalCache[key] = CachedItem(
        data: testData,
        expiresAt: veryOldTime,
        timestamp: oldTimestamp,
      );

      // Act
      final fallbackGet = await cacheService.getFallback(
        key,
        maxAge: const Duration(hours: 2),
        isStillUsable: (data) => true,
      );

      // Assert
      expect(fallbackGet, isNull);
    });

    test('getFallback respects isStillUsable callback', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'fallback_callback_test';

      // Set with recently expired time
      final recentlyExpired = mockTime.subtract(const Duration(minutes: 30));
      await cacheService.set(key, testData, expiresAt: recentlyExpired);

      // Act - getFallback with isStillUsable returning false
      final fallbackGet = await cacheService.getFallback(
        key,
        maxAge: const Duration(hours: 2),
        isStillUsable: (data) => false, // Always return false
      );

      // Assert
      expect(fallbackGet, isNull);
    });

    test('edge case - data expires exactly at current time', () async {
      // Arrange
      final testData = TestFactories.createAQIData();
      const key = 'edge_case_test';

      // Set with expiry exactly at current time
      await cacheService.set(key, testData, expiresAt: mockTime);

      // Act
      final retrieved = await cacheService.get(key);

      // Assert - should be null because current >= expiry is considered expired
      expect(retrieved, isNull);
    });
  });
}
