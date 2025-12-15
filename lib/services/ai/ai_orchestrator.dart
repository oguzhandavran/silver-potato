import 'package:meta/meta.dart';

import 'ai_client.dart';
import 'ai_models.dart';
import 'settings/ai_settings.dart';
import 'settings/ai_settings_store.dart';

class AiRoutingDecision {
  final AiClientMeta selected;
  final List<AiClientMeta> candidates;

  const AiRoutingDecision({required this.selected, required this.candidates});
}

class AiNoAvailableClientException implements Exception {
  final String message;

  const AiNoAvailableClientException(this.message);

  @override
  String toString() => 'AiNoAvailableClientException: $message';
}

@visibleForTesting
AiRoutingDecision decideAiRoute({
  required List<AiClient> clients,
  required AiChatRequest request,
  required AiSettings settings,
  required AiRuntimeContext runtime,
  required bool needsStreaming,
}) {
  final needsFunctions = request.needsFunctionCalling;

  bool isClientConfigured(AiClient client) {
    if (!client.meta.requiresApiKey) {
      return true;
    }
    final key = settings.apiKeyForProvider(client.meta.model.provider);
    return key != null && key.isNotEmpty;
  }

  final candidates = clients.where((client) {
    final meta = client.meta;
    if (!settings.isModelEnabled(meta.model, defaultValue: true)) {
      return false;
    }
    if (!isClientConfigured(client)) {
      return false;
    }
    if (runtime.isOffline && !meta.supportsOffline) {
      return false;
    }
    if (needsStreaming && !meta.supportsStreaming) {
      return false;
    }
    if (needsFunctions && !meta.supportsFunctionCalling) {
      return false;
    }
    if (!meta.supportedTaskTypes.contains(request.taskType) && !meta.supportedTaskTypes.contains(AiTaskType.general)) {
      return false;
    }
    return true;
  }).toList();

  if (candidates.isEmpty) {
    throw const AiNoAvailableClientException('No enabled AI client matched the request and current settings');
  }

  double score(AiClientMeta meta) {
    var s = meta.relativeCost;

    if (!runtime.isOffline && meta.isOfflineFallback) {
      s += 1000;
    }

    if (request.taskType == AiTaskType.coding && meta.model.provider == AiProvider.claude) {
      s -= 2;
    }

    if (request.taskType == AiTaskType.summarize && meta.model.provider == AiProvider.gemini) {
      s -= 1;
    }

    if (request.taskType == AiTaskType.functionCalling && meta.supportsFunctionCalling) {
      s -= 1;
    }

    if (runtime.isOffline && meta.supportsOffline) {
      s -= 10;
    }

    return s;
  }

  candidates.sort((a, b) => score(a.meta).compareTo(score(b.meta)));

  return AiRoutingDecision(
    selected: candidates.first.meta,
    candidates: candidates.map((c) => c.meta).toList(growable: false),
  );
}

class AiOrchestrator {
  final AiSettingsStore _settingsStore;
  final List<AiClient> _clients;

  const AiOrchestrator({
    required AiSettingsStore settingsStore,
    required List<AiClient> clients,
  })  : _settingsStore = settingsStore,
        _clients = clients;

  Future<AiChatResponse> chat(
    AiChatRequest request, {
    AiRuntimeContext runtime = const AiRuntimeContext(),
  }) async {
    final settings = await _settingsStore.load();
    final decision = decideAiRoute(
      clients: _clients,
      request: request,
      settings: settings,
      runtime: runtime,
      needsStreaming: false,
    );

    final client = _clients.firstWhere((c) => c.meta.model.id == decision.selected.model.id);
    final credentials = AiClientCredentials(apiKey: settings.apiKeyForProvider(client.meta.model.provider));
    final response = await client.chat(request, credentials: credentials);

    return AiChatResponse(
      model: client.meta.model,
      text: response.text,
      toolCalls: response.toolCalls,
    );
  }

  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    AiRuntimeContext runtime = const AiRuntimeContext(),
  }) async* {
    final settings = await _settingsStore.load();
    final decision = decideAiRoute(
      clients: _clients,
      request: request,
      settings: settings,
      runtime: runtime,
      needsStreaming: true,
    );

    final client = _clients.firstWhere((c) => c.meta.model.id == decision.selected.model.id);
    final credentials = AiClientCredentials(apiKey: settings.apiKeyForProvider(client.meta.model.provider));

    final buffer = StringBuffer();
    final toolCalls = <AiToolCall>[];

    await for (final event in client.streamChat(request, credentials: credentials)) {
      if (event is AiStreamTextDelta) {
        buffer.write(event.delta);
        yield event;
      } else if (event is AiStreamToolCall) {
        toolCalls.add(event.toolCall);
        yield event;
      } else if (event is AiStreamDone) {
        // Ignore: orchestrator emits its own done event with model attribution.
      } else {
        yield event;
      }
    }

    yield AiStreamDone(
      AiChatResponse(
        model: client.meta.model,
        text: buffer.toString(),
        toolCalls: toolCalls,
      ),
    );
  }
}
