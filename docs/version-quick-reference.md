# Version Management Quick Reference

Quick commands for common version management tasks.

## Check Current Version

```bash
# Check latest tag
git describe --tags --abbrev=0

# Check pubspec.yaml version
grep "^version:" pubspec.yaml

# List all version tags
git tag -l "v*"
```

## Automatic Versioning (Default)

Push to `main` → automatic patch increment:

```bash
# Current: v1.0.5
git add .
git commit -m "fix: bug fix"
git push origin main
# Result: v1.0.6 (automatic)
```

## Manual Version Bumps

### Minor Version (New Features)

```bash
# Bump from v1.2.5 to v1.3.0
git tag v1.3.0
git push origin v1.3.0
git push origin main
# Next auto: v1.3.1
```

### Major Version (Breaking Changes)

```bash
# Bump from v1.5.3 to v2.0.0
git tag v2.0.0
git push origin v2.0.0
git push origin main
# Next auto: v2.0.1
```

## Force New Build Without Changes

```bash
git commit --allow-empty -m "chore: trigger build"
git push origin main
```

## Skip CI

```bash
git commit -m "docs: update [skip ci]"
git push origin main
```

## Delete/Fix Wrong Tag

```bash
# Delete local tag
git tag -d v1.0.5

# Delete remote tag
git push origin :refs/tags/v1.0.5

# Create correct tag
git tag v1.0.6
git push origin v1.0.6
```

## Version Code Calculation

```
versionCode = major * 10000 + minor * 100 + patch
```

Examples:
- `1.0.0` → `10000`
- `1.2.3` → `10203`
- `2.5.10` → `20510`

## Common Commit Prefixes

- `fix:` - Bug fixes (auto patch bump)
- `feat:` - New features (manual minor bump)
- `feat!:` - Breaking changes (manual major bump)
- `chore:` - Maintenance tasks
- `docs:` - Documentation only
- `test:` - Test updates

## Troubleshooting

### Workflow not running?
```bash
# Check workflow file exists
ls -la .github/workflows/flutter-build.yml

# Check recent runs
# Go to: GitHub → Actions tab
```

### Build failing?
```bash
# Test locally first
flutter analyze
flutter test
flutter build apk --release
```

### Version conflict?
```bash
# Reset to latest remote version
git fetch origin
git reset --hard origin/main
```

## File Locations

- Workflow: `.github/workflows/flutter-build.yml`
- Version: `pubspec.yaml` line 6
- Android config: `android/app/build.gradle`
- Secrets: GitHub → Settings → Secrets → Actions

## When to Use Each Version Type

| Change Type | Version | Command |
|-------------|---------|---------|
| Bug fix, typo | Patch (auto) | Just push to main |
| New feature, enhancement | Minor (manual) | `git tag v1.X.0` |
| Breaking change | Major (manual) | `git tag vX.0.0` |

## Full Documentation

For detailed information, see:
- [Version Management Guide](version-management.md)
- [GitHub Secrets Setup](github-secrets-setup.md)
