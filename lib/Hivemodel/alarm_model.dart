import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 10) // keep same typeId if you already used 10
class AlarmModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  int hour;

  @HiveField(4)
  int minute;

  @HiveField(5)
  bool isRepeating;

  @HiveField(6)
  List<bool> selectedDays;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  // Status tracking fields
  @HiveField(9)
  DateTime? lastTriggered;

  @HiveField(10)
  String? lastAction; // 'snoozed', 'taken', 'missed'

  @HiveField(11)
  DateTime? lastActionTime;

  @HiveField(12)
  String medicineName;
  @HiveField(13)
  String dosage;
  @HiveField(14)
  int? snoozeId;
  @HiveField(15) // next available Hive field number
  int snoozeCount;

  AlarmModel({
    required this.id,
    required this.title,
    String? description,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.medicineName,
    this.isRepeating = true,
    List<bool>? selectedDays,
    this.isActive = true,
    DateTime? createdAt,
    this.lastTriggered,
    this.lastAction,
    this.lastActionTime,
      this.snoozeCount = 0, // initialize to 0
  })  : selectedDays = selectedDays ?? List.filled(7, true),
        createdAt = createdAt ?? DateTime.now(),
        description = description ?? "";

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get statusText {
    if (lastActionTime != null && _isToday(lastActionTime!)) {
      switch (lastAction) {
        case 'taken':
          return 'Taken today at ${_formatTime(lastActionTime!)}';
        case 'snoozed':
          return 'Snoozed today at ${_formatTime(lastActionTime!)}';
        case 'missed':
          return 'Missed today';
        default:
          return 'Scheduled';
      }
    }
    return 'Scheduled';
  }

  bool get isTakenToday {
    return lastAction == 'taken' &&
        lastActionTime != null &&
        _isToday(lastActionTime!);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
