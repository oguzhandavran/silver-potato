import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'ai_orchestrator.dart';
import 'clients/claude_ai_client.dart';
import 'clients/gemini_ai_client.dart';
import 'clients/offline_ai_client.dart';
import 'clients/openai_ai_client.dart';
import 'settings/ai_settings_store.dart';
import 'settings/secure_ai_settings_store.dart';

final aiSettingsStoreProvider = Provider<AiSettingsStore>((ref) {
  return const SecureAiSettingsStore();
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiOrchestratorProvider = Provider<AiOrchestrator>((ref) {
  final settingsStore = ref.watch(aiSettingsStoreProvider);
  final httpClient = ref.watch(httpClientProvider);

  return AiOrchestrator(
    settingsStore: settingsStore,
    clients: [
      OfflineAiClient(),
      GeminiAiClient(model: 'gemini-1.5-flash', relativeCost: 0.2),
      OpenAiClient(httpClient: httpClient, model: 'gpt-4o-mini', relativeCost: 0.6),
      ClaudeAiClient(httpClient: httpClient, model: 'claude-3-5-sonnet-latest', relativeCost: 1.2),
    ],
  );
});
