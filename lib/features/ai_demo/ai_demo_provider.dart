import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/services/ai/ai_models.dart';
import 'package:flutter_shell/services/ai/ai_orchestrator.dart';
import 'package:flutter_shell/services/ai/ai_providers.dart';

class AiDemoState {
  static const _unset = Object();

  final bool isLoading;
  final String output;
  final List<AiToolCall> toolCalls;
  final String? error;

  const AiDemoState({
    this.isLoading = false,
    this.output = '',
    this.toolCalls = const [],
    this.error,
  });

  AiDemoState copyWith({
    bool? isLoading,
    String? output,
    List<AiToolCall>? toolCalls,
    Object? error = _unset,
  }) {
    return AiDemoState(
      isLoading: isLoading ?? this.isLoading,
      output: output ?? this.output,
      toolCalls: toolCalls ?? this.toolCalls,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

final aiDemoViewModelProvider = StateNotifierProvider<AiDemoViewModel, AiDemoState>((ref) {
  final orchestrator = ref.watch(aiOrchestratorProvider);
  return AiDemoViewModel(orchestrator);
});

class AiDemoViewModel extends StateNotifier<AiDemoState> {
  final AiOrchestrator _orchestrator;
  StreamSubscription<AiStreamEvent>? _sub;

  AiDemoViewModel(this._orchestrator) : super(const AiDemoState());

  Future<void> sendPrompt(String prompt) async {
    await _sub?.cancel();
    state = state.copyWith(isLoading: true, output: '', toolCalls: const [], error: null);

    final request = AiChatRequest(
      messages: [AiChatMessage.user(prompt)],
      taskType: AiTaskType.general,
    );

    _sub = _orchestrator.streamChat(request).listen(
      (event) {
        if (event is AiStreamTextDelta) {
          state = state.copyWith(output: state.output + event.delta);
        } else if (event is AiStreamToolCall) {
          state = state.copyWith(toolCalls: [...state.toolCalls, event.toolCall]);
        } else if (event is AiStreamDone) {
          state = state.copyWith(isLoading: false, output: event.response.text, toolCalls: event.response.toolCalls);
        }
      },
      onError: (Object err, StackTrace st) {
        state = state.copyWith(isLoading: false, error: err.toString());
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
