# BloomSafe Component Structure

This document describes the component architecture of the BloomSafe application, detailing the responsibilities of each component and their relationships.

## Architecture Overview

BloomSafe follows a clean architecture approach with clear separation between:

- **Core Components**: App-wide utilities, configurations, and services
- **Feature Modules**: Feature-specific implementations (currently AQI monitoring)
- **UI Components**: Presentation layer including screens and widgets

## Core Components

### 1. Configuration Components

#### AppConfig (`lib/core/config/app_config.dart`)
- **Responsibility**: Central configuration management
- **Key Functions**:
  - Manages environment-specific settings
  - Toggles features (mock API, rate limiting)
  - Provides access to API keys and other sensitive information
- **Dependencies**: SecureStorage, EnvConfig

#### EnvConfig (`lib/core/config/env_config.dart`)
- **Responsibility**: Environment variable management
- **Key Functions**:
  - Parses .env files
  - Provides type-safe access to environment variables
- **Dependencies**: None

#### SecureStorage (`lib/core/config/secure_storage.dart`)
- **Responsibility**: Secure data persistence
- **Key Functions**:
  - Securely stores API keys using platform-specific encryption
  - Handles graceful fallbacks to memory cache when storage fails
  - Manages test-specific storage needs
- **Dependencies**: flutter_secure_storage package

### 2. Network Components

#### ApiClient (`lib/core/network/api_client.dart`)
- **Responsibility**: External API communication
- **Key Functions**:
  - Configures and manages Dio HTTP client
  - Formats requests to AirNow API
  - Validates inputs before sending requests
  - Integrates with rate limiting system
- **Dependencies**: Dio, RateLimiter, AppConfig, ErrorInterceptor

#### MockApiClient (`lib/core/network/mock_api_client.dart`)
- **Responsibility**: Simulated API responses
- **Key Functions**:
  - Mimics real ApiClient interface
  - Provides consistent test data
  - Simulates various error scenarios
- **Dependencies**: Dio, AppConfig

#### RateLimiter (`lib/core/network/rate_limiter.dart`)
- **Responsibility**: API request throttling
- **Key Functions**:
  - Tracks API requests with timestamps
  - Enforces per-minute and hourly limits
  - Implements lockout mechanism with persistence
  - Manages lockout state across app restarts
- **Dependencies**: SharedPreferences, AppConfig

#### ErrorHandler (`lib/core/network/error_handler.dart`)
- **Responsibility**: Centralized error processing
- **Key Functions**:
  - Implements retry logic with exponential backoff
  - Maps generic errors to domain-specific exceptions
  - Preserves error context during processing
- **Dependencies**: ApiExceptions

#### Exception Components (`lib/core/network/exceptions/api_exceptions.dart`)
- **Responsibility**: Error type definitions
- **Key Classes**:
  - ApiException (base class)
  - NetworkException, ServerException
  - InvalidZipcodeException, NoDataForZipcodeException
  - RateLimitException (with different types)
- **Dependencies**: None

#### ErrorInterceptor (`lib/core/network/interceptors/error_interceptor.dart`)
- **Responsibility**: HTTP error processing
- **Key Functions**:
  - Converts HTTP status codes to domain exceptions
  - Identifies different types of rate limit errors
  - Maps network errors appropriately
- **Dependencies**: Dio, ApiExceptions

#### LoggingInterceptor (`lib/core/network/interceptors/logging_interceptor.dart`)
- **Responsibility**: Request/response logging
- **Key Functions**:
  - Logs API requests and responses in debug mode
  - Sanitizes sensitive information from logs
- **Dependencies**: Dio

### 3. Utility Components

#### TimeZoneMapper (`lib/core/utils/time_zone_mapper.dart`)
- **Responsibility**: Timezone handling
- **Key Functions**:
  - Converts timezone abbreviations to IANA identifiers
  - Creates timezone-aware DateTime objects
  - Calculates expiry times for cache entries
  - Handles daylight saving time edge cases
- **Dependencies**: timezone package

#### AQIParser (`lib/core/utils/aqi_parser.dart`)
- **Responsibility**: AQI data processing
- **Key Functions**:
  - Extracts PM2.5 data from API responses
  - Generates health recommendations based on AQI levels
  - Validates data freshness
- **Dependencies**: None

