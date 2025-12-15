import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ContextPlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.example.flutter_shell/context_bridge');

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> openNotificationListenerSettings() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('openNotificationListenerSettings');
  }

  Future<void> openAccessibilitySettings() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> openUsageAccessSettings() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<bool> isNotificationListenerEnabled() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('isNotificationListenerEnabled')) ?? false;
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled')) ?? false;
  }

  Future<bool> hasUsageStatsAccess() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('hasUsageStatsAccess')) ?? false;
  }

  Future<bool> startAudioFeaturesService() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('startAudioFeaturesService')) ?? false;
  }

  Future<bool> stopAudioFeaturesService() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('stopAudioFeaturesService')) ?? false;
  }

  Future<bool> isAudioFeaturesServiceRunning() async {
    if (!isAndroid) return false;
    return (await _channel.invokeMethod<bool>('isAudioFeaturesServiceRunning')) ?? false;
  }

  Future<List<String>> drainPendingEvents({required String channel}) async {
    if (!isAndroid) return const <String>[];

    final result = await _channel.invokeMethod<List<Object?>>(
      'drainPendingEvents',
      <String, Object?>{'channel': channel},
    );

    return result?.whereType<String>().toList(growable: false) ?? const <String>[];
  }

  Future<List<Map<String, Object?>>> getBrowserUsageSummary({Duration window = const Duration(hours: 24)}) async {
    if (!isAndroid) return const <Map<String, Object?>>[];

    final result = await _channel.invokeMethod<List<Object?>>( 
      'getBrowserUsageSummary',
      <String, Object?>{'windowMs': window.inMilliseconds},
    );

    return result
            ?.whereType<Map>()
            .map((map) => map.cast<String, Object?>())
            .toList(growable: false) ??
        const <Map<String, Object?>>[];
  }
}
