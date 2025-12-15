import 'ai_settings.dart';

abstract class AiSettingsStore {
  Future<AiSettings> load();

  Future<void> save(AiSettings settings);
}

class InMemoryAiSettingsStore implements AiSettingsStore {
  AiSettings _settings;

  InMemoryAiSettingsStore([AiSettings? initial]) : _settings = initial ?? const AiSettings();

  @override
  Future<AiSettings> load() async => _settings;

  @override
  Future<void> save(AiSettings settings) async {
    _settings = settings;
  }
}
