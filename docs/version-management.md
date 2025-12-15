# Version Management Guide

This guide explains how automatic semantic versioning works in this project and how to manage version bumps.

## Overview

The project uses GitHub Actions to automatically manage version numbers following [Semantic Versioning](https://semver.org/) principles:

- **MAJOR version** (X.0.0): Incompatible API changes
- **MINOR version** (0.X.0): New functionality in a backward-compatible manner
- **PATCH version** (0.0.X): Backward-compatible bug fixes

## Automatic Patch Version Updates

On every push to the `main` branch, the GitHub Actions workflow automatically:

1. ✅ Extracts the latest git tag (e.g., `v1.0.5`)
2. ✅ Increments the **patch** version (`v1.0.5` → `v1.0.6`)
3. ✅ Updates `pubspec.yaml` with the new version
4. ✅ Runs `flutter analyze` and `flutter test`
5. ✅ Builds a release APK
6. ✅ Creates a GitHub Release with the new tag
7. ✅ Commits the version updates back to `main`

**Example:**
```
Current: v1.0.5
Next:    v1.0.6 (automatic)
```

## Manual Major/Minor Version Bumps

When you need to bump the **MAJOR** or **MINOR** version, you must create a git tag manually before pushing to `main`.

### Bumping Minor Version (New Features)

When adding new features that don't break backward compatibility:

```bash
# Check current version
git describe --tags --abbrev=0

# Example: Current is v1.0.5, bump to v1.1.0
git tag v1.1.0
git push origin v1.1.0

# Make your changes, commit, and push
git add .
git commit -m "feat: add new feature"
git push origin main
```

The workflow will then auto-increment to `v1.1.1` on the next push.

### Bumping Major Version (Breaking Changes)

When introducing breaking changes:

```bash
# Check current version
git describe --tags --abbrev=0

# Example: Current is v1.5.3, bump to v2.0.0
git tag v2.0.0
git push origin v2.0.0

# Make your changes, commit, and push
git add .
git commit -m "feat!: breaking change description"
git push origin main
```

The workflow will then auto-increment to `v2.0.1` on the next push.

## Starting Fresh (First Release)

If there are no tags in the repository, the workflow defaults to `v1.0.0` and will create `v1.0.1` on the first build.

To start with a specific version:

```bash
# Start at v1.0.0
git tag v1.0.0
git push origin v1.0.0
```

## Manual Version Updates

### Updating pubspec.yaml

If you need to manually update the version in `pubspec.yaml`:

```yaml
# Format: version+buildNumber
version: 1.2.3+10203
```

The `+buildNumber` format is calculated as:
```
buildNumber = major * 10000 + minor * 100 + patch
```

Example: `1.2.3` → `10203`

### Triggering a Build Without Code Changes

To trigger a new build and version increment without code changes:

```bash
git commit --allow-empty -m "chore: trigger new build"
git push origin main
```

## Version Workflow Examples

### Scenario 1: Bug Fix Release
```bash
# Current: v1.2.5
# 1. Fix bug, commit, push to main
git add .
git commit -m "fix: resolve login issue"
git push origin main

# Automatic result: v1.2.6
```

### Scenario 2: New Feature Release
```bash
# Current: v1.2.6
# 1. Create minor version tag
git tag v1.3.0
git push origin v1.3.0

# 2. Add feature, commit, push to main
git add .
git commit -m "feat: add dark mode"
git push origin main

# Automatic result: v1.3.1
```

### Scenario 3: Breaking Change Release
```bash
# Current: v1.5.10
# 1. Create major version tag
git tag v2.0.0
git push origin v2.0.0

# 2. Make breaking changes, commit, push to main
git add .
git commit -m "feat!: redesign API interface"
git push origin main

# Automatic result: v2.0.1
```

## Version Numbering Best Practices

### When to Bump Major Version (X.0.0)
- Breaking API changes
- Removing deprecated features
- Major architectural changes
- Incompatible with previous versions

### When to Bump Minor Version (0.X.0)
- New features added
- New functionality that's backward-compatible
- Deprecating features (but not removing them)

### When to Bump Patch Version (0.0.X)
- Bug fixes
- Performance improvements
- Documentation updates
- Internal refactoring

**Note:** Patch version is handled automatically by the workflow.

## CI/CD Configuration

### Required GitHub Secrets

For proper APK signing, configure these secrets in your repository settings:

1. **KEYSTORE_BASE64**: Base64-encoded keystore file
   ```bash
   base64 -i upload-keystore.jks | pbcopy
   ```

2. **KEY_STORE_PASSWORD**: Keystore password
3. **KEY_PASSWORD**: Key password
4. **KEY_ALIAS**: Key alias name

### Setting Up Secrets

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each of the required secrets

### Creating a Keystore

If you don't have a keystore yet:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# Follow the prompts to set passwords and details
```

**Important:** Store the keystore file and passwords securely. Losing them means you cannot update your app.

## Workflow Behavior

### Skip CI

To push changes without triggering the workflow:

```bash
git commit -m "docs: update README [skip ci]"
git push origin main
```

The workflow automatically adds `[skip ci]` to version bump commits to prevent infinite loops.

### Workflow Triggers

The workflow runs on:
- Push to `main` branch (except commits with `[skip ci]`)

### Build Artifacts

Each successful build creates:
- **GitHub Release** with tag (e.g., `v1.0.1`)
- **APK file** named `flutter-shell-v{version}.apk`
- **Release notes** with version details

## Troubleshooting

### Workflow Fails on `flutter test`

Fix the failing tests before the workflow will succeed:

```bash
# Run tests locally
flutter test

# Fix issues, then commit and push
```

### Version Conflict

If you manually edited `pubspec.yaml` and the workflow conflicts:

1. Delete the problematic tag: `git tag -d v1.0.5 && git push origin :refs/tags/v1.0.5`
2. Let the workflow create the correct version

### Missing Version Tags

To see all version tags:

```bash
git tag -l "v*"
```

To see the latest tag:

```bash
git describe --tags --abbrev=0
```

## Version History

To view all releases and their APK downloads:
1. Go to your GitHub repository
2. Click on "Releases" (right sidebar)
3. Download APK from any release

## Additional Resources

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Flutter Build and Release Docs](https://docs.flutter.dev/deployment/android)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Conventional Commits](https://www.conventionalcommits.org/) (recommended for commit messages)