#### ZipcodeValidator (`lib/core/network/utils/zipcode_validator.dart`)
- **Responsibility**: ZIP code validation
- **Key Functions**:
  - Validates 5-digit US ZIP code format
  - Provides detailed validation error messages
- **Dependencies**: None

#### ResponseParser (`lib/core/network/utils/response_parser.dart`)
- **Responsibility**: API response parsing
- **Key Functions**:
  - Extracts and validates data from API responses
  - Handles different response formats
- **Dependencies**: None

### 4. Theme Components

#### AppTheme (`lib/core/theme/app_theme.dart`)
- **Responsibility**: Application theming
- **Key Functions**:
  - Defines app-wide theme settings
  - Provides light/dark theme configurations
- **Dependencies**: Colors, Typography constants

## Feature: AQI Monitoring

### 1. Domain Layer

#### AQIRepository Interface (`lib/features/aqi_monitoring/domain/repositories/aqi_repository.dart`)
- **Responsibility**: Defines data access contract
- **Key Functions**:
  - Declares methods for AQI data retrieval
- **Dependencies**: AQIData model

### 2. Data Layer

#### AQIRepositoryImpl (`lib/features/aqi_monitoring/data/repositories/aqi_repository_impl.dart`)
- **Responsibility**: AQI data access implementation
- **Key Functions**:
  - Implements AQIRepository interface
  - Manages caching logic with time-based validation
  - Coordinates between API and cache sources
  - Handles error processing and validation
- **Dependencies**: ApiClient, CacheManager, ErrorHandler, AQIData

#### AQIData Model (`lib/features/aqi_monitoring/data/models/aqi_data.dart`)
- **Responsibility**: Air quality data representation
- **Key Functions**:
  - Stores and provides access to air quality measurements
  - Manages timezone-aware observation and expiry times
  - Validates data freshness
  - Extracts PM2.5 specific data
- **Dependencies**: PollutantData, TimeZoneMapper

#### PollutantData Model (`lib/features/aqi_monitoring/data/models/pollutant_data.dart`)
- **Responsibility**: Individual pollutant representation
- **Key Functions**:
  - Stores pollutant measurements (PM2.5, O3, PM10)
  - Identifies pollutant type
  - Provides AQI category information
- **Dependencies**: AQICategory

#### AQICategory Model (`lib/features/aqi_monitoring/data/models/aqi_category.dart`)
- **Responsibility**: AQI categorization
- **Key Functions**:
  - Maps numeric AQI values to named categories
  - Validates category numbers (1-6)
- **Dependencies**: None

#### AQISeverity Enum (`lib/features/aqi_monitoring/data/models/aqi_severity.dart`)
- **Responsibility**: Custom severity classification
- **Key Functions**:
  - Defines pregnancy-specific severity zones
  - Maps PM2.5 values to severity categories
  - Provides zone-specific colors and recommendations
- **Dependencies**: None

### 3. Presentation Layer

#### AQIProvider (`lib/features/aqi_monitoring/presentation/state/aqi_provider.dart`)
- **Responsibility**: State management
- **Key Functions**:
  - Coordinates between UI and repository
  - Manages loading, error, and data states
  - Maps exceptions to user-friendly messages
  - Provides data access to UI components
- **Dependencies**: AQIRepository, AQIData

#### TrackHomePage (`lib/features/aqi_monitoring/presentation/screens/track_home_page.dart`)
- **Responsibility**: Main input screen
- **Key Functions**:
  - Provides ZIP code input interface
  - Manages navigation to results screen
  - Displays appropriate error messages
- **Dependencies**: AQIProvider, ZipcodeInputForm

#### AQIScreen (`lib/features/aqi_monitoring/presentation/screens/aqi_screen.dart`)
- **Responsibility**: Results display screen
- **Key Functions**:
  - Shows AQI results with severity indicators
  - Displays health recommendations
  - Provides error handling UI
- **Dependencies**: AQIProvider, AQIResultDisplay

#### ZipcodeInputForm (`lib/features/aqi_monitoring/presentation/widgets/zipcode_input_form.dart`)
- **Responsibility**: ZIP code input UI
- **Key Functions**:
  - Validates ZIP code input in real-time
  - Provides submission handling
  - Shows input-specific error messages
- **Dependencies**: AQIProvider, ZipcodeValidator

