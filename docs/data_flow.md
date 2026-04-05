# BloomSafe Complete Data Flow

This document describes the detailed data flow through the BloomSafe application, from user input to visual display, including all transformations, caching, and error handling paths.

## Overview

The BloomSafe application follows a unidirectional data flow pattern:

```
User Input → State Management → Data Access → Data Processing → UI Rendering
```

## User Input Flow

### 1. ZIP Code Entry and Validation

**Components Involved**:
- `ZipcodeInputForm` widget in `zipcode_input_form.dart`
- `ZipCodeValidator` utility in `zipcode_validator.dart`

**Data Flow**:
1. User enters ZIP code in the input field
2. Input form validates the ZIP code format (5-digit US format)
3. Upon submission, validated ZIP code is passed to `AQIProvider.fetchData(zipcode)`

### 2. Rate Limiting Check

**Components Involved**:
- `AQIProvider` in `aqi_provider.dart`
- `AQIRepository` in `aqi_repository.dart`
- `ApiClient` in `api_client.dart`
- `RateLimiter` in `rate_limiter.dart`

**Data Flow**:
1. `ApiClient` checks against rate limiter before making request
2. If rate limited, a `RateLimitException` is thrown
3. Exception is propagated to UI for appropriate user feedback

## Data Retrieval Flow

### 1. Cache Check

**Components Involved**:
- `AQIRepositoryImpl` in `aqi_repository_impl.dart`
- `CacheManager` interface and `AQIDataCache` implementation

**Data Flow**:
1. Repository checks cache for valid data for the requested ZIP code
2. If valid cache exists, data is returned immediately
3. If no valid cache exists, repository proceeds to API request

### 2. API Request

**Components Involved**:
- `AQIRepositoryImpl` in `aqi_repository_impl.dart`
- `ApiClient` in `api_client.dart`
- `ErrorInterceptor` in `error_interceptor.dart`

**Data Flow**:
1. Repository calls `ApiClient.getAirQualityByZipCode(zipcode, format, distance)`
2. API client formats and sends request to AirNow API
3. Response is received and parsed into a List of Map<String, dynamic>
4. ErrorInterceptor processes any HTTP errors into domain-specific exceptions

### 3. Model Creation

**Components Involved**:
- `AQIRepositoryImpl` in `aqi_repository_impl.dart`
- `AQIData` model in `aqi_data.dart`
- `PollutantData` model in `pollutant_data.dart`
- `AQICategory` model in `aqi_category.dart`
- `TimeZoneMapper` in `time_zone_mapper.dart`

**Data Flow**:
1. Response data is passed to `AQIData.fromApiResponse(responseItems)`
2. Factory method creates `PollutantData` instances for each pollutant
3. Each pollutant gets an `AQICategory` based on API response
4. TimeZoneMapper creates timezone-aware observation and expiry times
5. Complete `AQIData` object is constructed with all components

### 4. Caching

**Components Involved**:
- `AQIRepositoryImpl` in `aqi_repository_impl.dart`
- `AQIDataCache` in repository implementation
- `TimeZoneMapper` in `time_zone_mapper.dart`

**Data Flow**:
1. Valid `AQIData` is passed to `cacheManager.cacheData(zipcode, aqiData)`
2. Cache validates data using timezone-aware validation logic
3. If valid, data is stored in memory cache with ZIP code as key

## Error Handling Flow

### 1. Error Generation

**Components Involved**:
- `ApiClient` in `api_client.dart`
- `ErrorInterceptor` in `error_interceptor.dart`
- Exception classes in `api_exceptions.dart`

**Data Flow**:
1. Error occurs (network, server, validation, rate limit)
2. Appropriate exception type is created with user-friendly message
3. Exception is thrown up the call stack

### 2. Error Processing

**Components Involved**:
- `AQIRepositoryImpl` in `aqi_repository_impl.dart`
- `ErrorHandler` in `error_handler.dart`
- `AQIProvider` in `aqi_provider.dart`

**Data Flow**:
1. Repository catches exception and passes to `ErrorHandler.handle()`
2. Error handler processes exception (retry logic if configured)
3. Repository returns or rethrows appropriate exception
4. AQIProvider catches exception and updates error state
5. UI components display appropriate error messages

## State Management Flow

**Components Involved**:
- `AQIProvider` in `aqi_provider.dart`
- UI components that use the provider

**Data Flow**:
1. `AQIProvider` holds current data, loading state, and error state
2. When data is requested via `fetchData(zipcode)`:
   - Sets loading state to true
   - Clears previous error
   - Sends request to repository
   - Updates state with result or error
   - Sets loading state to false
3. UI components observe provider state changes and rebuild

## UI Rendering Flow

**Components Involved**:
- `TrackHomePage` in `track_home_page.dart`
- `AQIScreen` in `aqi_screen.dart` 
- `AQIResultDisplay` in `aqi_result_display.dart`
- `SeverityGauge` in `severity_gauge.dart`

**Data Flow**:
1. UI components access state via `Provider.of<AQIProvider>(context)`
2. Based on loading, error, and data states:
   - If loading, show loading indicator
   - If error, show error message
   - If data available:
     - Extract PM2.5 data from `aqiData.getPM25()`
     - Display in `SeverityGauge` with appropriate color coding
     - Show recommendations based on severity level

