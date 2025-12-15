// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_event.dart';

// **************************************************************************
// TypeAdapter
// **************************************************************************

class ContextEventAdapter extends TypeAdapter<ContextEvent> {
  @override
  final int typeId = 0;

  @override
  ContextEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContextEvent(
      id: fields[0] as String,
      type: fields[1] as String,
      data: (fields[2] as Map).cast<String, dynamic>(),
      timestamp: fields[3] as DateTime,
      source: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContextEvent obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.tags);
  }
}