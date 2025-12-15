# Flutter Shell

A modern Flutter 3 application with integrated AI capabilities, state management using Riverpod, local data persistence with Hive, and background service support.

## Features

- **Flutter 3** with Material 3 design
- **State Management**: Riverpod and Provider for reactive UI
- **Local Storage**: Hive + hive_flutter for persistent data
- **Permissions**: permission_handler for runtime permission management
- **Background Services**: flutter_background_service for long-running tasks
- **Audio Support**: audio_session for audio playback and recording
- **AI Integration**: Google Generative AI for intelligent suggestions
- **Networking**: http client for API communication

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration and theme
├── services/              # Application services and providers
│   ├── app_state.dart     # Global app state (Riverpod)
│   └── README.md
├── data/                  # Data models and repositories
│   └── README.md
├── features/              # Feature modules
│   ├── home/              # Home screen feature
│   ├── suggestions/       # AI suggestions feature
│   └── README.md
└── widgets/               # Reusable UI components
    └── README.md
```

## Getting Started

### Prerequisites

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Android SDK 21+ (minSdkVersion)
- Android Gradle Plugin compatible with Flutter 3
- Kotlin 1.9.10

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd flutter_shell
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code** (for Hive and other code generators):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Configuration

#### Android-specific Setup

The project is configured to target Android with the following versions:
- **compileSdkVersion**: 34
- **minSdkVersion**: 21
- **targetSdkVersion**: 34
- **Kotlin**: 1.9.10

##### Android Context Collectors (stubs)

This repository includes Android-only stub integrations for context capture (NotificationListenerService, AccessibilityService, UsageStatsManager summaries, and a foreground audio feature service).

See: [`docs/android-context-collectors.md`](docs/android-context-collectors.md)

Required Android permissions are declared in `android/app/src/main/AndroidManifest.xml`:
- **POST_NOTIFICATIONS**: Required for push notifications and background notifications
- **RECORD_AUDIO**: Required for voice commands and audio recording features
- **FOREGROUND_SERVICE**: Required to run long-lived foreground services
- **FOREGROUND_SERVICE_MICROPHONE**: Required for foreground services that use the microphone (Android 14+)
- **QUERY_ALL_PACKAGES**: Required to monitor system accessibility features and user behavior
- **PACKAGE_USAGE_STATS**: Required for app usage analytics and tracking
- **WAKE_LOCK**: Required to keep the app running in the background
- **INTERNET**: Required for API calls and data synchronization

### Running the App

#### On Android Device/Emulator

```bash
flutter run
```

#### Release Build

```bash
flutter build apk --release
```

Or for Android App Bundle:

```bash
flutter build appbundle --release
```

### Testing

#### Run all tests

```bash
flutter test
```

#### Run tests with coverage

```bash
flutter test --coverage
```

### Code Analysis

Run the analyzer to check for code issues:

```bash
flutter analyze
```

This project follows strict linting rules defined in `analysis_options.yaml`.

## Dependencies

### Core Dependencies

- **riverpod (^2.4.0)** & **flutter_riverpod (^2.4.0)**: State management
- **provider (^6.0.0)**: Additional provider functionality
- **hive (^2.2.3)** & **hive_flutter (^1.1.0)**: Local database
- **permission_handler (^11.4.3)**: Runtime permissions
- **flutter_background_service (^5.0.5)**: Background task execution
- **audio_session (^0.1.13)**: Audio playback and recording
- **google_generative_ai (^0.4.0)**: AI API integration
- **http (^1.1.0)**: HTTP client

### Dev Dependencies

- **build_runner (^2.4.4)**: Code generation
- **hive_generator (^2.0.0)**: Hive model generation
- **flutter_lints (^3.0.0)**: Flutter linting rules

## Architecture

### State Management

The app uses **Riverpod** for global state management with a centralized `AppState` provider in `lib/services/app_state.dart`. This provides:
- Loading states
- Error handling
- App versioning
- Access to all features

### Feature-based Structure

Each feature (home, suggestions) is a self-contained module with its own screens and logic, making the codebase scalable and maintainable.

### Background Services

The app supports long-running background tasks using `flutter_background_service`, ideal for:
- Audio processing
- Periodic sync operations
- Voice command listening
- Sensor monitoring

## API Integration

The app integrates with Google Generative AI for intelligent suggestions. Set up your API key in the environment or configuration file before using AI features.

## CI/CD and Versioning

This project uses GitHub Actions for automated builds and semantic versioning.

### Automatic Versioning

On every push to `main`, the workflow automatically:
- ✅ Increments the patch version (1.0.0 → 1.0.1 → 1.0.2)
- ✅ Runs tests and analysis
- ✅ Builds a release APK
- ✅ Creates a GitHub Release with the APK

### Manual Version Bumps

For **minor** or **major** version bumps, create a git tag before pushing:

```bash
# Bump to v1.3.0 (new features)
git tag v1.3.0
git push origin v1.3.0

# Bump to v2.0.0 (breaking changes)
git tag v2.0.0
git push origin v2.0.0
```

### Documentation

- 📖 [Version Management Guide](docs/version-management.md) - Complete versioning guide
- 🔐 [GitHub Secrets Setup](docs/github-secrets-setup.md) - APK signing configuration
- ⚡ [Quick Reference](docs/version-quick-reference.md) - Common commands

### APK Signing

Configure these GitHub Secrets for production builds:
- `KEYSTORE_BASE64` - Base64-encoded keystore file
- `KEY_STORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password
- `KEY_ALIAS` - Key alias name

See the [GitHub Secrets Setup Guide](docs/github-secrets-setup.md) for detailed instructions.

## Contributing

When adding new features:
1. Create a new folder under `lib/features/`
2. Use Riverpod for state management
3. Follow the existing code style and structure
4. Run `flutter analyze` and `flutter test` before committing
5. Update this README with any new features or dependencies

## Troubleshooting

### Build Issues

If you encounter build errors:

1. Clean the project:
   ```bash
   flutter clean
   ```

2. Get fresh dependencies:
   ```bash
   flutter pub get
   ```

3. Regenerate code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Android Issues

- Ensure you have the correct Android SDK version (API 34)
- Check that Kotlin version matches (1.9.10)
- Verify `local.properties` has the correct Android SDK path

### Code Analysis Warnings

Run `flutter analyze` to identify and fix any code issues. The project is configured with strict linting rules.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions, please open an issue in the repository.
