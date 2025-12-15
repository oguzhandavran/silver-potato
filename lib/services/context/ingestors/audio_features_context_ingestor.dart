import 'dart:async';

import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_ingestor.dart';
import 'package:flutter_shell/services/context/platform/context_platform_bridge.dart';
import 'package:flutter_shell/services/context/ingestors/android_event_channel_ingestor.dart';

class AudioFeaturesContextIngestor implements ContextIngestor {
  final ContextPlatformBridge _bridge;
  final AndroidEventChannelIngestor _delegate;

  AudioFeaturesContextIngestor(this._bridge)
      : _delegate = AndroidEventChannelIngestor(
          id: 'audio_features',
          displayName: 'Audio features (VAD/activity, on-device)',
          eventChannelName: 'com.example.flutter_shell/context_events/audio_features',
          bridge: _bridge,
        );

  @override
  String get id => _delegate.id;

  @override
  String get displayName => _delegate.displayName;

  @override
  Stream<ContextEvent> get events => _delegate.events;

  @override
  Future<void> start() async {
    final started = await _bridge.startAudioFeaturesService();
    if (!started) {
      throw StateError('Failed to start audio features service');
    }

    await _delegate.start();
  }

  @override
  Future<void> stop() async {
    await _delegate.stop();

    final stopped = await _bridge.stopAudioFeaturesService();
    if (!stopped) {
      throw StateError('Failed to stop audio features service');
    }
  }

  @override
  void dispose() {
    unawaited(stop());
    _delegate.dispose();
  }
}
