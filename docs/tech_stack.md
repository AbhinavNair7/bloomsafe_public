# BloomSafe Tech Stack Documentation

## Frontend Implementation

### Flutter Framework
- **Core Technology**: Flutter 3.24.0 (Dart 3.7.2+)
- **State Management**: Provider 6.1.1
- **Target Platforms**: iOS/Android
- **Key Justification**:
  - Single codebase for cross-platform deployment (critical for MVP cost reduction)
  - Hot reload for rapid iteration (essential for solo development)
  - Customizable widget library for health-focused UI

### UI/UX Libraries
| Package | Version | Purpose |
|---------|---------|---------|
| percent_indicator | 4.2.4 | Circular AQI severity gauges |
| cupertino_icons | 1.0.8 | iOS-style iconography |
| url_launcher | 6.2.5 | External link handling |
| share_plus | 10.1.1 | Content sharing functionality |

## Backend Services

### Firebase Suite
| Service | Version | Purpose | Implementation Detail |
|---------|---------|---------|----------------------|
| Firebase Core | 2.24.2 | Platform initialization | Environment-specific projects |
| Firebase Analytics | 10.7.4 | Usage tracking | Custom events: `aqi_lookup`, `educational_content_view` |

**Note**: Authentication and Firestore initially planned but not implemented in current version.

### External APIs

#### AirNow API Integration
- **Endpoint**: `https://www.airnowapi.org/aq/observation/zipCode/current/`
- **Parameters**:
  - `format=application/json`
  - `zipCode={validated 5-digit}`
  - `API_KEY={secured via flutter_secure_storage}`
- **Rate Limiting**: 500 requests/hour, 5 requests/minute
- **Data Structure Focus**: PM2.5 concentration and severity classification

#### Discord Webhook Integration
- **Purpose**: User feedback collection system
- **Implementation**: Replaces Firebase-based feedback due to build conflicts
- **Security**: Webhook URL stored in secure storage

## Data Management

### Storage Solutions
| Type | Technology | Version | Purpose |
|------|------------|---------|---------|
| Secure Storage | flutter_secure_storage | 9.2.4 | API keys, sensitive configuration |
| Cache Storage | shared_preferences | 2.2.2 | AQI data caching with TTL |
| Environment Config | flutter_dotenv | 5.2.1 | Environment-specific settings |

### Caching Strategy
- **TTL**: 2 hours with timezone-aware expiration
- **Scope**: AQI data, rate limit status
- **Cleanup**: Automatic purging of expired entries
- **Fallback**: Memory cache during storage failures

## Development Environment

### Core Tooling
- **IDE**: Cursor AI with Flutter/Dart extensions
- **AI Assistant**: Claude Sonnet 4 (integrated via Cursor)
- **Version Control**: Git 2.42 + GitHub Actions CI/CD
- **Package Management**: pub.dev with version constraints

### Environment Configuration
| Environment | Entry Point | Purpose |
|-------------|-------------|---------|
| Development | main_dev.dart | Mock services, debug features |
| Production | main_prod.dart | Live services, analytics enabled |

### Testing Infrastructure
| Type | Framework | Coverage | Configuration |
|------|-----------|----------|---------------|
| Unit Tests | flutter_test | Target: 85% | Mockito 5.4.5 for mocking |
| Integration Tests | integration_test | Critical flows | E2E user journeys |
| Build Verification | GitHub Actions | All environments | Flutter 3.24.0 runners |

## Security Implementation

### Data Protection
| Layer | Technology | Version | Implementation |
|-------|------------|---------|----------------|
| Encryption | encrypt | 5.0.3 | AES-256 for sensitive data |
| Certificate Pinning | dio + crypto | 5.4.0 + 3.0.3 | HTTPS enforcement |
| Device Security | device_info_plus | 11.4.0 | Root/jailbreak detection |

### Compliance Framework
- **Medical Disclaimer**: Integrated across all AQI recommendations
- **Privacy**: No PII collection, anonymized error reporting
- **Data Retention**: Cache-only storage with automatic expiration

## Monitoring & Analytics

### Error Tracking
- **Platform**: Sentry Flutter 8.14.2
- **Network Monitoring**: sentry_dio 8.14.2
- **Privacy**: Screenshot disabled, no PII capture
- **Sampling**: 20% transaction monitoring

### Analytics Implementation
- **Platform**: Firebase Analytics 10.7.4
- **Custom Events**: AQI lookups, educational engagement, sharing activity
- **Environment Tagging**: Separate tracking for dev/prod

## Deployment Strategy

### Build Configuration
| Platform | Command | Flavor | Output |
|----------|---------|--------|--------|
| iOS Dev | `flutter build ios --flavor dev -t lib/main_dev.dart` | dev | .ipa |
| iOS Prod | `flutter build ios --flavor prod -t lib/main_prod.dart` | prod | .ipa |
| Android Dev | `flutter build apk --flavor dev -t lib/main_dev.dart` | dev | .apk |
| Android Prod | `flutter build appbundle --flavor prod -t lib/main_prod.dart` | prod | .aab |

### App Store Configuration
| Platform | Bundle ID | Version | Store |
|----------|-----------|---------|-------|
| iOS Production | com.bloomsafe.app | 1.0.0+1 | App Store Connect |
| iOS Development | com.bloomsafe.app.dev | 1.0.0+1 | TestFlight |
| Android Production | com.bloomsafe.app | 1.0.0+1 | Google Play Console |
| Android Development | com.bloomsafe.app.dev | 1.0.0+1 | Internal Testing |

## Network Architecture

### HTTP Client Configuration
- **Library**: Dio 5.4.0
- **Interceptors**: Logging, error handling, Sentry integration
- **Timeout**: 30 seconds for API requests
- **Retry Logic**: Exponential backoff for transient failures

### Rate Limiting
- **Implementation**: Local tracking with secure storage persistence
- **Limits**: AirNow API constraints (500/hour, 5/minute)
- **Lockout**: 10-minute cooling period after limit exceeded
- **Status Tracking**: Warning at 70%, critical at 90%

## Utilities & Helpers

### Time Management
| Package | Version | Purpose |
|---------|---------|---------|
| timezone | 0.10.0 | Multi-timezone AQI data handling |
| intl | 0.20.2 | Date formatting and localization |

### Development Tools
| Package | Version | Purpose |
|---------|---------|---------|
| flutter_lints | 5.0.0 | Code quality enforcement |
| build_runner | 2.4.15 | Code generation |
| json_serializable | 6.7.1 | Model serialization |

### Device Integration
| Package | Version | Purpose |
|---------|---------|---------|
| package_info_plus | 8.3.0 | App version tracking |
| device_info_plus | 11.4.0 | Device capability detection |

## AI Development Integration

### Cursor AI Configuration
- **Model**: Claude Sonnet 4
- **Integration**: Real-time code assistance
- **Workflow**: Pair programming approach with human oversight
- **Code Quality**: Automated adherence to project patterns and constraints

## Version Control Strategy

### Branch Management
- **Main Branch**: Production-ready code
- **Feature Branches**: Individual feature development
- **Commit Convention**: Conventional Commits standard

### CI/CD Pipeline
- **Trigger**: Push to main, pull requests
- **Stages**: Code analysis → Testing → Build verification → Coverage reporting
- **Artifacts**: APK builds, coverage reports
- **Environment**: Ubuntu runners with Flutter 3.24.0

---

**Last Updated**: 01/06/2025  
**Documentation Version**: 1.0  
**Maintained By**: Development team via automated updates