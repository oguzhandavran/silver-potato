import 'dart:async';

import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_ingestor.dart';
import 'package:flutter_shell/services/context/platform/context_platform_bridge.dart';

class UsageStatsContextIngestor implements ContextIngestor {
  final ContextPlatformBridge _bridge;

  final StreamController<ContextEvent> _controller = StreamController<ContextEvent>.broadcast();
  Timer? _timer;

  UsageStatsContextIngestor(this._bridge);

  @override
  String get id => 'usage_stats';

  @override
  String get displayName => 'Usage stats (browser summaries)';

  @override
  Stream<ContextEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    if (_timer != null) return;
    if (!_bridge.isAndroid) return;

    await _pollOnce();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(_pollOnce());
    });
  }

  Future<void> _pollOnce() async {
    final window = const Duration(hours: 24);
    final summaries = await _bridge.getBrowserUsageSummary(window: window);
    final now = DateTime.now();

    for (final summary in summaries) {
      final packageName = summary['packageName'];
      if (packageName is! String) continue;

      _controller.add(
        ContextEvent(
          source: ContextEventSource.usageStats,
          type: 'browser_usage_summary',
          timestamp: now,
          data: <String, Object?>{
            'packageName': packageName,
            'windowMs': window.inMilliseconds,
            'totalTimeInForegroundMs': summary['totalTimeInForegroundMs'],
            'lastTimeUsedMs': summary['lastTimeUsedMs'],
          },
        ),
      );
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    unawaited(stop());
    _controller.close();
  }
}
