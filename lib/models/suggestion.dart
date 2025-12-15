import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'suggestion.g.dart';

@HiveType(typeId: 1)
class Suggestion extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int priority;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? expiresAt;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  @HiveField(8)
  final bool isEnabled;

  Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.expiresAt,
    this.metadata = const {},
    this.isEnabled = true,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        priority,
        createdAt,
        expiresAt,
        metadata,
        isEnabled,
      ];

  Suggestion copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    bool? isEnabled,
  }) {
    return Suggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'isEnabled': isEnabled,
    };
  }

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      isEnabled: json['isEnabled'] as bool,
    );
  }
}