
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static const String _boxName = 'alarms';
  static Box<AlarmModel>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AlarmModelAdapter());
    Hive.registerAdapter(AlarmHistoryAdapter());
    _box = await Hive.openBox<AlarmModel>(_boxName);
  }

  static Box<AlarmModel> get box => _box!;

  static List<AlarmModel> getAllAlarms() {
    return box.values.toList()
      ..sort((a, b) => '${a.hour}:${a.minute}'.compareTo('${b.hour}:${b.minute}'));
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    await box.put(alarm.id, alarm);
    await _scheduleAlarm(alarm);
  }

  static Future<void> deleteAlarm(int id) async {
    await box.delete(id);
    await Alarm.stop(id);
    await Alarm.stop(id + 10000);
  }

  static Future<void> toggleAlarm(AlarmModel alarm) async {
    alarm.isActive = !alarm.isActive;
    await box.put(alarm.id, alarm);
    
    if (alarm.isActive) {
      await _scheduleAlarm(alarm);
    } else {
      await Alarm.stop(alarm.id);
      await Alarm.stop(alarm.id + 10000);
    }
  }

  // Log alarm trigger
  static Future<void> logAlarmTriggered(AlarmModel alarm) async {
    alarm.lastTriggered = DateTime.now();
    alarm.history.add(AlarmHistory(
      timestamp: DateTime.now(),
      action: 'triggered',
    ));
    await box.put(alarm.id, alarm);
  }

  static Future<void> snoozeAlarm(AlarmModel alarm) async {
    await Alarm.stop(alarm.id);

    // LOG SNOOZE ACTION
    alarm.lastAction = 'snoozed';
    alarm.lastActionTime = DateTime.now();
    alarm.history.add(AlarmHistory(
      timestamp: DateTime.now(),
      action: 'snoozed',
      note: 'Snoozed for 5 minutes',
    ));
    await box.put(alarm.id, alarm);

    // Schedule snooze
    final snoozeTime = DateTime.now().add(const Duration(minutes: 2));
    final snoozeSettings = AlarmSettings(
      id: alarm.id + 10000,
      dateTime: snoozeTime,
      assetAudioPath: 'sounds/alarm.mp3',
      loopAudio: true,
      vibrate: false, // ❌ no vibration here
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

  static Future<void> dismissAlarm(AlarmModel alarm) async {
    await Alarm.stop(alarm.id);
    await Alarm.stop(alarm.id + 10000);

    // LOG TAKEN ACTION
    alarm.lastAction = 'taken';
    alarm.lastActionTime = DateTime.now();
    alarm.history.add(AlarmHistory(
      timestamp: DateTime.now(),
      action: 'taken',
      note: 'Medication taken successfully',
    ));
    await box.put(alarm.id, alarm);

    if (alarm.isRepeating) {
      await _scheduleAlarm(alarm);
    } else {
      alarm.isActive = false;
      await box.put(alarm.id, alarm);
    }
  }

  static Future<void> _scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isActive) return;

    final now = DateTime.now();
    DateTime nextAlarm = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    
    if (nextAlarm.isBefore(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: nextAlarm,
      assetAudioPath: 'sounds/alarm.mp3',
      loopAudio: true,
      vibrate: false, // ❌ vibration handled manually in AlarmRingScreen
      fadeDuration: 3.0,
      notificationTitle: alarm.title,
      notificationBody: alarm.description,
      enableNotificationOnKill: true,
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      if (kDebugMode) print('Alarm scheduled for: ${nextAlarm.toString()}');
    } catch (e) {
      if (kDebugMode) print('Error scheduling alarm: $e');
    }
  }
}
