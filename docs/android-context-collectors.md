# Android Context Collectors (stubs)

This app includes **Android-only** collector stubs intended to demonstrate how context signals can be ingested **with explicit user opt-in**.

## Overview

Collectors are exposed to Dart through the `ContextIngestor` interface and publish **sanitized** `ContextEvent`s into `ContextRepository`.

All collectors require explicit user action in Android system settings and/or runtime permissions.

## Collectors

### 1) Notification collector (NotificationListenerService)

- **Source**: `NotificationListenerService`
- **Targets** (best-effort package filter):
  - WhatsApp (`com.whatsapp`)
  - ColorNote (`com.socialnmobile.dictapps.notepad.color.note`)
  - StarNote (package varies; stub filter is best-effort)
- **User approval**: Enable “Notification access” for the app in system settings.
- **Data stored**: Only lengths + SHA-256 hashes of title/text and basic metadata (package name, timestamp).
- **Limitations**:
  - Apps can suppress notification contents.
  - Some notifications may not contain `EXTRA_TEXT`.

### 2) Accessibility collector (AccessibilityService)

- **Source**: `AccessibilityService`
- **User approval**: Must be enabled manually in Accessibility settings.
- **Data stored**: High-level event metadata only (event type, package/class name, timestamps).
- **Strict opt-in**:
  - The service is configured with `canRetrieveWindowContent=false`.
  - The implementation intentionally does **not** read event text.
- **Limitations**:
  - Accessibility access is powerful and subject to platform and store policy restrictions.

### 3) Usage stats collector (UsageStatsManager)

- **Source**: `UsageStatsManager`
- **User approval**: Grant “Usage access” in system settings.
- **Data stored**: Aggregate app usage time (e.g., Chrome/Firefox total foreground time in the last 24h).
- **Important limitation**:
  - `UsageStatsManager` does **not** provide browser URL history. The “history summaries” in this stub are app-level usage summaries only.

### 4) Audio features collector (foreground microphone service)

- **Source**: Foreground `Service` + `AudioRecord`
- **User approval**:
  - Runtime microphone permission.
  - Runtime notification permission (Android 13+) to show the required foreground-service notification.
- **Data stored**:
  - On-device features only: activity level (normalized RMS) + a simple VAD-like boolean.
  - No raw audio is stored or transmitted.
- **Limitations**:
  - Foreground services must show a persistent notification.
  - Some OEMs may aggressively restrict background/foreground behavior.

## Dart integration

- Dart-side onboarding UI lives in `lib/features/context_onboarding/`.
- Platform bridge uses a `MethodChannel` (`com.example.flutter_shell/context_bridge`) and `EventChannel`s:
  - `.../context_events/notifications`
  - `.../context_events/accessibility`
  - `.../context_events/audio_features`

## Notes on privacy

These collectors are designed to be **privacy-preserving by default** (hashing/redacting, no raw audio storage).
If you expand these stubs into full collectors, ensure you:

- Document all data fields collected.
- Provide in-app controls to stop collection.
- Comply with Play policy requirements for notification/accessibility/microphone usage.
