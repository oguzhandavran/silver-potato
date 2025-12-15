import 'dart:convert';

enum ContextEventSource {
  notification,
  accessibility,
  usageStats,
  audioFeatures,
}

class ContextEvent {
  final ContextEventSource source;
  final String type;
  final DateTime timestamp;
  final Map<String, Object?> data;

  const ContextEvent({
    required this.source,
    required this.type,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'source': source.name,
      'type': type,
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory ContextEvent.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'];
    final type = json['type'];
    final timestampMs = json['timestampMs'];

    if (sourceName is! String || type is! String || timestampMs is! num) {
      throw const FormatException('Invalid ContextEvent JSON');
    }

    final source = ContextEventSource.values.byName(sourceName);
    final data = (json['data'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{};

    return ContextEvent(
      source: source,
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt()),
      data: data,
    );
  }

  factory ContextEvent.fromPlatformJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Invalid platform event payload');
    }

    final map = decoded.cast<String, Object?>();

    final sourceName = map['source'];
    final type = map['type'];
    final timestampMs = map['timestampMs'];

    if (sourceName is! String || type is! String || timestampMs is! num) {
      throw const FormatException('Invalid platform event payload');
    }

    final source = ContextEventSource.values.byName(sourceName);
    final data = Map<String, Object?>.from(map)
      ..remove('source')
      ..remove('type')
      ..remove('timestampMs');

    return ContextEvent(
      source: source,
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt()),
      data: data,
    );
  }
}
