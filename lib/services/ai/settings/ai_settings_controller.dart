import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai_models.dart';
import '../ai_providers.dart';
import 'ai_settings.dart';
import 'ai_settings_store.dart';

final aiSettingsControllerProvider = StateNotifierProvider<AiSettingsController, AsyncValue<AiSettings>>((ref) {
  final store = ref.watch(aiSettingsStoreProvider);
  return AiSettingsController(store);
});

class AiSettingsController extends StateNotifier<AsyncValue<AiSettings>> {
  final AiSettingsStore _store;

  AiSettingsController(this._store) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _store.load();
      state = AsyncData(settings);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> setApiKey(AiProvider provider, String? apiKey) async {
    final current = state.valueOrNull ?? const AiSettings();

    final updated = switch (provider) {
      AiProvider.gemini => current.copyWith(geminiApiKey: apiKey),
      AiProvider.openai => current.copyWith(openAiApiKey: apiKey),
      AiProvider.claude => current.copyWith(claudeApiKey: apiKey),
      AiProvider.offline => current,
    };

    state = AsyncData(updated);
    await _store.save(updated);
  }

  Future<void> setModelEnabled(AiModelRef model, bool enabled) async {
    final current = state.valueOrNull ?? const AiSettings();
    final toggles = Map<String, bool>.from(current.modelToggles);
    toggles[model.id] = enabled;

    final updated = current.copyWith(modelToggles: toggles);
    state = AsyncData(updated);
    await _store.save(updated);
  }

  Future<void> clear() async {
    const cleared = AiSettings();
    state = const AsyncData(cleared);
    await _store.save(cleared);
  }
}
