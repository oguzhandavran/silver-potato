import '../ai_models.dart';

class AiSettings {
  final String? geminiApiKey;
  final String? openAiApiKey;
  final String? claudeApiKey;

  /// Model enablement overrides.
  ///
  /// Key format: `${provider}:${model}`.
  final Map<String, bool> modelToggles;

  const AiSettings({
    this.geminiApiKey,
    this.openAiApiKey,
    this.claudeApiKey,
    this.modelToggles = const {},
  });

  AiSettings copyWith({
    String? geminiApiKey,
    String? openAiApiKey,
    String? claudeApiKey,
    Map<String, bool>? modelToggles,
  }) {
    return AiSettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      modelToggles: modelToggles ?? this.modelToggles,
    );
  }

  String? apiKeyForProvider(AiProvider provider) {
    return switch (provider) {
      AiProvider.gemini => geminiApiKey,
      AiProvider.openai => openAiApiKey,
      AiProvider.claude => claudeApiKey,
      AiProvider.offline => null,
    };
  }

  bool isModelEnabled(AiModelRef model, {bool defaultValue = true}) {
    return modelToggles[model.id] ?? defaultValue;
  }

  Map<String, Object?> toJson() {
    return {
      'geminiApiKey': geminiApiKey,
      'openAiApiKey': openAiApiKey,
      'claudeApiKey': claudeApiKey,
      'modelToggles': modelToggles,
    };
  }

  static AiSettings fromJson(Map<String, Object?> json) {
    final togglesRaw = json['modelToggles'];
    final Map<String, bool> toggles;
    if (togglesRaw is Map) {
      toggles = togglesRaw.map((key, value) {
        return MapEntry(key.toString(), value == true);
      });
    } else {
      toggles = const {};
    }

    return AiSettings(
      geminiApiKey: json['geminiApiKey'] as String?,
      openAiApiKey: json['openAiApiKey'] as String?,
      claudeApiKey: json['claudeApiKey'] as String?,
      modelToggles: toggles,
    );
  }
}
