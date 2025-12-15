#!/bin/bash
# Build script for Flutter Shell Release APK
# This script automates the build process with validation steps

set -e  # Exit on error

echo "========================================"
echo "Flutter Shell - Release Build Script"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found${NC}"
flutter --version
echo ""

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo -e "${YELLOW}Warning: ANDROID_HOME not set${NC}"
    echo "Attempting to locate Android SDK..."
    
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
        echo -e "${GREEN}✓ Found Android SDK at $ANDROID_HOME${NC}"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
        echo -e "${GREEN}✓ Found Android SDK at $ANDROID_HOME${NC}"
    else
        echo -e "${RED}Error: Could not find Android SDK${NC}"
        echo "Please install Android Studio or set ANDROID_HOME manually"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Android SDK configured${NC}"
echo ""

# Navigate to project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "Project directory: $PROJECT_DIR"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to get dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dependencies resolved${NC}"
echo ""

# Run static analysis
echo "Running static analysis..."
flutter analyze > /tmp/flutter_analyze.log 2>&1
ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -ne 0 ]; then
    echo -e "${YELLOW}Warning: Static analysis found issues${NC}"
    echo "Check /tmp/flutter_analyze.log for details"
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Static analysis passed${NC}"
fi
echo ""

# Run tests (optional, with confirmation)
echo "Run tests before building? (y/n)"
read -r run_tests
if [[ "$run_tests" =~ ^[Yy]$ ]]; then
    echo "Running tests..."
    flutter test
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Some tests failed${NC}"
        echo "Continue with build? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ All tests passed${NC}"
    fi
    echo ""
fi

# Check for signing configuration
if [ ! -f "android/key.properties" ]; then
    echo -e "${YELLOW}Warning: android/key.properties not found${NC}"
    echo "The APK will be signed with debug keys"
    echo "For production release, create key.properties file"
    echo "See BUILD_AND_RELEASE.md for instructions"
    echo ""
    echo "Continue with debug signing? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build release APK
echo "Building release APK..."
echo "This may take several minutes..."
flutter build apk --release

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================"
echo "✓ Build completed successfully!"
echo "========================================${NC}"
echo ""

# Locate the APK
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "APK Location: $APK_PATH"
    echo "APK Size: $APK_SIZE"
    echo ""
    
    # Get APK info
    if command -v aapt &> /dev/null; then
        echo "APK Information:"
        aapt dump badging "$APK_PATH" | grep -E "package:|sdkVersion:|targetSdkVersion:"
        echo ""
    fi
    
    echo "To install on a connected device:"
    echo "  adb install -r $APK_PATH"
    echo ""
    echo "For installation instructions, see:"
    echo "  BUILD_AND_RELEASE.md"
else
    echo -e "${YELLOW}Warning: APK file not found at expected location${NC}"
    echo "Search for APK files in build directory:"
    find build -name "*.apk" -type f
fi

echo ""
echo "Build log saved to: /tmp/flutter_build_release.log"
