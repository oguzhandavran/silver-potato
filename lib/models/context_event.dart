import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'context_event.g.dart';

@HiveType(typeId: 0)
class ContextEvent extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String source;

  @HiveField(5)
  final List<String> tags;

  ContextEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.source,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [id, type, data, timestamp, source, tags];

  ContextEvent copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? source,
    List<String>? tags,
  }) {
    return ContextEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'tags': tags,
    };
  }

  factory ContextEvent.fromJson(Map<String, dynamic> json) {
    return ContextEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }
}