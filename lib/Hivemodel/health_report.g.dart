// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthReportAdapter extends TypeAdapter<HealthReport> {
  @override
  final int typeId = 5;

  @override
  HealthReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthReport(
      id: fields[0] as String,
      childId: fields[1] as String,
      notes: fields[2] as String,
      reportDate: fields[3] as DateTime,
      systolic: fields[4] as String?,
      diastolic: fields[5] as String?,
      cholesterol: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthReport obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.childId)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.reportDate)
      ..writeByte(4)
      ..write(obj.systolic)
      ..writeByte(5)
      ..write(obj.diastolic)
      ..writeByte(6)
      ..write(obj.cholesterol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