#### SeverityGauge (`lib/features/aqi_monitoring/presentation/widgets/severity_gauge.dart`)
- **Responsibility**: Visual AQI representation
- **Key Functions**:
  - Displays circular and horizontal gauge indicators
  - Uses color coding based on severity level
  - Shows numeric AQI value and category name
- **Dependencies**: AQISeverity, AQIData

#### AQIResultDisplay (`lib/features/aqi_monitoring/presentation/widgets/aqi_result_display.dart`)
- **Responsibility**: Comprehensive results UI
- **Key Functions**:
  - Combines severity gauge, location info, and recommendations
  - Formats observation time information
  - Displays data freshness indicators
- **Dependencies**: SeverityGauge, AQIData, AQISeverity

### Feature: Learn & Guide

**Models**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **guide_content.dart** | Guide content models and data | N/A | Guide screens |
| **learn_content.dart** | Educational article definitions | N/A | Learn screens |

**Presentation**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **guide_screen.dart** | UI for displaying guide content | Provider, ContentCard | Main app navigation |
| **learn_screen.dart** | UI for displaying educational content | Provider, ContentCard | Main app navigation |

**Widgets**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **content_card.dart** | Reusable card component for content display | N/A | Guide and Learn screens |
| **section_header.dart** | Standardized section headers | N/A | Guide and Learn screens |

## UI Navigation

### Navigation System

BloomSafe implements a standardized navigation system with consistent top and bottom bars:

**Components**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **bloom_app_bar.dart** | Consistent app bar with logo | N/A | All screens |
| **bottom_navigation.dart** | Tab navigation with indicators | N/A | Main app structure |

**Features**:
- Tab-specific indicator lines for active navigation items
- State-aware icons (filled/outlined pattern for active/inactive states)
- Consistent visibility across all screens including results

## Share and Settings Features

**Sharing System**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **share_service.dart** | Text-based sharing functionality | N/A | AQI results and educational cards |

**Settings Screens**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **about_screen.dart** | About BloomSafe information | N/A | Top menu |
| **privacy_policy_screen.dart** | Privacy policy display | N/A | Top menu |
| **feedback_screen.dart** | Feedback submission form | N/A | Top menu |

**Feedback Components**:
| File | Purpose | Key Dependencies | Used By |
|------|---------|------------------|---------|
| **feedback_type_selector.dart** | Custom feedback type selection | FormField | Feedback screen |

## Dependency Flow

The high-level dependencies flow as follows:

```
UI Components → State (Providers) → Domain Interface → Data Implementation → Network/Storage

TrackHomePage, AQIScreen → AQIProvider → AQIRepository → AQIRepositoryImpl → ApiClient + CacheManager
```

This architecture ensures:
1. Separation of concerns
2. Testability of individual components
3. Clean dependencies flowing from UI to data layer
4. Loose coupling through interfaces and dependency injection

## Component Interaction Diagrams

### AQI Data Lookup Flow

```
ZipcodeInputForm → [submits] → AQIProvider.fetchData() → AQIRepository.getAQIByZipcode() → AQIRepositoryImpl
                                                                                                 |
                                                                                                 v
                                                                                            CacheManager
                                                                                                 |
                                                                                                 v
                                                                                         [if no valid cache]
                                                                                                 |
                                                                                                 v
                                                                                            ApiClient.getAirQualityByZipCode()
                                                                                                 |
                                                                                                 v
                                                                                         [processes response]
                                                                                                 |
                                                                                                 v
ZipcodeInputForm ← [updates UI] ← AQIProvider ← [updates state] ← AQIRepositoryImpl ← AQIData.fromApiResponse()
```

### Error Handling Flow

```
ApiClient → [error occurs] → ErrorInterceptor → [creates exception] → AQIRepositoryImpl → [catches exception]
                                                                                                 |
                                                                                                 v
                                                                                            ErrorHandler
                                                                                                 |
                                                                                                 v
UI Components ← [updates UI] ← AQIProvider ← [updates error state] ← AQIRepositoryImpl ← [processes or rethrows]
```

### Cache Validation Flow

```
AQIData → [creates] → observationTime + validUntil → [stored in] → CacheManager → [validates with] → isValid()
                                                                         |
                                                                         v
                                                            [gets current time in observation timezone]
                                                                         |
                                                                         v
                                                             [compares with validUntil]
                                                                         |
                                                                         v
                                                                 [returns validity]
``` 