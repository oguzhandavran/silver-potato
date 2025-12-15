import 'package:google_generative_ai/google_generative_ai.dart';

import '../ai_client.dart';
import '../ai_models.dart';

class GeminiAiClient implements AiClient {
  @override
  final AiClientMeta meta;

  GeminiAiClient({
    String model = 'gemini-1.5-flash',
    double relativeCost = 0.2,
  }) : meta = AiClientMeta(
          model: AiModelRef(provider: AiProvider.gemini, model: model),
          relativeCost: relativeCost,
          requiresApiKey: true,
          supportsStreaming: true,
          supportsFunctionCalling: false,
          supportsOffline: false,
          isOfflineFallback: false,
          supportedTaskTypes: const {AiTaskType.general, AiTaskType.summarize, AiTaskType.coding},
        );

  @override
  Future<AiChatResponse> chat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async {
    final apiKey = credentials.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError('Gemini API key is required');
    }

    final model = GenerativeModel(model: meta.model.model, apiKey: apiKey);
    final prompt = _buildPrompt(request);
    final response = await model.generateContent([Content.text(prompt)]);

    return AiChatResponse(
      model: meta.model,
      text: response.text ?? '',
    );
  }

  @override
  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async* {
    final apiKey = credentials.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError('Gemini API key is required');
    }

    final model = GenerativeModel(model: meta.model.model, apiKey: apiKey);
    final prompt = _buildPrompt(request);

    await for (final chunk in model.generateContentStream([Content.text(prompt)])) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield AiStreamTextDelta(text);
      }
    }
  }

  String _buildPrompt(AiChatRequest request) {
    if (request.messages.length == 1) {
      return request.messages.single.content;
    }
    return request.messages
        .map((m) => '${m.role.name.toUpperCase()}: ${m.content}')
        .join('\n');
  }
}
