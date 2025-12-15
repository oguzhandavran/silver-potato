import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_ingestor.dart';
import 'package:flutter_shell/services/context/platform/context_platform_bridge.dart';
import 'package:flutter_shell/services/context/ingestors/android_event_channel_ingestor.dart';

class AccessibilityContextIngestor implements ContextIngestor {
  final AndroidEventChannelIngestor _delegate;

  AccessibilityContextIngestor(ContextPlatformBridge bridge)
      : _delegate = AndroidEventChannelIngestor(
          id: 'accessibility',
          displayName: 'Accessibility context (opt-in)',
          eventChannelName: 'com.example.flutter_shell/context_events/accessibility',
          bridge: bridge,
        );

  @override
  String get id => _delegate.id;

  @override
  String get displayName => _delegate.displayName;

  @override
  Stream<ContextEvent> get events => _delegate.events;

  @override
  Future<void> start() => _delegate.start();

  @override
  Future<void> stop() => _delegate.stop();

  @override
  void dispose() => _delegate.dispose();
}
