# CI/CD Overview

This document provides an overview of the Continuous Integration and Continuous Deployment (CI/CD) setup for the Flutter Shell project.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workflow                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Code Changes → Commit → Push to main                    │
│                                                              │
│  2. [Optional] Create git tag for major/minor versions      │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│               GitHub Actions Workflow                        │
│         (.github/workflows/flutter-build.yml)                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✓ Extract latest version tag                               │
│  ✓ Auto-increment patch version                             │
│  ✓ Update pubspec.yaml                                      │
│  ✓ Configure Android signing (if secrets present)           │
│  ✓ Run flutter analyze                                      │
│  ✓ Run flutter test                                         │
│  ✓ Build release APK                                        │
│  ✓ Create GitHub Release                                    │
│  ✓ Commit version updates                                   │
│  ✓ Upload APK artifact                                      │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Release                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  • Semantic version tag (e.g., v1.0.1)                      │
│  • Release notes with version details                       │
│  • Downloadable APK: flutter-shell-v1.0.1.apk               │
│  • Commit with updated version numbers                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. GitHub Actions Workflow

**File**: `.github/workflows/flutter-build.yml`

**Trigger**: Push to `main` branch

**Key Features**:
- Automatic semantic versioning
- Flutter analysis and testing
- Release APK building
- APK signing (with secrets)
- GitHub Release creation
- Version commit automation

### 2. Version Management Scripts

**File**: `scripts/test-version-increment.sh`

**Purpose**: Local testing of version increment logic without modifying files

**Usage**:
```bash
./scripts/test-version-increment.sh
```

### 3. Android Build Configuration

**File**: `android/app/build.gradle`

**Features**:
- Dynamic keystore loading from `key.properties`
- Fallback to debug signing if no keystore
- Version code/name from Flutter (pubspec.yaml)
- Release build configuration

### 4. Documentation

| Document | Purpose |
|----------|---------|
| [version-management.md](version-management.md) | Complete guide to versioning |
| [github-secrets-setup.md](github-secrets-setup.md) | APK signing configuration |
| [version-quick-reference.md](version-quick-reference.md) | Quick command reference |
| [ci-cd-overview.md](ci-cd-overview.md) | This document |

## Semantic Versioning

### Format: MAJOR.MINOR.PATCH

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features (backward-compatible)
- **PATCH** (0.0.X): Bug fixes (backward-compatible)

### Version Examples

```
v1.0.0  → Initial release
v1.0.1  → Bug fix (automatic)
v1.0.2  → Another bug fix (automatic)
v1.1.0  → New feature (manual tag)
v1.1.1  → Bug fix (automatic)
v2.0.0  → Breaking change (manual tag)
v2.0.1  → Bug fix (automatic)
```

## Workflow Stages

### Stage 1: Version Calculation

```bash
# Get latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")

# Increment patch
VERSION=${LATEST_TAG#v}  # Remove 'v' prefix
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

# Calculate version code
VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + NEW_PATCH))
```

### Stage 2: File Updates

**pubspec.yaml**:
```yaml
# Before
version: 1.0.0+1

# After
version: 1.0.1+10001
```

### Stage 3: Quality Checks

```bash
flutter analyze  # Static analysis
flutter test     # Unit tests
```

If either fails, the workflow stops and no release is created.

### Stage 4: Build Process

**Without Signing Secrets**:
```bash
flutter build apk --release
# Uses debug signing
# APK can be installed but not published to Play Store
```

**With Signing Secrets**:
```bash
# Creates android/key.properties from secrets
# Creates android/app/upload-keystore.jks from base64
flutter build apk --release
# Uses production signing
# APK ready for Play Store
```

### Stage 5: Release Creation

- **Tag**: `v1.0.1`
- **Name**: `Release v1.0.1`
- **APK**: `flutter-shell-v1.0.1.apk`
- **Notes**: Automated release notes with version details

### Stage 6: Version Commit

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.1 [skip ci]"
git push origin main
```

Note: `[skip ci]` prevents infinite loop.

## Required GitHub Secrets

| Secret | Description | Required? |
|--------|-------------|-----------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file | Optional* |
| `KEY_STORE_PASSWORD` | Keystore password | Optional* |
| `KEY_PASSWORD` | Key password | Optional* |
| `KEY_ALIAS` | Key alias name | Optional* |

\* Required for production Play Store releases. Without them, debug signing is used.

## Workflow Permissions

```yaml
permissions:
  contents: write  # Required to create releases and push commits
```

## Environment Requirements

### GitHub Actions Runner
- **OS**: ubuntu-latest
- **Java**: 17 (Temurin distribution)
- **Flutter**: 3.19.0 (stable channel)

### Project Requirements
- **Flutter**: >=3.0.0
- **Dart**: >=3.0.0
- **Android SDK**: 21+ (minSdkVersion)
- **Target SDK**: 34

## Branching Strategy

### Main Branch
- **Purpose**: Production-ready code
- **Protection**: All pushes trigger CI/CD
- **Versioning**: Automatic patch increments

### Feature Branches (Recommended)
```
feature/new-feature → Pull Request → main
```

### Release Process
1. Merge feature branch to main
2. Workflow automatically creates release
3. APK available in GitHub Releases

## Troubleshooting

### Workflow Not Running

**Check**:
1. Workflow file exists: `.github/workflows/flutter-build.yml`
2. Branch is `main`
3. Commit doesn't contain `[skip ci]`

### Build Failing

**Common Issues**:
1. `flutter analyze` errors → Fix code issues
2. `flutter test` failures → Fix failing tests
3. Keystore errors → Check secrets configuration

**Local Testing**:
```bash
flutter analyze
flutter test
flutter build apk --release
```

### Version Conflicts

**Solution**:
```bash
# Delete wrong tag
git tag -d v1.0.5
git push origin :refs/tags/v1.0.5

# Workflow will create correct version on next push
```

## Monitoring

### View Workflow Runs
1. Go to repository on GitHub
2. Click **Actions** tab
3. Click on specific workflow run for details

### View Releases
1. Go to repository on GitHub
2. Click **Releases** (right sidebar)
3. Download APK from any release

### View Logs
- Each workflow step has detailed logs
- Failures show error messages
- Build artifacts are downloadable

## Best Practices

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/):

```
fix: resolve login bug
feat: add dark mode
docs: update README
chore: bump dependencies
test: add unit tests
refactor: improve code structure
```

### Version Management
- Let patch versions increment automatically
- Use manual tags only for minor/major versions
- Document breaking changes in CHANGELOG.md

### Testing
- Always run tests locally before pushing
- Add tests for new features
- Fix failing tests immediately

### Security
- Never commit keystore files
- Use GitHub Secrets for sensitive data
- Rotate secrets if compromised
- Store keystore backup securely offline

## Future Enhancements

Potential improvements to consider:

1. **Multi-environment Builds**
   - Development, staging, production configurations
   - Different signing keys per environment

2. **Code Coverage Reports**
   - Integrate code coverage tools
   - Publish coverage reports

3. **Automated Testing**
   - Integration tests
   - UI tests with screenshots

4. **Beta Releases**
   - Pre-release tags for beta testing
   - Separate distribution channels

5. **Release Notes Automation**
   - Generate from commit messages
   - Link to closed issues/PRs

6. **Play Store Publishing**
   - Automated upload to Play Store
   - Beta track distribution

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Semantic Versioning Specification](https://semver.org/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

## Support

For issues or questions:
- Check workflow logs in Actions tab
- Review documentation in `docs/` folder
- Open an issue in the repository
