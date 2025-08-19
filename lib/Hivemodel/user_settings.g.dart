// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 3;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      childId: fields[7] as String,
      parentId: fields[8] as String,
      username: fields[0] as String,
      pin: fields[1] as String,
      securityQuestion: fields[5] as String,
      securityAnswer: fields[6] as String,
      phone: fields[2] as String?,
      parentEmail: fields[3] as String?,
      alarmSound: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.pin)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.parentEmail)
      ..writeByte(4)
      ..write(obj.alarmSound)
      ..writeByte(5)
      ..write(obj.securityQuestion)
      ..writeByte(6)
      ..write(obj.securityAnswer)
      ..writeByte(7)
      ..write(obj.childId)
      ..writeByte(8)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
