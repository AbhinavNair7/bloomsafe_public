# BloomSafe Error Handling & Rate Limiting

This document provides a detailed overview of BloomSafe's error handling architecture and rate limiting system.

## Error Handling Architecture

BloomSafe implements a comprehensive multi-layered error handling system that ensures users receive appropriate feedback when issues occur.

### Core Components

#### 1. Exception Hierarchy

All API exceptions extend from the base `ApiException` class:

```dart
abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}
```

Specific exception types:

| Exception Type | Purpose | Thrown When |
|----------------|---------|-------------|
| `NetworkException` | Connectivity issues | Device is offline |
| `NoDataForZipcodeException` | No data available | API returns empty result for a ZIP code |
| `RateLimitException` | Rate limits exceeded | Too many requests are made |
| `ServerException` | Server-side errors | General API errors (5xx) |
| `InvalidZipcodeException` | ZIP code format issues | ZIP code validation fails |
| `BadRequestException` | Request format errors | 400 status code |
| `UnauthorizedException` | Authentication errors | 401 status code |
| `AQIException` | General AQI-related errors | Parsing issues or data problems |

#### 2. Error Handler Class

The `ErrorHandler` class (`lib/core/network/error_handler.dart`) provides centralized error processing:

```dart
class ErrorHandler {
  Future<dynamic> handle(dynamic error, {
    String? zipcode,
    int retries = 0,
    Future<dynamic> Function()? retryAction,
  }) async {
    // Error handling implementation
  }
}
```

Key features:
- Error logging and analytics tracking
- Exponential backoff retry mechanism
- Specific error type preservation
- Consistent error message mapping

#### 3. Error Interceptor

The `ErrorInterceptor` class (`lib/core/network/interceptors/error_interceptor.dart`) intercepts Dio HTTP errors and converts them to domain-specific exceptions:

```dart
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Error interception and mapping
  }
}
```

This interceptor:
- Maps HTTP status codes to appropriate exception types
- Extracts detailed error information from responses
- Provides special handling for rate limit errors
- Preserves the original request context

### Error Flow

1. **API Client Layer**:
   - Validates input parameters
   - Implements rate limiting
   - Uses Dio with ErrorInterceptor
   - Throws specific exceptions

2. **Repository Layer**:
   - Catches and processes exceptions
   - Uses ErrorHandler for retry logic
   - Preserves specific exceptions

3. **Provider/ViewModel Layer**:
   - Converts exceptions to user-friendly error states
   - Updates UI state based on error type
   - Provides recovery actions when possible

4. **UI Layer**:
   - Displays appropriate error messages
   - Provides retry options where applicable
   - Shows loading states during retries

### Common Error Types and Messages

| Error Type | User Message | Recovery Action |
|------------|--------------|----------------|
| Network | No internet connection detected. Please check your network settings and try again. | Retry button |
| Client Rate Limit | You've made several searches in a short time. Please wait 10 minutes before trying again. | Timer |
| API Rate Limit | Our servers are busy at the moment. Please try again in a few minutes. | Timer |
| No Data | No data available for this zipcode. | Try different zipcode |
| Server | Unable to retrieve air quality data at this time. Please try again later. | Retry button |
| Validation | Zipode must be 5 digits. | Form validation |

## Rate Limiting System

BloomSafe implements a dual rate limiting system to protect against API quotas being exhausted.

### 1. Client-Side Rate Limiter

The application implements a client-side rate limiter (`lib/core/network/rate_limiter.dart`) with the following characteristics:

- **Per-Minute Limit**: 5 requests per minute
- **Lockout Duration**: 10 minutes after exceeding the limit
- **Status Thresholds**:
  - Warning: 70% of limit reached (3-4 requests)
  - Critical: 90% of limit reached (4-5 requests)
  - Exceeded: Over 5 requests in one minute

Key features:
- Request counting with timestamps
- Status change notifications
- Persistent lockout state (survives app restarts)
- App lifecycle awareness (handles background/foreground transitions)

Implementation details:
```dart
class RateLimiter {
  // Request tracking
  final List<DateTime> _requestTimestamps = [];
  final int maxRequestsPerMinute = 5;
  
  // Status management
  RateLimitStatus _status = RateLimitStatus.normal;
  
  // Lockout tracking
  DateTime? _lockoutStartTime;
  final Duration lockoutDuration = Duration(minutes: 10);
  
  // Methods to check limits, record requests, etc.
}
```

### 2. API-Side Rate Limit Handling

The AirNow API enforces its own rate limits which are detected and handled:

#### API Per-Minute Rate Limit
- **Rate Limit**: Variable (approximately 10-20 requests per minute)
- **Error Response**: Status code 429 when limit is exceeded
- **Client Behavior**: Displays error message but does NOT enforce a lockout
- **Detection**: 429 responses without specific hourly limit messages
- **User Experience**: Shows "Our servers are busy at the moment. Please try again in a few minutes."

