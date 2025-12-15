import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final String title;
  final bool isLoading;

  const HomeState({
    this.title = 'Home',
    this.isLoading = false,
  });

  HomeState copyWith({
    String? title,
    bool? isLoading,
  }) {
    return HomeState(
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
  return HomeStateNotifier();
});

class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier() : super(const HomeState());

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }
}
