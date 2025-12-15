import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_ingestor.dart';
import 'package:flutter_shell/services/context/platform/context_platform_bridge.dart';

class AndroidEventChannelIngestor implements ContextIngestor {
  final String _id;
  final String _displayName;
  final EventChannel _eventChannel;
  final ContextPlatformBridge _bridge;

  final StreamController<ContextEvent> _controller = StreamController<ContextEvent>.broadcast();
  StreamSubscription<Object?>? _subscription;
  bool _isRunning = false;

  AndroidEventChannelIngestor({
    required String id,
    required String displayName,
    required String eventChannelName,
    required ContextPlatformBridge bridge,
  })  : _id = id,
        _displayName = displayName,
        _eventChannel = EventChannel(eventChannelName),
        _bridge = bridge;

  @override
  String get id => _id;

  @override
  String get displayName => _displayName;

  @override
  Stream<ContextEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    if (!_bridge.isAndroid) return;

    final drained = await _bridge.drainPendingEvents(channel: id);
    for (final rawJson in drained) {
      _emitRawJson(rawJson);
    }

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (payload) {
        if (payload is String) {
          _emitRawJson(payload);
        }
      },
    );
  }

  void _emitRawJson(String rawJson) {
    try {
      final event = ContextEvent.fromPlatformJsonString(rawJson);
      if (!_controller.isClosed) {
        _controller.add(event);
      }
    } catch (_) {
      // Ignore malformed platform messages.
    }
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(stop());
    _controller.close();
  }
}
