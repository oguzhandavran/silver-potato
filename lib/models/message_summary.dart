import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'message_summary.g.dart';

@HiveType(typeId: 3)
class MessageSummary extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String preview;

  @HiveField(3)
  final int messageCount;

  @HiveField(4)
  final DateTime lastMessageAt;

  @HiveField(5)
  final String? senderName;

  @HiveField(6)
  final List<String> participants;

  @HiveField(7)
  final String? category;

  @HiveField(8)
  final bool isRead;

  @HiveField(9)
  final Map<String, dynamic> metadata;

  MessageSummary({
    required this.id,
    required this.conversationId,
    required this.preview,
    required this.messageCount,
    required this.lastMessageAt,
    this.senderName,
    this.participants = const [],
    this.category,
    this.isRead = false,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        preview,
        messageCount,
        lastMessageAt,
        senderName,
        participants,
        category,
        isRead,
        metadata,
      ];

  MessageSummary copyWith({
    String? id,
    String? conversationId,
    String? preview,
    int? messageCount,
    DateTime? lastMessageAt,
    String? senderName,
    List<String>? participants,
    String? category,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return MessageSummary(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      preview: preview ?? this.preview,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      senderName: senderName ?? this.senderName,
      participants: participants ?? this.participants,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'preview': preview,
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'senderName': senderName,
      'participants': participants,
      'category': category,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory MessageSummary.fromJson(Map<String, dynamic> json) {
    return MessageSummary(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      preview: json['preview'] as String,
      messageCount: json['messageCount'] as int,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      senderName: json['senderName'] as String?,
      participants: (json['participants'] as List<dynamic>).cast<String>(),
      category: json['category'] as String?,
      isRead: json['isRead'] as bool,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}