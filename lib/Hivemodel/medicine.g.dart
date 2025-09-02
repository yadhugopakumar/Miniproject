// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 1;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      id: fields[8] as String,
      name: fields[0] as String,
      dosage: fields[1] as String,
      expiryDate: fields[2] as DateTime,
      dailyIntakeTimes: (fields[3] as List).cast<String>(),
      totalQuantity: fields[5] as int,
      quantityLeft: fields[6] as int,
      refillThreshold: fields[7] as int,
      instructions: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.dosage)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.dailyIntakeTimes)
      ..writeByte(5)
      ..write(obj.totalQuantity)
      ..writeByte(6)
      ..write(obj.quantityLeft)
      ..writeByte(7)
      ..write(obj.refillThreshold)
      ..writeByte(8)
      ..write(obj.id)
      ..writeByte(9)
      ..write(obj.instructions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
