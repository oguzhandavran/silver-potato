import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  final bool isLoading;
  final String? errorMessage;
  final String appVersion;

  const AppState({
    this.isLoading = false,
    this.errorMessage,
    this.appVersion = '1.0.0',
  });

  AppState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? appVersion,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
