import 'package:flutter_shell/services/ai/ai_models.dart';

class AiClientMeta {
  final AiModelRef model;
  final double relativeCost;
  final bool requiresApiKey;
  final bool supportsStreaming;
  final bool supportsFunctionCalling;
  final bool supportsOffline;
  final bool isOfflineFallback;
  final Set<AiTaskType> supportedTaskTypes;

  const AiClientMeta({
    required this.model,
    required this.relativeCost,
    required this.requiresApiKey,
    required this.supportsStreaming,
    required this.supportsFunctionCalling,
    required this.supportsOffline,
    required this.isOfflineFallback,
    required this.supportedTaskTypes,
  });
}

abstract class AiClient {
  AiClientMeta get meta;

  Future<AiChatResponse> chat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  });

  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  });
}
