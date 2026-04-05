# BloomSafe

Cross-platform Flutter app for air-quality monitoring focused on fertility and pregnancy.

## What It Does
BloomSafe translates PM2.5 air quality data into a reproductive-health-oriented experience for users who are trying to conceive or are pregnant. The product combines AQI lookup, tailored guidance, educational content, caching, and lightweight analytics/error monitoring in a single mobile app.

This repository is being published as a public record of the product and codebase. It has been scrubbed for public sharing, so live third-party credentials and production Firebase configuration are intentionally not included.

## Tech Stack
- Flutter and Dart
- Provider and GetIt
- Dio and http
- AirNow API
- Firebase Core and Firebase Analytics
- Sentry
- flutter_secure_storage and shared_preferences

## Key Features
- PM2.5 AQI lookup by ZIP code
- Reproductive-health-specific severity tiers and recommendations
- Guide and learn sections with curated educational content
- Local caching and rate-limiting safeguards
- Error handling, privacy-aware logging, and optional monitoring integrations
- Separate development and production entry points via Flutter flavors

## Build Locally
```bash
flutter pub get
cp .env.dev.template .env.dev
cp .env.prod.template .env.prod
flutter run --flavor dev -t lib/main_dev.dart
```

Populate `.env.dev` and `.env.prod` with your own values before building. `AIRNOW_API_KEY` is required for live API calls. `DISCORD_WEBHOOK_URL`, `SENTRY_DSN`, and `FIREBASE_ANALYTICS_ENABLED` are optional depending on how much of the original stack you want to enable.

Firebase is left in a placeholder state for the public repo:
- Add your own `android/app/google-services.json` locally if you want Android Firebase support.
- Replace the placeholder values in `lib/core/config/firebase/firebase_options.dart`, or regenerate that file with FlutterFire for your own project.

Common commands:
```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
flutter build apk --flavor prod -t lib/main_prod.dart
flutter build ios --flavor prod -t lib/main_prod.dart
```

## Tests
```bash
flutter test
flutter test test/path/to/test_file.dart
```

Rate-intensive tests that validate rate limiting are skipped by default:
```bash
flutter test --run-skipped test/intensive/
```

## Documentation

Documentation is available in the `/docs` folder:

- [**Data Flow**](docs/data_flow.md) - Complete data flow through the application
- [**Component Structure**](docs/component_structure.md) - Breakdown of component responsibilities
- [**Caching System**](docs/caching_system.md) - In-depth explanation of caching with timezone handling
- [**Error Handling & Rate Limiting**](docs/error_handling_and_rate_limiting.md) - Error handling and rate limiting details
- [**Security Implementation**](docs/security_implementation.md) - Security measures and implementation details
- [**Tech Stack**](docs/tech_stack.md) - Detailed technology stack breakdown

## Current Status
BloomSafe previously shipped on the App Store as an MVP. The app has since been retracted while I moved on to a new project, and this repository is now public as part of a startup accelerator application.

## License

This project is proprietary and confidential.
