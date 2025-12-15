// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference.dart';

// **************************************************************************
// TypeAdapter
// **************************************************************************

class UserPreferenceAdapter extends TypeAdapter<UserPreference> {
  @override
  final int typeId = 2;

  @override
  UserPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreference(
      id: fields[0] as String,
      category: fields[1] as String,
      key: fields[2] as String,
      value: fields[3],
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      description: fields[6] as String?,
      isEncrypted: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreference obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.key)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.isEncrypted);
  }
}