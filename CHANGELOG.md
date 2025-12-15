# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow with automatic semantic versioning
- Automatic patch version increments on push to main
- Automated APK builds and GitHub Releases
- APK signing support with GitHub Secrets
- Comprehensive version management documentation

### Changed
- Updated android/app/build.gradle to support release signing configuration

## [1.0.0] - Initial Release

### Added
- Flutter 3 application with Material 3 design
- Riverpod state management integration
- Hive local storage for persistent data
- AI-powered suggestion engine
- Context-aware suggestions system
- Background service support
- Android platform integration
- Comprehensive test suite

### Features
- **Suggestion Engine**: AI-powered contextual suggestions with temporal intelligence
- **Context Repository**: Real-time event processing from notifications, usage stats, accessibility, and audio
- **Manual Approval UI**: User-controlled suggestion review and approval system
- **Temporal Profiles**: Time-of-day aware suggestion generation (morning, afternoon, evening, night)
- **Prioritization Engine**: Smart suggestion ranking based on context, urgency, and user engagement
- **Learning System**: Adapts to user behavior and preferences over time

### Documentation
- [Version Management Guide](docs/version-management.md)
- [GitHub Secrets Setup](docs/github-secrets-setup.md)
- [Version Quick Reference](docs/version-quick-reference.md)
- [Suggestion Engine Extension Guide](docs/suggestion_engine_extension_guide.md)
- [Android Context Collectors](docs/android-context-collectors.md)

---

## Version Management

This project uses automated semantic versioning:

- **Patch versions** (x.x.X) are automatically incremented on every push to main
- **Minor versions** (x.X.0) require manual git tags for new features
- **Major versions** (X.0.0) require manual git tags for breaking changes

See the [Version Management Guide](docs/version-management.md) for detailed instructions.

## Release Process

1. **Automatic Releases**: Push to main → automatic patch increment → GitHub Release with APK
2. **Feature Releases**: Create minor version tag → push to main → GitHub Release
3. **Breaking Changes**: Create major version tag → push to main → GitHub Release

Each release includes:
- Semantic version tag (e.g., v1.0.1)
- Release APK artifact
- Automated release notes
- Build artifacts

## Links

- [Repository](https://github.com/your-username/flutter-shell)
- [Releases](https://github.com/your-username/flutter-shell/releases)
- [Issues](https://github.com/your-username/flutter-shell/issues)
