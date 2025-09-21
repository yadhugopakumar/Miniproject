import 'package:hive/hive.dart';
part 'history_entry.g.dart';

@HiveType(typeId: 2)
class HistoryEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String medicineName; // e.g. "Paracetamol@08:00"

  @HiveField(2)
  String status; // 'taken' or 'skipped'

  @HiveField(3)
  String? time; // 'taken' or 'skipped'
  @HiveField(4)
  int snoozeCount; // NEW: number of 5-min snoozes

  HistoryEntry({
    required this.date,
    required this.medicineName,
    required this.status,
    this.time,
    this.snoozeCount = 0,
  });
}
