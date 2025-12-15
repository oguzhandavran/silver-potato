import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'user_preference.g.dart';

@HiveType(typeId: 2)
class UserPreference extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String key;

  @HiveField(3)
  final dynamic value;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String? description;

  @HiveField(7)
  final bool isEncrypted;

  UserPreference({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isEncrypted = false,
  });

  @override
  List<Object?> get props => [
        id,
        category,
        key,
        value,
        createdAt,
        updatedAt,
        description,
        isEncrypted,
      ];

  UserPreference copyWith({
    String? id,
    String? category,
    String? key,
    dynamic value,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    bool? isEncrypted,
  }) {
    return UserPreference(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  T getValueAs<T>() {
    return value as T;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'key': key,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'isEncrypted': isEncrypted,
    };
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'] as String,
      category: json['category'] as String,
      key: json['key'] as String,
      value: json['value'],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      isEncrypted: json['isEncrypted'] as bool,
    );
  }
}