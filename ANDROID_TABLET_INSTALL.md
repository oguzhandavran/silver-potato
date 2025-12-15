# Android Tablet Installation Guide

This guide provides step-by-step instructions for installing Flutter Shell on your Android tablet.

## System Requirements

- **Android Version**: 5.0 (Lollipop) or higher
- **Storage Space**: At least 100 MB free space
- **RAM**: 2 GB or more recommended for optimal performance
- **Internet Connection**: Required for AI features (Gemini, OpenAI, Claude integration)

## Installation Methods

### Method 1: Sideloading APK (Recommended for Testing)

#### Step 1: Download the APK

1. Download `app-release.apk` to your computer
2. The APK file size is approximately 20-50 MB

#### Step 2: Transfer APK to Tablet

Choose one of these methods:

**Option A: USB Cable**
1. Connect your tablet to your computer via USB
2. On your tablet, swipe down and tap "USB charging this device"
3. Select "File Transfer" or "MTP" mode
4. Copy `app-release.apk` to your tablet's Downloads folder
5. Safely disconnect the USB cable

**Option B: Cloud Storage (Google Drive, Dropbox)**
1. Upload `app-release.apk` to your cloud storage from computer
2. Open the cloud storage app on your tablet
3. Download the APK file to your tablet
4. Note the download location (usually Downloads folder)

**Option C: Email**
1. Email the APK to yourself as an attachment
2. Open the email on your tablet
3. Download the attachment
4. Note the download location

#### Step 3: Enable Installation from Unknown Sources

**For Android 8.0 (Oreo) and higher:**
1. Open **Settings** on your tablet
2. Go to **Apps & notifications** (or just **Apps**)
3. Tap **Advanced** > **Special app access**
4. Tap **Install unknown apps**
5. Select the app you'll use to install the APK (e.g., **Files**, **Downloads**, or your browser)
6. Enable **Allow from this source**

**For Android 7.1 (Nougat) and lower:**
1. Open **Settings** on your tablet
2. Go to **Security** or **Lock screen and security**
3. Enable **Unknown sources**
4. Confirm the warning message

#### Step 4: Install the APK

1. Open your **Files** app or **Downloads** app
2. Navigate to where you saved `app-release.apk`
3. Tap on the APK file
4. Review the permissions required by the app
5. Tap **Install**
6. Wait for installation to complete (usually 10-30 seconds)
7. Tap **Open** to launch the app, or **Done** to finish

#### Step 5: Disable Unknown Sources (Security Best Practice)

After installation, it's recommended to disable unknown sources:
1. Go back to **Settings** > **Security** or **Apps**
2. Disable **Unknown sources** or **Install unknown apps** for the file manager you used

### Method 2: ADB Installation (For Advanced Users)

If you have Android Debug Bridge (ADB) set up:

#### Prerequisites
1. Install ADB on your computer:
   - **Windows**: Download Platform Tools from Google
   - **Mac/Linux**: `brew install android-platform-tools` or use package manager

2. Enable USB Debugging on your tablet:
   - Go to **Settings** > **About tablet**
   - Tap **Build number** 7 times to enable Developer options
   - Go back to **Settings** > **Developer options**
   - Enable **USB debugging**

#### Installation Steps

1. Connect your tablet via USB
2. Open a terminal/command prompt on your computer
3. Verify connection:
   ```bash
   adb devices
   ```
   You should see your device listed

4. Install the APK:
   ```bash
   adb install -r app-release.apk
   ```
   The `-r` flag allows reinstallation and keeps app data if updating

5. Launch the app:
   ```bash
   adb shell am start -n com.example.flutter_shell/.MainActivity
   ```

### Method 3: Wireless ADB (No USB Cable Required)

If your tablet and computer are on the same WiFi network:

1. Enable USB debugging (see Method 2)
2. Connect tablet via USB initially
3. Enable wireless debugging:
   ```bash
   adb tcpip 5555
   ```
4. Find your tablet's IP address:
   - Settings > About tablet > Status > IP address
5. Disconnect USB and connect wirelessly:
   ```bash
   adb connect <tablet-ip-address>:5555
   ```
6. Install as in Method 2:
   ```bash
   adb install -r app-release.apk
   ```

## Initial Setup

After installation, follow these steps:

### 1. Grant Permissions

When you first launch the app, you'll be asked to grant various permissions:

#### Critical Permissions (Required for core functionality)
- **Notifications**: Allows the app to show suggestions and alerts
- **Background**: Allows the app to run context collection in the background

#### Optional Permissions (Required for specific features)
- **Usage Access**: Enable in Settings > Special app access > Usage access
  - Required for activity-aware suggestions
- **Accessibility Service**: Enable in Settings > Accessibility
  - Required for text extraction features
- **Microphone**: For audio analysis features (if enabled)

### 2. Configure AI Services

Flutter Shell integrates with multiple AI providers:

1. Open the app's **Settings**
2. Navigate to **AI Configuration**
3. Choose your preferred provider(s):
   - **Google Gemini** (recommended for most users)
   - **OpenAI GPT-4**
   - **Anthropic Claude**
4. Enter your API key(s)
5. Test the connection

**Getting API Keys:**
- Gemini: https://makersuite.google.com/app/apikey
- OpenAI: https://platform.openai.com/api-keys
- Claude: https://console.anthropic.com/

