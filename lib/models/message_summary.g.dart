// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_summary.dart';

// **************************************************************************
// TypeAdapter
// **************************************************************************

class MessageSummaryAdapter extends TypeAdapter<MessageSummary> {
  @override
  final int typeId = 3;

  @override
  MessageSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageSummary(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      preview: fields[2] as String,
      messageCount: fields[3] as int,
      lastMessageAt: fields[4] as DateTime,
      senderName: fields[5] as String?,
      participants: (fields[6] as List).cast<String>(),
      category: fields[7] as String?,
      isRead: fields[8] as bool,
      metadata: (fields[9] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageSummary obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.preview)
      ..writeByte(3)
      ..write(obj.messageCount)
      ..writeByte(4)
      ..write(obj.lastMessageAt)
      ..writeByte(5)
      ..write(obj.senderName)
      ..writeByte(6)
      ..write(obj.participants)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.metadata);
  }
}