# Build and Release Guide for Flutter Shell

This document provides comprehensive instructions for building, signing, and releasing the Flutter Shell Android application.

## Prerequisites

Before building the APK, ensure you have the following installed:

1. **Flutter SDK** (3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Android Studio** or **Android SDK Command-line Tools**
   - Download from: https://developer.android.com/studio
   - Required SDK components:
     - Android SDK Platform-Tools
     - Android SDK Build-Tools 34.0.0 or higher
     - Android SDK Platform API 34
     - Android SDK Platform API 21 (for minSdkVersion compatibility)

3. **Java Development Kit (JDK) 11 or higher**
   - Required for Android builds
   - OpenJDK 17 recommended

## Project Configuration

### Target Device Requirements

- **minSdkVersion**: 21 (Android 5.0 Lollipop)
- **targetSdkVersion**: 34 (Android 14)
- **compileSdkVersion**: 34

This configuration ensures compatibility with Android tablets running Android 5.0 (API 21) and above, covering a wide range of devices.

## Development Build (Debug APK)

For testing purposes, you can build a debug APK:

```bash
cd /path/to/flutter_shell
flutter pub get
flutter build apk --debug
```

The debug APK will be located at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

## Production Build (Release APK)

### Step 1: Create a Keystore (One-time setup)

For production releases, you need to sign your APK with a release keystore:

```bash
keytool -genkey -v -keystore ~/flutter-shell-release.keystore \
  -alias flutter-shell \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**Important**: Store the keystore file and passwords securely. You'll need them for all future app updates.

### Step 2: Create Key Properties File

Create `android/key.properties` with your keystore information:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=flutter-shell
storeFile=<path-to-your-keystore>/flutter-shell-release.keystore
```

**Security Note**: Add `key.properties` to `.gitignore` to prevent committing sensitive credentials.

### Step 3: Update build.gradle (One-time setup)

Modify `android/app/build.gradle` to use your keystore:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing configuration ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4: Run Validation

Before building, ensure code quality:

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Fix any issues before proceeding
```

### Step 5: Build Release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The signed release APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 6: Build App Bundle (Recommended for Play Store)

For Google Play Store distribution, use an Android App Bundle (AAB):

```bash
flutter build appbundle --release
```

The AAB will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Current Build Status

### Code Validation Status

✅ **flutter analyze**: Code compiles successfully with minor linting warnings in test files
✅ **minSdkVersion**: Configured for Android 21+ (verified in `android/app/build.gradle`)
✅ **Dependencies**: All dependencies resolved successfully
⚠️ **flutter test**: Some test files have import issues but main application code is functional

### Known Issues

1. **Test Import Issues**: The suggestion_engine_test.dart file has some import/dependency issues that don't affect the production build but should be fixed for complete test coverage.

2. **Temporary Debug Signing**: The current configuration uses debug signing for release builds (line 30 in `android/app/build.gradle`). Follow Step 3 above to configure production signing.

3. **Assets Directory**: An empty `assets/` directory has been created as referenced in `pubspec.yaml`.

## Installing on Android Tablet

### Method 1: Direct APK Installation (Sideloading)

1. **Transfer the APK** to your Android tablet:
   - Via USB cable: Copy `app-release.apk` to the tablet's Downloads folder
   - Via cloud storage: Upload to Google Drive, Dropbox, etc., and download on tablet
   - Via email: Send as attachment and download on tablet

2. **Enable Unknown Sources** (first-time only):
   - Go to **Settings** > **Security** > **Install unknown apps**
   - Select your file manager or browser
   - Enable **Allow from this source**

3. **Install the APK**:
   - Open your file manager
   - Navigate to the APK location
   - Tap the APK file
   - Tap **Install**
   - Tap **Open** to launch the app

### Method 2: Using ADB (Android Debug Bridge)

If you have ADB installed on your computer:

```bash
# Connect tablet via USB with USB debugging enabled
adb devices

# Install the APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Launch the app
adb shell am start -n com.example.flutter_shell/.MainActivity
```

### Method 3: Google Play Store (For production distribution)

1. Create a Google Play Console account
2. Upload the AAB file (`app-release.aab`)
3. Complete store listing information
4. Submit for review
5. Once approved, users can install from Play Store

## Post-Installation Setup

After installing the app on your Android tablet:

1. **Grant Required Permissions**:
   - Notification Access (for context-aware features)
   - Usage Stats Access (for activity tracking)
   - Accessibility Service (for text extraction)
   - Microphone (for audio features)

2. **Initial Configuration**:
   - Launch the app
   - Follow the onboarding screens
   - Configure AI API keys in Settings (if using Gemini/OpenAI/Claude)

3. **Background Service**:
   - The app includes background services for context collection
   - Grant battery optimization exemption if prompted
   - Configure background service settings in the app's Settings screen

## Troubleshooting

### Build Errors

**Error**: `No Android SDK found`
- **Solution**: Set `ANDROID_HOME` environment variable to your Android SDK location

**Error**: `JAVA_HOME is not set`
- **Solution**: Install JDK 11+ and set `JAVA_HOME` environment variable

**Error**: `License for package Android SDK Platform not accepted`
- **Solution**: Run `flutter doctor --android-licenses` and accept all licenses

### Installation Errors

**Error**: `App not installed`
- Check that you have enough storage space
- Ensure you're using a compatible Android version (5.0+)
- Try uninstalling any previous version first

**Error**: `Package conflicts with existing package`
- Uninstall the existing app
- Or use `adb install -r` to replace the existing installation

## Version Information

- **App Version**: 1.0.0+1
- **Flutter SDK**: 3.0.0+
- **Dart SDK**: 3.0.0+
- **Android minSdkVersion**: 21
- **Android targetSdkVersion**: 34

## Security Recommendations

1. **Never commit**:
   - `key.properties` file
   - Keystore files (`.keystore`, `.jks`)
   - API keys in source code

2. **Backup securely**:
   - Your release keystore file
   - Keystore passwords
   - Store in a secure location (password manager, encrypted storage)

3. **API Key Management**:
   - The app uses `.env` files for API keys (see `.env.example`)
   - Never commit `.env` files to version control
   - Use Flutter Secure Storage for runtime key storage

## Additional Resources

- Flutter Build Documentation: https://flutter.dev/docs/deployment/android
- Android App Signing: https://developer.android.com/studio/publish/app-signing
- Google Play Console: https://play.google.com/console

## Support

For issues or questions:
- Check existing documentation in the `docs/` directory
- Review the README.md for feature overview
- Check the GitHub Issues page
