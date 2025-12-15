import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuggestionsState {
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
    String? error,
  }) {
    return SuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final suggestionsStateProvider = StateNotifierProvider<SuggestionsStateNotifier, SuggestionsState>((ref) {
  return SuggestionsStateNotifier();
});

class SuggestionsStateNotifier extends StateNotifier<SuggestionsState> {
  SuggestionsStateNotifier() : super(const SuggestionsState());

  Future<void> fetchSuggestions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Implement API call to Google Generative AI
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        suggestions: [
          'Try exploring the settings',
          'Check the documentation',
          'Enable background services',
        ],
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
    state = state.copyWith(suggestions: const []);
  }
}
