import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shell/services/ai/ai_client.dart';
import 'package:flutter_shell/services/ai/ai_models.dart';
import 'package:flutter_shell/services/ai/ai_orchestrator.dart';
import 'package:flutter_shell/services/ai/settings/ai_settings.dart';
import 'package:flutter_shell/services/ai/settings/ai_settings_store.dart';

class FakeAiClient implements AiClient {
  @override
  final AiClientMeta meta;

  final String responseText;
  final List<String> streamDeltas;

  FakeAiClient({
    required this.meta,
    this.responseText = '',
    this.streamDeltas = const [],
  });

  @override
  Future<AiChatResponse> chat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async {
    return AiChatResponse(model: meta.model, text: responseText);
  }

  @override
  Stream<AiStreamEvent> streamChat(
    AiChatRequest request, {
    required AiClientCredentials credentials,
  }) async* {
    for (final d in streamDeltas) {
      yield AiStreamTextDelta(d);
    }
  }
}

void main() {
  test('routes to offline client when runtime is offline', () {
    final offline = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.offline, model: 'rules'),
        relativeCost: 0,
        requiresApiKey: false,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: true,
        isOfflineFallback: true,
        supportedTaskTypes: {AiTaskType.general},
      ),
    );

    final gemini = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.gemini, model: 'flash'),
        relativeCost: 0.1,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.general},
      ),
    );

    final decision = decideAiRoute(
      clients: [offline, gemini],
      request: const AiChatRequest(messages: [AiChatMessage.user('hi')]),
      settings: const AiSettings(geminiApiKey: 'k'),
      runtime: const AiRuntimeContext(isOffline: true),
      needsStreaming: false,
    );

    expect(decision.selected.model.provider, AiProvider.offline);
  });

  test('routes to cheapest configured client by default', () {
    final cheap = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.gemini, model: 'flash'),
        relativeCost: 0.1,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.general},
      ),
    );

    final expensive = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.gemini, model: 'pro'),
        relativeCost: 5,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.general},
      ),
    );

    final decision = decideAiRoute(
      clients: [expensive, cheap],
      request: const AiChatRequest(messages: [AiChatMessage.user('hi')]),
      settings: const AiSettings(geminiApiKey: 'k'),
      runtime: const AiRuntimeContext(isOffline: false),
      needsStreaming: false,
    );

    expect(decision.selected.model.model, 'flash');
  });

  test('prefers Claude for coding tasks when available', () {
    final gemini = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.gemini, model: 'flash'),
        relativeCost: 0.1,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.coding, AiTaskType.general},
      ),
    );

    final claude = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.claude, model: 'sonnet'),
        relativeCost: 10,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: true,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.coding, AiTaskType.general},
      ),
    );

    final decision = decideAiRoute(
      clients: [gemini, claude],
      request: const AiChatRequest(messages: [AiChatMessage.user('write code')], taskType: AiTaskType.coding),
      settings: const AiSettings(geminiApiKey: 'g', claudeApiKey: 'c'),
      runtime: const AiRuntimeContext(isOffline: false),
      needsStreaming: false,
    );

    expect(decision.selected.model.provider, AiProvider.claude);
  });

  test('routes function-calling tasks to a function-capable client', () {
    final gemini = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.gemini, model: 'flash'),
        relativeCost: 0.1,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.functionCalling, AiTaskType.general},
      ),
    );

    final openai = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.openai, model: 'mini'),
        relativeCost: 1,
        requiresApiKey: true,
        supportsStreaming: true,
        supportsFunctionCalling: true,
        supportsOffline: false,
        isOfflineFallback: false,
        supportedTaskTypes: {AiTaskType.functionCalling, AiTaskType.general},
      ),
    );

    final decision = decideAiRoute(
      clients: [gemini, openai],
      request: const AiChatRequest(
        messages: [AiChatMessage.user('call tool')],
        taskType: AiTaskType.functionCalling,
        tools: [
          AiToolSpec(name: 'lookup', description: 'lookup', parametersJsonSchema: {'type': 'object'}),
        ],
      ),
      settings: const AiSettings(geminiApiKey: 'g', openAiApiKey: 'o'),
      runtime: const AiRuntimeContext(isOffline: false),
      needsStreaming: false,
    );

    expect(decision.selected.model.provider, AiProvider.openai);
  });

  test('orchestrator streaming yields done event with aggregated text', () async {
    final client = FakeAiClient(
      meta: const AiClientMeta(
        model: AiModelRef(provider: AiProvider.offline, model: 'rules'),
        relativeCost: 0,
        requiresApiKey: false,
        supportsStreaming: true,
        supportsFunctionCalling: false,
        supportsOffline: true,
        isOfflineFallback: true,
        supportedTaskTypes: {AiTaskType.general},
      ),
      streamDeltas: const ['a', 'b'],
    );

    final store = InMemoryAiSettingsStore(const AiSettings());
    final orchestrator = AiOrchestrator(settingsStore: store, clients: [client]);

    final stream = orchestrator.streamChat(const AiChatRequest(messages: [AiChatMessage.user('hi')]));

    await expectLater(
      stream,
      emitsInOrder([
        isA<AiStreamTextDelta>().having((e) => (e as AiStreamTextDelta).delta, 'delta', 'a'),
        isA<AiStreamTextDelta>().having((e) => (e as AiStreamTextDelta).delta, 'delta', 'b'),
        predicate<AiStreamEvent>(
          (e) => e is AiStreamDone && e.response.text == 'ab',
          'done with text',
        ),
      ]),
    );
  });
}
