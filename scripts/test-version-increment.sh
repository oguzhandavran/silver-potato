#!/bin/bash
# Script to test version increment logic locally
# This mimics what the GitHub Actions workflow does

set -e

echo "=== Version Increment Test Script ==="
echo ""

# Get the latest git tag or default to v1.0.0
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
echo "✓ Latest tag: $LATEST_TAG"

# Remove 'v' prefix if present
VERSION=${LATEST_TAG#v}
echo "✓ Current version: $VERSION"

# Split version into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
echo "  - Major: $MAJOR"
echo "  - Minor: $MINOR"
echo "  - Patch: $PATCH"

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
echo ""
echo "✓ New version: $NEW_VERSION"

# Calculate versionCode (major*10000 + minor*100 + patch)
VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + NEW_PATCH))
echo "✓ Version code: $VERSION_CODE"

# Show what would be in pubspec.yaml
echo ""
echo "=== pubspec.yaml update ==="
echo "Current line:"
grep "^version:" pubspec.yaml
echo ""
echo "Would become:"
echo "version: $NEW_VERSION+$VERSION_CODE"

echo ""
echo "=== Tag that would be created ==="
echo "v$NEW_VERSION"

echo ""
echo "=== Test Complete ==="
echo "No files were modified. This is a dry-run only."
echo ""
echo "To actually bump versions:"
echo "1. For patch: Just push to main (automatic)"
echo "2. For minor: git tag v$MAJOR.$((MINOR + 1)).0 && git push origin v$MAJOR.$((MINOR + 1)).0"
echo "3. For major: git tag v$((MAJOR + 1)).0.0 && git push origin v$((MAJOR + 1)).0.0"
