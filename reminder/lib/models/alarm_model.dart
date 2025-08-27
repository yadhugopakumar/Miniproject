import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel {
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

  // NEW: Status tracking fields
  @HiveField(9)
  DateTime? lastTriggered;

  @HiveField(10)
  String? lastAction; // 'snoozed', 'taken', 'missed'

  @HiveField(11)
  DateTime? lastActionTime;

  @HiveField(12)
  List<AlarmHistory> history; // History of all actions

  AlarmModel({
    required this.id,
    required this.title,
    required this.description,
    required this.hour,
    required this.minute,
    this.isRepeating = true,
    List<bool>? selectedDays,
    this.isActive = true,
    DateTime? createdAt,
    this.lastTriggered,
    this.lastAction,
    this.lastActionTime,
    List<AlarmHistory>? history,
  }) : selectedDays = selectedDays ?? List.filled(7, true),
       createdAt = createdAt ?? DateTime.now(),
       history = history ?? [];

  String get timeString => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  
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
    return lastAction == 'taken' && lastActionTime != null && _isToday(lastActionTime!);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

@HiveType(typeId: 1)
class AlarmHistory {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String action; // 'triggered', 'snoozed', 'taken', 'missed'

  @HiveField(2)
  String? note;

  AlarmHistory({
    required this.timestamp,
    required this.action,
    this.note,
  });
}
