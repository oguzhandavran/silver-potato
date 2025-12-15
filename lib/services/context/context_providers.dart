import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_ingestor.dart';
import 'package:flutter_shell/services/context/context_repository.dart';
import 'package:flutter_shell/services/context/ingestors/accessibility_context_ingestor.dart';
import 'package:flutter_shell/services/context/ingestors/audio_features_context_ingestor.dart';
import 'package:flutter_shell/services/context/ingestors/notification_context_ingestor.dart';
import 'package:flutter_shell/services/context/ingestors/usage_stats_context_ingestor.dart';
import 'package:flutter_shell/services/context/platform/context_platform_bridge.dart';

final contextPlatformBridgeProvider = Provider<ContextPlatformBridge>((ref) {
  return ContextPlatformBridge();
});

final contextRepositoryProvider = Provider<ContextRepository>((ref) {
  final repo = InMemoryContextRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final contextIngestorsProvider = Provider<List<ContextIngestor>>((ref) {
  final bridge = ref.watch(contextPlatformBridgeProvider);

  final ingestors = <ContextIngestor>[
    NotificationContextIngestor(bridge),
    AccessibilityContextIngestor(bridge),
    UsageStatsContextIngestor(bridge),
    AudioFeaturesContextIngestor(bridge),
  ];

  ref.onDispose(() {
    for (final ingestor in ingestors) {
      ingestor.dispose();
    }
  });

  return ingestors;
});

class ContextIngestionState {
  static const _unset = Object();

  final Set<String> activeCollectorIds;
  final String? error;

  const ContextIngestionState({
    this.activeCollectorIds = const <String>{},
    this.error,
  });

  ContextIngestionState copyWith({
    Set<String>? activeCollectorIds,
    Object? error = _unset,
  }) {
    return ContextIngestionState(
      activeCollectorIds: activeCollectorIds ?? this.activeCollectorIds,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

final contextIngestionControllerProvider =
    StateNotifierProvider<ContextIngestionController, ContextIngestionState>((ref) {
  final repository = ref.watch(contextRepositoryProvider);
  final ingestors = ref.watch(contextIngestorsProvider);

  final controller = ContextIngestionController(repository: repository, ingestors: ingestors);
  ref.onDispose(controller.dispose);
  return controller;
});

class ContextIngestionController extends StateNotifier<ContextIngestionState> {
  final ContextRepository _repository;
  final Map<String, ContextIngestor> _ingestorsById;
  final Map<String, StreamSubscription<ContextEvent>> _subscriptions =
      <String, StreamSubscription<ContextEvent>>{};

  ContextIngestionController({
    required ContextRepository repository,
    required List<ContextIngestor> ingestors,
  })  : _repository = repository,
        _ingestorsById = <String, ContextIngestor>{
          for (final ingestor in ingestors) ingestor.id: ingestor,
        },
        super(const ContextIngestionState());

  Future<void> startCollector(String id) async {
    if (state.activeCollectorIds.contains(id)) return;

    final ingestor = _ingestorsById[id];
    if (ingestor == null) return;

    try {
      await ingestor.start();
      final subscription = ingestor.events.listen(_repository.addEvent);
      _subscriptions[id] = subscription;

      state = state.copyWith(
        activeCollectorIds: Set<String>.unmodifiable(<String>{...state.activeCollectorIds, id}),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopCollector(String id) async {
    if (!state.activeCollectorIds.contains(id)) return;

    final ingestor = _ingestorsById[id];
    if (ingestor == null) return;

    try {
      await _subscriptions.remove(id)?.cancel();
      await ingestor.stop();

      final updated = Set<String>.from(state.activeCollectorIds)..remove(id);
      state = state.copyWith(activeCollectorIds: Set<String>.unmodifiable(updated));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopAll() async {
    final ids = state.activeCollectorIds.toList(growable: false);
    for (final id in ids) {
      await stopCollector(id);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final id in state.activeCollectorIds) {
      final ingestor = _ingestorsById[id];
      if (ingestor != null) {
        unawaited(ingestor.stop());
      }
    }

    super.dispose();
  }
}

final contextEventsStreamProvider = StreamProvider<ContextEvent>((ref) {
  final repository = ref.watch(contextRepositoryProvider);
  return repository.events;
});
