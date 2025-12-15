import 'package:flutter_shell/services/ai/ai_client.dart';
import 'package:flutter_shell/services/ai/ai_models.dart';

class OfflineAiClient implements AiClient {
  @override
  final AiClientMeta meta = const AiClientMeta(
    model: AiModelRef(provider: AiProvider.offline, model: 'rules-v1'),
    relativeCost: 0,
    requiresApiKey: false,
    supportsStreaming: true,
    supportsFunctionCalling: false,
    supportsOffline: true,
    isOfflineFallback: true,
    supportedTaskTypes: {AiTaskType.general, AiTaskType.summarize, AiTaskType.coding, AiTaskType.functionCalling},
  );

  @override
  Future<AiChatResponse> chat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async {
    final prompt = request.messages.isNotEmpty ? request.messages.last.content : '';
    final text = _generateOfflineReply(prompt: prompt, taskType: request.taskType);
    return AiChatResponse(model: meta.model, text: text);
  }

  @override
  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async* {
    final response = await chat(request, credentials: credentials);
    yield AiStreamTextDelta(response.text);
  }

  String _generateOfflineReply({required String prompt, required AiTaskType taskType}) {
    return switch (taskType) {
      AiTaskType.summarize => 'Offline summary: $prompt',
      AiTaskType.coding => 'Offline mode: unable to generate high-quality code. Prompt: $prompt',
      AiTaskType.functionCalling => 'Offline mode: function calling is unavailable.',
      AiTaskType.general => 'Offline response: $prompt',
    };
  }
}
