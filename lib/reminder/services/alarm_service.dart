import 'package:alarm/alarm.dart';
import 'package:hive_flutter/adapters.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/medicine.dart';
import 'notification_service.dart';
import '../../Hivemodel/user_settings.dart';
import '../../services/fetch_and_store_medicine.dart';
import 'package:collection/collection.dart';

class HistoryService {
  static Future<void> updateHistoryStatus(
    String medicineName,
    DateTime actionTime,
    String status, {
    int snoozeCount = 0,
  }) async {
    final historyBox = Hive.box<HistoryEntry>('historyBox');
    final medicinesBox = Hive.box<Medicine>('medicinesBox');
    final userBox = Hive.box<UserSettings>('settingsBox');
    final userSettings = userBox.get('user');
    if (userSettings == null) return;
    final childId = userSettings.childId;

    // Find the Medicine object by name
    final Medicine? medicine =
        medicinesBox.values.firstWhereOrNull((m) => m.name == medicineName);
    if (medicine == null) return;

    final formattedTime =
        "${actionTime.hour.toString().padLeft(2, '0')}:${actionTime.minute.toString().padLeft(2, '0')}";

    // Use medicineId in the key to match Supabase unique constraint
    final doseKey = buildDoseKey(
      medicine.id , // fallback to name if id null
      actionTime,
      formattedTime,
      childId,
    );

    final existingEntry = historyBox.get(doseKey);

    if (existingEntry != null) {
      // 🔹 Rules:
      // taken → always final
      // takenLate → always override snoozed/missed
      // missed → override snoozed, but not taken
      // snoozed → only set if not taken/takenLate
      if (status == "taken") {
        existingEntry.status = "taken";
      } else if (status == "takenLate") {
        existingEntry.status = "takenLate";
        existingEntry.statusChanged = true;
      } else if (status == "missed" && existingEntry.status != "taken") {
        existingEntry.status = "missed";
        existingEntry.statusChanged = true;
      } else if (status == "snoozed" &&
          existingEntry.status != "taken" &&
          existingEntry.status != "takenLate") {
        existingEntry.status = "snoozed";
        existingEntry.statusChanged = true;
      }

      existingEntry.snoozeCount = snoozeCount;
      await existingEntry.save();
    } else {
      // Create new entry
      final newEntry = HistoryEntry(
        date: actionTime,
        medicineName: medicineName,
        medicineId: medicine.id,
        status: status,
        time: formattedTime,
        snoozeCount: snoozeCount,
        childId: childId,
        statusChanged: true, // all new entries need syncing
      );
      await historyBox.put(doseKey, newEntry);
    }

    print("✅ History updated: $doseKey → $status, snooze=$snoozeCount");
  }
}

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

  static Future<void> snoozeAlarm(AlarmModel alarm) async {
    try {
      print('🔔 Snoozing alarm id: ${alarm.id}');

      // Stop any existing snooze alarm
      if (alarm.snoozeId != null) {
        print('⏹ Stopping previous snooze id: ${alarm.snoozeId}');
        await Alarm.stop(alarm.snoozeId!);
        await box.delete(alarm.snoozeId!); // remove old snooze from Hive
      }

      // Cancel main notification
      await NotificationService.cancelAlarm(alarm.id);

      // Assign a new snooze ID
      final snoozeId = alarm.id + 10000;
      alarm.snoozeId = snoozeId;

      // Use original alarm time for history
      final alarmTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        alarm.hour,
        alarm.minute,
      );

      // Update history
      final newSnoozeCount = (alarm.snoozeCount) + 1;
      print('📝 Updating history for snooze, snoozeCount=$newSnoozeCount');

      // When calling updateHistoryStatus
      await HistoryService.updateHistoryStatus(
        alarm.medicineName,
        alarmTime,
        "snoozed", // or "missed"/"takenLate"
        snoozeCount: newSnoozeCount,
      );

      // Update alarm model
      alarm.lastAction = 'snoozed';
      alarm.lastActionTime = DateTime.now();
      alarm.snoozeCount = newSnoozeCount;
      await box.put(alarm.id, alarm);

      // Create a separate AlarmModel for the snooze trigger
      final snoozeAlarm = AlarmModel(
        id: snoozeId,
        medicineName: alarm.medicineName,
        dosage: alarm.dosage,
        title: alarm.title,
        description: alarm.description,
        hour: DateTime.now().hour,
        minute: DateTime.now().minute,
        isRepeating: false,
      );
      await box.put(snoozeId, snoozeAlarm);

      // Schedule snooze alarm
      final snoozeTime = DateTime.now().add(const Duration(minutes: 1));
      print('⏰ Scheduling snooze for $snoozeTime with id $snoozeId');
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: snoozeId,
          dateTime: snoozeTime,
          assetAudioPath: '',
          notificationTitle: '${alarm.title} (Snoozed)',
          notificationBody: alarm.description,
          loopAudio: true,
          vibrate: false,
          enableNotificationOnKill: true,
          androidFullScreenIntent: true,
        ),
      );

      // Schedule next main alarm if repeating
      if (alarm.isRepeating) {
        print('📅 Scheduling main alarm for next repetition');
        await _scheduleAlarm(alarm);
      }

      print('✅ Snooze scheduled successfully');
    } catch (e, s) {
      print('❌ Error in snoozeAlarm: $e');
      print(s);
    }
  }

  static Future<void> dismissAlarm(AlarmModel alarm) async {
    try {
      print('✅ Dismissing alarm id: ${alarm.id}');

      // Stop main and snooze alarms
      await Alarm.stop(alarm.id);
      if (alarm.snoozeId != null) {
        print('⏹ Stopping snooze id: ${alarm.snoozeId}');
        await Alarm.stop(alarm.snoozeId!);
        alarm.snoozeId = null;
      }

      // Cancel notifications
      await NotificationService.cancelAlarm(alarm.id);

      // Use the original alarm time for history
      final alarmTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        alarm.hour,
        alarm.minute,
      );

      // Determine status and snooze count
      String status;
      int snoozeCount = alarm.snoozeCount;

      if (alarm.lastAction == 'snoozed') {
        status = 'takenLate';
        snoozeCount += 1; // include last snooze
      } else {
        status = 'taken';
      }

      print('📝 Updating history: $status, snoozeCount=$snoozeCount');

      // Always upgrade snoozed to takenLate
      if (alarm.lastAction == 'snoozed' || status == 'snoozed') {
        status = 'takenLate';
      }

      await HistoryService.updateHistoryStatus(
        alarm.medicineName,
        alarmTime,
        status,
        snoozeCount: snoozeCount,
      );

      // Update alarm model
      alarm.lastAction = 'taken';
      alarm.lastActionTime = DateTime.now();
      alarm.snoozeCount = 0; // reset after taken
      await box.put(alarm.id, alarm);

      // Schedule next alarm if repeating
      if (alarm.isRepeating) {
        print('📅 Scheduling next main alarm for repetition');
        await _scheduleAlarm(alarm);
      } else {
        alarm.isActive = false;
        await box.put(alarm.id, alarm);
        print('⏹ Alarm deactivated');
      }
    } catch (e, s) {
      print('❌ Error in dismissAlarm: $e');
      print(s);
    }
  }

  static Future<void> _scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isActive) {
      print('⏹ Alarm id ${alarm.id} is inactive, skipping schedule');
      return;
    }

    final now = DateTime.now();
    DateTime nextAlarm =
        DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    if (nextAlarm.isBefore(now))
      nextAlarm = nextAlarm.add(const Duration(days: 1));

    try {
      print('⏰ Scheduling main alarm id ${alarm.id} at $nextAlarm');
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: alarm.id,
          dateTime: nextAlarm,
          assetAudioPath: 'sounds/alarm2.mp3',
          loopAudio: true,
          vibrate: false,
          fadeDuration: 3.0,
          notificationTitle: alarm.title,
          notificationBody: alarm.description,
          enableNotificationOnKill: true,
        ),
      );

      print('✅ Main alarm scheduled: $nextAlarm');

      // Backup
      await NotificationService.scheduleBackupAlarm(alarm);
      print('🔔 Backup notification scheduled');
    } catch (e, s) {
      print('❌ Error scheduling main alarm: $e');
      print(s);
    }
  }

  // Log alarm trigger
  static Future<void> logAlarmTriggered(AlarmModel alarm) async {
    alarm.lastTriggered = DateTime.now();

    await box.put(alarm.id, alarm);
  }

}
