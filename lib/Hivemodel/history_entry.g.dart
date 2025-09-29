// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 2;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      date: fields[0] as DateTime,
      medicineName: fields[1] as String,
      status: fields[2] as String,
      time: fields[3] as String?,
      snoozeCount: fields[4] as int,
      medicineId: fields[5] as String?,
      remoteId: fields[6] as String?,
      childId: fields[7] as String?,
      statusChanged: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.medicineName)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.snoozeCount)
      ..writeByte(5)
      ..write(obj.medicineId)
      ..writeByte(6)
      ..write(obj.remoteId)
      ..writeByte(7)
      ..write(obj.childId)
      ..writeByte(8)
      ..write(obj.statusChanged);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