### 3. Configure Context Collection

1. Go to **Settings** > **Privacy & Data**
2. Choose which context sources to enable:
   - Notification monitoring
   - App usage tracking
   - Accessibility text extraction
   - Audio feature analysis
3. Review and accept the privacy policy

### 4. Enable Background Service

For continuous context awareness:

1. Go to **Settings** > **Battery**
2. Find **Flutter Shell** in the app list
3. Set battery optimization to **Don't optimize** or **Unrestricted**
4. This allows the app to run in the background

### 5. Customize Suggestion Engine

1. Open **Settings** > **Suggestions**
2. Configure:
   - Auto-send preferences (disabled by default)
   - Temporal profiles (morning, afternoon, evening, night)
   - Suggestion types to enable
   - Daily limits per suggestion type
   - Cooldown periods

## Using the App

### Main Features

1. **Context Dashboard**: View collected context events
2. **AI Chat**: Interact with AI assistants
3. **Suggestions**: Review and manage AI-generated suggestions
4. **Settings**: Customize app behavior and privacy settings

### Suggestion Approval Workflow

By default, all AI suggestions require manual approval:

1. Navigate to **Suggestions** screen
2. Review pending suggestions
3. Choose to:
   - **Approve**: Mark as good suggestion
   - **Reject**: Dismiss the suggestion
   - **Send**: Immediately use the suggestion
4. Approved suggestions are tracked for learning

### Privacy Controls

- **Pause Data Collection**: Settings > Privacy > Pause Collection
- **Clear Context History**: Settings > Privacy > Clear Data
- **Export Data**: Settings > Privacy > Export Context
- **Delete Account Data**: Settings > Privacy > Delete All Data

## Troubleshooting

### Installation Issues

**Problem**: "App not installed" error
- **Solution**: 
  - Check available storage space (need at least 100 MB)
  - Verify Android version is 5.0 or higher
  - Try uninstalling any previous version first

**Problem**: "Package conflicts with an existing package by the same name"
- **Solution**: Uninstall the existing app first:
  - Settings > Apps > Flutter Shell > Uninstall

**Problem**: "App not installed as package appears to be invalid"
- **Solution**:
  - Re-download the APK (file may be corrupted)
  - Ensure you're installing the correct APK for your architecture

### Runtime Issues

**Problem**: App crashes on startup
- **Solution**:
  - Clear app data: Settings > Apps > Flutter Shell > Storage > Clear Data
  - Ensure all required permissions are granted
  - Check if device meets minimum requirements

**Problem**: Suggestions not generating
- **Solution**:
  - Verify AI API keys are configured correctly
  - Check internet connection
  - Ensure required permissions are granted
  - Check that context collection is enabled

**Problem**: Background service stops
- **Solution**:
  - Disable battery optimization for the app
  - Check that background data is enabled
  - Some aggressive battery savers may need to be disabled

**Problem**: High battery usage
- **Solution**:
  - Reduce context collection frequency in Settings
  - Disable unused context sources
  - Lower AI query frequency

### Permission Issues

**Problem**: Can't find Usage Access setting
- **Solution**: Settings > Apps > Special app access > Usage access > Flutter Shell > Enable

**Problem**: Can't find Accessibility setting
- **Solution**: Settings > Accessibility > Downloaded services > Flutter Shell > Enable

**Problem**: Notification permission denied
- **Solution**: Settings > Apps > Flutter Shell > Permissions > Notifications > Allow

## Updating the App

To install a new version:

1. Download the new APK
2. Install it using the same method as initial installation
3. The new version will install over the old one
4. Your settings and data will be preserved

**Note**: If you disabled "Unknown sources" after initial installation, you'll need to re-enable it for updates.

## Uninstalling

To remove Flutter Shell from your tablet:

1. Go to **Settings** > **Apps**
2. Find and tap **Flutter Shell**
3. Tap **Uninstall**
4. Confirm the uninstallation

**Note**: This will remove all app data, settings, and collected context. Export any data you want to keep before uninstalling.

## Security & Privacy

### Data Storage
- All sensitive data (API keys) is encrypted using Flutter Secure Storage
- Context data is stored locally on your device
- No data is sent to external servers except AI API calls

### Network Usage
- The app only connects to:
  - Configured AI service providers (Gemini, OpenAI, Claude)
  - No analytics or tracking services are used

### Permissions Explained
- **Notifications**: Read notifications for context (never sent externally)
- **Usage Access**: Track app usage patterns locally
- **Accessibility**: Extract text from screen for suggestions
- **Microphone**: Optional audio analysis features
- **Background**: Run context collection service

## Support

For help or issues:

1. Check the in-app Help section
2. Review documentation in the GitHub repository
3. Submit issues via GitHub Issues page
4. Contact support email (if provided)

## Technical Specifications

- **Package Name**: com.example.flutter_shell
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Architecture**: ARM, ARM64, x86, x86_64 (universal APK)
- **Version**: 1.0.0 (Build 1)

## Additional Resources

- **User Guide**: See README.md in the repository
- **Privacy Policy**: See PRIVACY.md
- **API Documentation**: See docs/ folder
- **Suggestion Engine Guide**: See docs/suggestion_engine_extension_guide.md