#### API Per-Hour Rate Limit
- **Rate Limit**: 500 requests per hour (as documented in API specifications)
- **Error Response**: Status code 429 with specific XML error format
- **Client Behavior**: Displays error message but does NOT enforce a lockout
- **Detection**: 429 responses with message containing "Web service request limit exceeded"
- **User Experience**: Shows "Unable to connect to the servers currently. Please try again in 30 minutes."

### Rate Limit Detection Logic

The application detects different types of rate limits:

```dart
// Helper method to handle DioExceptions and convert them to appropriate ApiExceptions
Never _handleDioException(DioException e, String endpoint) {
  if (e.response != null && e.response!.statusCode == 429) {
    // Handle API rate limit exceeded
    Logger.error('ApiClient: API rate limit exceeded on $endpoint');
    
    // Check if it's an hourly rate limit by examining the response
    final responseString = e.response?.data.toString() ?? '';
    if (responseString.contains('Web service request limit exceeded')) {
      // This is the hourly limit
      throw RateLimitExceededException(
        apiHourlyRateLimitExceededMessage,
        RateLimitType.serverHourly
      );
    } else {
      // Default per-minute rate limit
      throw RateLimitExceededException(
        apiRateLimitExceededMessage,
        RateLimitType.serverMinute
      );
    }
  }
  // Other error handling...
}
```

### Rate Limiting Integration Points

The rate limiter integrates with the app through several components:

1. **ApiClient**: 
   - Calls `verifyRateLimit()` before making requests (client-side limits only)
   - Records successful requests 
   - Handles rate limit exceptions without enforcing lockouts for API limits

2. **Repository**: 
   - Catches and processes rate limit exceptions
   - Provides appropriate user messaging

3. **Provider**: 
   - Maps rate limit exceptions to UI state
   - Preserves specific rate limit messages

4. **UI**: 
   - Displays appropriate messages based on the type of rate limit
   - Shows remaining lockout time for client-side limits
   - Prevents additional requests during client-side lockout

### Rate Limiter Improvements

Recent improvements to the rate limiter system include:

1. **Enhanced Lockout Persistence**:
   - Storage of lockout state using `SharedPreferences`
   - Timestamp-based tracking for accurate expiration
   - Type preservation across app restarts

2. **App Lifecycle Management**:
   - Implementation of `WidgetsBindingObserver` for foreground/background detection
   - State preservation during app lifecycle changes
   - Protected reset logic to prevent premature lockout clearing

3. **Development Mode Support**:
   - Environment variable flag to disable rate limiting during development
   - Documentation for development mode usage

4. **Improved API Limit Handling**:
   - No lockout enforcement for API-side rate limits
   - Clear user messaging for different limit types
   - Ability to continue searching with different parameters when hitting API limits

## Multi-Layered Protection

BloomSafe's approach combines multiple protection mechanisms:

1. **Primary Defense**: Conservative client-side rate limiting (5 requests/minute with 10-minute lockout)

2. **Secondary Defense**: API-side rate limit detection and handling (no lockout)

3. **Protection Layers**:
   - Form validation to prevent invalid requests
   - Client-side tracking to prevent quota exhaustion
   - API-side protection as final safeguard
   - User education through clear messaging

## UI Error Feedback Optimization

BloomSafe implements optimized error presentation through a robust layout structure:

### 1. Layout Structure Improvements

**Components Involved**:
- `TrackHomePage` in `track_home_page.dart`
- Error message components
- Educational tip components

**Implementation Features**:
- Deterministic layout structure with explicit Column/Expanded components
- Fixed positioning of educational tips outside scrollable areas
- Proper constraint enforcement for reliable rendering across devices
- Consistent spacing around error message components

### 2. Error Visibility Prioritization

**Components Involved**:
- Error display components
- Layout structure

**Implementation Features**:
- Errors displayed in fixed, always-visible screen areas
- Educational tips remain visible during error display
- Consistent spacing around error components
- Proper contrast for error messages
- Appropriate error action buttons always visible

### 3. Error Recovery UI

**Components Involved**:
- Error message components
- Retry buttons

**Implementation Features**:
- Fixed positioning of retry buttons outside scrollable areas
- Clear visual association between errors and recovery actions
- Consistent button styling across different error types
- Appropriate spacing for touch targets
- Proper constraint enforcement for reliable rendering

This approach ensures error messages and recovery actions are always visible and accessible to users, regardless of device size or orientation.

## Fallback Strategy During Rate Limiting

When rate limits are reached, the system follows these steps:

1. Check if valid cached data (less than 2 hours old) exists for the requested ZIP code
2. If valid cache exists, use it and inform the user that cached data is being displayed
3. If no valid cache is available, display a rate limit exceeded message to the user
4. BloomSafe never shows expired cache data (>2 hours old), even during rate limiting

This ensures users only see fresh, reliable data while respecting API rate limits. 