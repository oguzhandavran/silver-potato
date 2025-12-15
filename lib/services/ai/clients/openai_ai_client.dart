import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_shell/services/ai/ai_client.dart';
import 'package:flutter_shell/services/ai/ai_models.dart';

class OpenAiClient implements AiClient {
  @override
  final AiClientMeta meta;

  final Uri _endpoint;
  final http.Client _http;

  OpenAiClient({
    required http.Client httpClient,
    String model = 'gpt-4o-mini',
    Uri? endpoint,
    double relativeCost = 0.6,
  })  : _http = httpClient,
        _endpoint = endpoint ?? Uri.parse('https://api.openai.com/v1/chat/completions'),
        meta = AiClientMeta(
          model: AiModelRef(provider: AiProvider.openai, model: model),
          relativeCost: relativeCost,
          requiresApiKey: true,
          supportsStreaming: true,
          supportsFunctionCalling: true,
          supportsOffline: false,
          isOfflineFallback: false,
          supportedTaskTypes: const {AiTaskType.general, AiTaskType.summarize, AiTaskType.coding, AiTaskType.functionCalling},
        );

  @override
  Future<AiChatResponse> chat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async {
    final apiKey = credentials.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError('OpenAI API key is required');
    }

    final payload = {
      'model': meta.model.model,
      'messages': request.messages
          .map(
            (m) => {
              'role': m.role.name,
              'content': m.content,
            },
          )
          .toList(growable: false),
    };

    final response = await _http.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('OpenAI request failed: ${response.statusCode} ${response.body}', _endpoint);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected OpenAI response');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return AiChatResponse(model: meta.model, text: '');
    }

    final message = (choices.first as Map)['message'];
    if (message is! Map) {
      return AiChatResponse(model: meta.model, text: '');
    }

    final content = message['content'];
    return AiChatResponse(model: meta.model, text: content is String ? content : '');
  }

  @override
  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async* {
    final response = await chat(request, credentials: credentials);
    yield AiStreamTextDelta(response.text);
  }
}
