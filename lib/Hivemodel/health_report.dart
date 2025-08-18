import 'package:hive/hive.dart';

part 'health_report.g.dart';

@HiveType(typeId: 5) // make sure unique across your app
class HealthReport extends HiveObject {
  @HiveField(0)
  final String id; // uuid as string

  @HiveField(1)
  final String childId;

  @HiveField(2)
  final String notes;

  @HiveField(3)
  final DateTime reportDate;

  @HiveField(4)
  final String? systolic;

  @HiveField(5)
  final String? diastolic;

  @HiveField(6)
  final String? cholesterol;

  HealthReport({
    required this.id,
    required this.childId,
    required this.notes,
    required this.reportDate,
    this.systolic,
    this.diastolic,
    this.cholesterol,
  });
}