## Complete Data Flow Diagram

```
User Input → ZipcodeInputForm → Validation → AQIProvider.fetchData()
                                                     ↓
              ┌───────────────AQIRepository.getAQIByZipcode()───────────────┐
              ↓                                                              ↓
      Check rate limits                                               Check cache
              ↓                                                              ↓
     Throw exception if                                             If valid cache hit
      rate limited                                                     return data
              ↓                                                              ↓
     Add request to rate                                             If cache miss
      limit counter                                                    API request
              ↓                                                              ↓
   ApiClient.getAirQualityByZipCode()                                  Parse response
              ↓                                                              ↓
       Send HTTP request                                         AQIData.fromApiResponse()
              ↓                                                              ↓
       Process response                                           Create PollutantData objects
              ↓                                                              ↓
     Parse into List<Map>                                         Create AQICategory objects
              ↓                                                              ↓
  Return raw data to repository                                  Calculate observation time
              ↓                                                              ↓
         Create AQIData                                            Calculate validUntil time
              ↓                                                              ↓
         Cache AQIData                                               Return AQIData object
              ↓                                                              ↓
 Return AQIData to provider                                         Cache in AQIDataCache
              ↓
      Update UI state
              ↓
    Rebuild UI components
              ↓
    Display results to user
```

## Error Recovery Paths

1. **Network Error Path**:
   ```
   Network failure → NetworkException → ErrorHandler → Repository rethrows → Provider sets error → UI shows message with retry option
   ```

2. **Rate Limit Path**:
   ```
   Too many requests → RateLimiter lockout → RateLimitException → Provider sets error → UI shows lockout message with timer
   ```

3. **No Data Path**:
   ```
   Empty API response → NoDataForZipcodeException → Provider sets error → UI shows no data message
   ```

## Sharing Feature Data Flow

The Share feature allows users to share AQI results and educational content via text-based sharing:

### 1. Share Button Interaction

**Components Involved**:
- UI components with share buttons
- `ShareService` in `share_service.dart`

**Data Flow**:
1. User taps share button on AQI results or educational card
2. UI component calls `ShareService.shareContent()` with appropriate content type and data
3. ShareService validates connectivity status
4. Content is formatted based on type (AQI or educational)
5. System share dialog is presented to user

### 2. AQI Result Sharing

**Components Involved**:
- `AQIResultDisplay` in `aqi_result_display.dart`
- `ShareService` in `share_service.dart`
- `AQIData` model in `aqi_data.dart`

**Data Flow**:
1. When sharing AQI results, system extracts:
   - Location (ZIP code)
   - Current PM2.5 value
   - Severity category
   - Observation time
   - Recommendations
2. Data is formatted into a human-readable message
3. Formatted content is prepared for the share dialog
4. Formatted content is passed to system share dialog

### 3. Educational Content Sharing

**Components Involved**:
- `ContentCard` in `content_card.dart`
- `ShareService` in `share_service.dart`
- Learn/Guide content models

**Data Flow**:
1. When sharing educational content, system extracts:
   - Article title
   - Brief description
   - Category information
2. Data is formatted into a human-readable message
3. Formatted content is prepared for the share dialog
4. Formatted content is passed to system share dialog

### 4. Error Handling

**Components Involved**:
- `ShareService` in `share_service.dart`
- Connectivity service

**Data Flow**:
1. Before sharing, connectivity is checked
2. If device is offline, appropriate error message is displayed
3. Share operation is cancelled if connectivity check fails

## Settings and Feedback Flow

### 1. About and Privacy Policy Screens

**Components Involved**:
- App bar menu
- Static content screens

**Data Flow**:
1. User selects option from app bar menu
2. Navigation routes to appropriate static content screen
3. Content is displayed from predefined strings

### 2. Feedback Submission

**Components Involved**:
- `FeedbackScreen` in settings screens
- `FeedbackTypeSelector` custom form component
- `FeedbackService` for submission handling

**Data Flow**:
1. User navigates to feedback screen
2. User selects feedback type using custom selector
3. User enters feedback details
4. On submission:
   - Input validation is performed
   - If valid, feedback is formatted
   - Connectivity is checked
   - Feedback is submitted via appropriate channel
   - Success/failure confirmation is displayed

## Navigation Flow

**Components Involved**:
- `BloomAppBar` in `bloom_app_bar.dart`
- `BottomNavigation` in `bottom_navigation.dart`
- Main app navigation controller

**Data Flow**:
1. Tab selection in bottom navigation:
   - State update triggers UI rebuild
   - Active tab is highlighted with indicator line
   - Tab icon switches between filled/outlined states
   - Appropriate screen content is displayed
2. Navigation maintains state during transitions
3. Bottom navigation remains visible across all screens including results

## Timezone and TTL Handling

**Data Validation Flow**:

1. Each `AQIData` instance has its own timezone-aware observation time:
   ```
   API Response → Parse date/timezone → Convert timezone abbreviation to IANA → Create TZDateTime observationTime
   ```

2. TTL calculation:
   ```
   observationTime → Add 2 hours → validUntil timestamp
   ```

3. Cache validation:
   ```
   Get current time in observation timezone → Compare to validUntil → Return validity status
   ```

This ensures proper handling of observations across different timezones and daylight saving time transitions. 