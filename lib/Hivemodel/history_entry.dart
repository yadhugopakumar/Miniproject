import 'package:hive/hive.dart';
part 'history_entry.g.dart';

@HiveType(typeId: 2)
class HistoryEntry extends HiveObject {
  @HiveField(0)
  DateTime date; // Date of the medicine intake

  @HiveField(1)
  String medicineName; // e.g. "Paracetamol@08:00"

  @HiveField(2)
  String status; // 'taken', 'skipped', 'missed'

  @HiveField(3)
  String? time; // Exact time medicine was taken

  @HiveField(4)
  int snoozeCount; // Number of 5-min snoozes

  @HiveField(5)
  String? medicineId; // Link to medicine table in Supabase

  @HiveField(6)
  String? remoteId; // Supabase UUID for syncing

  @HiveField(7)
  String? childId; // Which child this entry belongs to

  HistoryEntry({
    required this.date,
    required this.medicineName,
    required this.status,
    this.time,
    this.snoozeCount = 0,
    this.medicineId,
    this.remoteId,
    this.childId,
  });
}
