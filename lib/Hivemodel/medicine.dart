import 'package:hive/hive.dart';
part 'medicine.g.dart';

@HiveType(typeId: 1)
class Medicine extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String dosage;

  @HiveField(2)
  DateTime expiryDate;

  @HiveField(3)
  List<String> dailyIntakeTimes; // Store times as strings: "08:00", "14:30"

  @HiveField(5)
  int totalQuantity; // Total tablets initially added

  @HiveField(6)
  int quantityLeft; // Updates as doses are taken

  @HiveField(7)
  int refillThreshold; // Alert if quantityLeft <= threshold
  @HiveField(8)
  String id; // instead of int id

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.expiryDate,
    required this.dailyIntakeTimes,
    required this.totalQuantity,
    required this.quantityLeft,
    required this.refillThreshold,
  });
}
