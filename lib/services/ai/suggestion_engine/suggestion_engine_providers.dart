import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/services/ai/ai_orchestrator.dart';
import 'package:flutter_shell/services/context/context_repository.dart';
import 'package:flutter_shell/services/ai/suggestion_engine/models/suggestion_models.dart';
import 'package:flutter_shell/services/ai/suggestion_engine/suggestion_engine.dart';

// Configuration providers
final suggestionEngineConfigProvider = Provider<SuggestionEngineConfig>((ref) {
  return const SuggestionEngineConfig(
    autoSendEnabled: false,
    enabledSuggestions: {
      TemporalProfile.morning: {
        SuggestionType.todoNudge,
        SuggestionType.studyAid,
      },
      TemporalProfile.afternoon: {
        SuggestionType.todoNudge,
        SuggestionType.empatheticReply,
        SuggestionType.studyAid,
      },
      TemporalProfile.evening: {
        SuggestionType.empatheticReply,
        SuggestionType.studyAid,
      },
    },
    maxDailySuggestions: {
      SuggestionType.todoNudge: 3,
      SuggestionType.empatheticReply: 5,
      SuggestionType.studyAid: 2,
    },
    suggestionCooldown: Duration(hours: 1),
  );
});

// Core engine provider - will be initialized in the app setup
final suggestionEngineProvider = StateProvider<SuggestionEngine?>((ref) => null);

// Initialize the suggestion engine with all required dependencies
final suggestionEngineInitializerProvider = Provider<void>((ref) {
  final config = ref.watch(suggestionEngineConfigProvider);
  final contextRepository = ref.watch(contextRepositoryProvider);
  final aiOrchestrator = ref.watch(aiOrchestratorProvider);
  
  final engine = SuggestionEngine(
    contextRepository: contextRepository,
    aiOrchestrator: aiOrchestrator,
    config: config,
  );
  
  ref.read(suggestionEngineProvider.notifier).state = engine;
});

// Streams for suggestions
final approvedSuggestionsProvider = StreamProvider<List<Suggestion>>((ref) {
  final engine = ref.watch(suggestionEngineProvider);
  if (engine == null) return const Stream.empty();
  return engine.approvedSuggestions;
});

final pendingSuggestionsProvider = StreamProvider<List<Suggestion>>((ref) {
  final engine = ref.watch(suggestionEngineProvider);
  if (engine == null) return const Stream.empty();
  // For StreamProvider, we need to return a stream, but currentPendingSuggestions is synchronous
  // So we'll create a stream from it
  return Stream.value(engine.currentPendingSuggestions);
});

// Individual suggestion management
final suggestionActionsProvider = Provider<SuggestionActions>((ref) {
  final engine = ref.watch(suggestionEngineProvider);
  if (engine == null) {
    throw StateError('Suggestion engine not initialized. Make sure suggestionEngineInitializerProvider is loaded.');
  }
  return SuggestionActions(engine);
});

// Profile statistics
final temporalProfileStatsProvider = Provider<Map<TemporalProfile, TemporalProfileStats>>((ref) {
  final engine = ref.watch(suggestionEngineProvider);
  if (engine == null) {
    return {
      TemporalProfile.morning: TemporalProfileStats(lastActivity: DateTime.now()),
      TemporalProfile.afternoon: TemporalProfileStats(lastActivity: DateTime.now()),
      TemporalProfile.evening: TemporalProfileStats(lastActivity: DateTime.now()),
      TemporalProfile.night: TemporalProfileStats(lastActivity: DateTime.now()),
    };
  }
  return {
    TemporalProfile.morning: engine.getProfileStats(TemporalProfile.morning) ?? 
        TemporalProfileStats(lastActivity: DateTime.now()),
    TemporalProfile.afternoon: engine.getProfileStats(TemporalProfile.afternoon) ?? 
        TemporalProfileStats(lastActivity: DateTime.now()),
    TemporalProfile.evening: engine.getProfileStats(TemporalProfile.evening) ?? 
        TemporalProfileStats(lastActivity: DateTime.now()),
    TemporalProfile.night: engine.getProfileStats(TemporalProfile.night) ?? 
        TemporalProfileStats(lastActivity: DateTime.now()),
  };
});

class SuggestionActions {
  final SuggestionEngine _engine;
  
  const SuggestionActions(this._engine);
  
  void approve(String suggestionId) {
    _engine.approveSuggestion(suggestionId);
  }
  
  void reject(String suggestionId) {
    _engine.rejectSuggestion(suggestionId);
  }
  
  void send(String suggestionId) {
    _engine.sendSuggestion(suggestionId);
  }
}