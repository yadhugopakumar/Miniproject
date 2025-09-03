import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/history_entry.dart';
import 'notification_service.dart';

class AlarmService {
  static const String _boxName = 'alarms';
  static Box? _box;

  static Future<void> init() async {
    // Don't call Hive.initFlutter() again if already called in main.dart
    if (!Hive.isAdapterRegistered(AlarmModelAdapter().typeId)) {
      Hive.registerAdapter(AlarmModelAdapter());
    }

    _box = await Hive.openBox<AlarmModel>(_boxName);
  }

  static Box get box => _box!;

  static AlarmModel? getAlarmById(int id) {
    final box = Hive.box<AlarmModel>('alarms');
    return box.get(id);
  }

  static List<AlarmModel> getAllAlarms() {
    return box.values.cast<AlarmModel>().toList()
      ..sort(
          (a, b) => '${a.hour}:${a.minute}'.compareTo('${b.hour}:${b.minute}'));
  }

  static Future saveAlarm(AlarmModel alarm) async {
    // Stop any existing alarms with same ID before re-scheduling
    await Alarm.stop(alarm.id);
    await Alarm.stop(alarm.id + 10000);
    await NotificationService.cancelAlarm(alarm.id);

    await box.put(alarm.id, alarm);
    if (alarm.isActive) {
      await _scheduleAlarm(alarm);
    }
  }

  static Future deleteAlarm(int id) async {
    await box.delete(id);
    await Alarm.stop(id);
    await Alarm.stop(id + 10000);
    // CANCEL BACKUP NOTIFICATION TOO
    await NotificationService.cancelAlarm(id);
  }

  static Future toggleAlarm(AlarmModel alarm) async {
    alarm.isActive = !alarm.isActive;
    await box.put(alarm.id, alarm);
    if (alarm.isActive) {
      await _scheduleAlarm(alarm);
    } else {
      await Alarm.stop(alarm.id);
      await Alarm.stop(alarm.id + 10000);
      // CANCEL BACKUP NOTIFICATION
      await NotificationService.cancelAlarm(alarm.id);
    }
  }

  static Future<void> updateHistoryStatus(
      String medicineName, String status) async {
    final historyBox = Hive.box<HistoryEntry>('historyBox');
    final today = DateTime.now();
    final todayKey = "$medicineName-${today.year}-${today.month}-${today.day}";

    final now = DateTime.now();
    final entry = HistoryEntry(
      date: today,
      medicineName: medicineName,
      status: status,
      time:
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
    );

    await historyBox.put(todayKey, entry);
  }

  static Future snoozeAlarm(AlarmModel alarm) async {
    await Alarm.stop(alarm.id);
    // CANCEL BACKUP NOTIFICATION
    await NotificationService.cancelAlarm(alarm.id);

    // LOG SNOOZE ACTION
    alarm.lastAction = 'snoozed';
    alarm.lastActionTime = DateTime.now();

    await box.put(alarm.id, alarm);
    updateHistoryStatus(alarm.medicineName, "snoozed");

    // Schedule snooze
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeSettings = AlarmSettings(
      id: alarm.id + 10000,
      dateTime: snoozeTime,
      assetAudioPath: 'sounds/alarm.mp3',
      loopAudio: true,
      vibrate: false,
      fadeDuration: 3.0,
      notificationTitle: '${alarm.title} (Snoozed)',
      notificationBody: alarm.description,
      enableNotificationOnKill: true,
    );
    await Alarm.set(alarmSettings: snoozeSettings);
    if (alarm.isRepeating) {
      await _scheduleAlarm(alarm);
    }
  }

  static Future dismissAlarm(AlarmModel alarm) async {
    await Alarm.stop(alarm.id);
    await Alarm.stop(alarm.id + 10000);
    // CANCEL BACKUP NOTIFICATION
    await NotificationService.cancelAlarm(alarm.id);

    // LOG TAKEN ACTION
    alarm.lastAction = 'taken';
    alarm.lastActionTime = DateTime.now();

    await box.put(alarm.id, alarm);
    if (alarm.lastTriggered != null &&
        DateTime.now().difference(alarm.lastTriggered!).inMinutes > 30) {
      updateHistoryStatus(alarm.medicineName, "lateTaken");
    } else {
      updateHistoryStatus(alarm.medicineName, "taken");
    }

    if (alarm.isRepeating) {
      await _scheduleAlarm(alarm);
    } else {
      alarm.isActive = false;
      await box.put(alarm.id, alarm);
    }
  }

  static Future _scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isActive) return;

    final now = DateTime.now();
    DateTime nextAlarm =
        DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    if (nextAlarm.isBefore(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    try {
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: alarm.id,
          dateTime: nextAlarm,
          assetAudioPath: 'sounds/alarm.mp3',
          loopAudio: true,
          vibrate: false,
          fadeDuration: 3.0,
          notificationTitle: alarm.title,
          notificationBody: alarm.description,
          enableNotificationOnKill: true,
        ),
      );

      if (kDebugMode) print('✅ Main alarm scheduled: $nextAlarm');

      // backup schedule
      await NotificationService.scheduleBackupAlarm(alarm);
    } catch (e) {
      if (kDebugMode) print('❌ Error scheduling alarm: $e');
    }
  }

  // Log alarm trigger
  static Future<void> logAlarmTriggered(AlarmModel alarm) async {
    alarm.lastTriggered = DateTime.now();

    await box.put(alarm.id, alarm);
  }

  // ... rest of your existing methods
}
