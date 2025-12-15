import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/services/ai/ai_models.dart';
import 'package:flutter_shell/services/ai/ai_orchestrator.dart';
import 'package:flutter_shell/services/ai/ai_providers.dart';

class SuggestionsState {
  static const _unset = Object();

  final List<String> suggestions;
  final bool isLoading;
  final String? error;

  const SuggestionsState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  SuggestionsState copyWith({
    List<String>? suggestions,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return SuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

final suggestionsStateProvider = StateNotifierProvider<SuggestionsStateNotifier, SuggestionsState>((ref) {
  final orchestrator = ref.watch(aiOrchestratorProvider);
  return SuggestionsStateNotifier(orchestrator);
});

class SuggestionsStateNotifier extends StateNotifier<SuggestionsState> {
  final AiOrchestrator _orchestrator;

  SuggestionsStateNotifier(this._orchestrator) : super(const SuggestionsState());

  Future<void> fetchSuggestions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _orchestrator.chat(
        const AiChatRequest(
          taskType: AiTaskType.summarize,
          messages: [
            AiChatMessage.user(
              'Generate 3 short suggestions for exploring a Flutter app. Return one per line.',
            ),
          ],
        ),
      );

      final parsed = _parseSuggestions(response.text);
      state = state.copyWith(
        suggestions: parsed.isEmpty
            ? const [
                'Try exploring the settings',
                'Check the documentation',
                'Enable background services',
              ]
            : parsed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: const [], error: null);
  }

  List<String> _parseSuggestions(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .map((line) => line.replaceFirst(RegExp(r'^(?:[-*•]|\d+\.)\s+'), ''))
        .where((line) => line.isNotEmpty)
        .take(10)
        .toList(growable: false);
  }
}
