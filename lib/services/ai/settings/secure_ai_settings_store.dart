import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_shell/services/ai/settings/ai_settings.dart';
import 'package:flutter_shell/services/ai/settings/ai_settings_store.dart';

class SecureAiSettingsStore implements AiSettingsStore {
  static const _storageKey = 'ai_settings_v1';

  final FlutterSecureStorage _storage;

  const SecureAiSettingsStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AiSettings> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return const AiSettings();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const AiSettings();
    }

    return AiSettings.fromJson(decoded.cast<String, Object?>());
  }

  @override
  Future<void> save(AiSettings settings) async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(settings.toJson()),
    );
  }
}
