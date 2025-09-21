// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 10;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String?,
      dosage: fields[13] as String,
      hour: fields[3] as int,
      minute: fields[4] as int,
      medicineName: fields[12] as String,
      isRepeating: fields[5] as bool,
      selectedDays: (fields[6] as List?)?.cast<bool>(),
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      lastTriggered: fields[9] as DateTime?,
      lastAction: fields[10] as String?,
      lastActionTime: fields[11] as DateTime?,
    )..snoozeId = fields[14] as int?;
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.hour)
      ..writeByte(4)
      ..write(obj.minute)
      ..writeByte(5)
      ..write(obj.isRepeating)
      ..writeByte(6)
      ..write(obj.selectedDays)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastTriggered)
      ..writeByte(10)
      ..write(obj.lastAction)
      ..writeByte(11)
      ..write(obj.lastActionTime)
      ..writeByte(12)
      ..write(obj.medicineName)
      ..writeByte(13)
      ..write(obj.dosage)
      ..writeByte(14)
      ..write(obj.snoozeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
