import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai_client.dart';
import '../ai_models.dart';

class ClaudeAiClient implements AiClient {
  @override
  final AiClientMeta meta;

  final Uri _endpoint;
  final http.Client _http;

  ClaudeAiClient({
    required http.Client httpClient,
    String model = 'claude-3-5-sonnet-latest',
    Uri? endpoint,
    double relativeCost = 1.2,
  })  : _http = httpClient,
        _endpoint = endpoint ?? Uri.parse('https://api.anthropic.com/v1/messages'),
        meta = AiClientMeta(
          model: AiModelRef(provider: AiProvider.claude, model: model),
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
      throw ArgumentError('Claude API key is required');
    }

    final userText = request.messages.where((m) => m.role == AiChatRole.user).map((m) => m.content).join('\n');

    final payload = {
      'model': meta.model.model,
      'max_tokens': 512,
      'messages': [
        {
          'role': 'user',
          'content': userText,
        },
      ],
    };

    final response = await _http.post(
      _endpoint,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Claude request failed: ${response.statusCode} ${response.body}', _endpoint);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected Claude response');
    }

    final content = decoded['content'];
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map && first['text'] is String) {
        return AiChatResponse(model: meta.model, text: first['text'] as String);
      }
    }

    return AiChatResponse(model: meta.model, text: '');
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
