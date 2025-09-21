import 'package:alarm/alarm.dart';
import 'package:hive_flutter/adapters.dart';
import '../../Hivemodel/alarm_model.dart';
import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/medicine.dart';
import 'notification_service.dart';

class HistoryService {
  // Use async for database operations
  static Future<void> updateHistoryStatus(
    String medicineName,
    String time,
    String status, {
    int snoozeCount = 0,
  }) async {
    final historyBox = Hive.box<HistoryEntry>('historyBox');
    final medicinesBox = Hive.box<Medicine>('medicinesBox');
    final now = DateTime.now();

    // Key format
    final key = '${medicineName}@${time}_${now.year}-${now.month}-${now.day}';

    // Lookup medicine ID dynamically
    final Medicine? medicine = medicinesBox.values
        .cast<Medicine?>()
        .firstWhere((med) => med != null && med.name == medicineName, orElse: () => null);

    if (medicine == null) {
      print("⚠️ Medicine not found for name: $medicineName");
      return;
    }

    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    HistoryEntry? entry;
    if (historyBox.containsKey(key)) {
      // Update existing entry
      entry = historyBox.get(key);
      if (entry != null) {
        entry.status = status;
        entry.time = formattedTime;
        entry.snoozeCount = snoozeCount;
        entry.medicineId = medicine.id;
        await entry.save();
      }
    } else {
      // Create new entry
      entry = HistoryEntry(
        date: now,
        medicineName: medicineName,
        medicineId: medicine.id,
        status: status,
        time: formattedTime,
        snoozeCount: snoozeCount,
      );
      await historyBox.put(key, entry);
    }

    print("✅ History updated: $key → $status, snooze=$snoozeCount");
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
  // static Future<void> updateHistoryStatus(
  //   String medicineName, // e.g. "Paracetamol"
  //   String time, // e.g. "08:00"
  //   String status, {
  //   int snoozeCount = 0,
  // }) async {
  //   final historyBox = Hive.box<HistoryEntry>('historyBox');
  //   final now = DateTime.now();

  //   // ✅ Use the same key format as homepage
  //   final key = '${medicineName}@${time}_${now.year}-${now.month}-${now.day}';

  //   HistoryEntry? entry;
  //   if (historyBox.containsKey(key)) {
  //     // update existing entry
  //     entry = historyBox.get(key);
  //     entry!.status = status;
  //     entry.time =
  //         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  //     entry.snoozeCount = snoozeCount;
  //     await entry.save();
  //   } else {
  //     // create new entry if not exists
  //     entry = HistoryEntry(
  //       date: now,
  //       medicineName: "${medicineName}@${time}",
  //       medicineId: ,
  //       status: status,
  //       time:
  //           "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
  //       snoozeCount: snoozeCount,
  //     );
  //     await historyBox.put(key, entry);
  //   }

  //   print("✅ History updated: $key → $status, snooze=$snoozeCount");
  // }
//  Future<void> updateHistoryStatus(
//   String medicineName, // e.g. "Paracetamol"
//   String time, // e.g. "08:00"
//   String status, {
//   int snoozeCount = 0,
// }) async {
//   final historyBox = Hive.box<HistoryEntry>('historyBox');
//   final medicinesBox = Hive.box<Medicine>('medicinesBox');
//   final now = DateTime.now();

//   // Key format
//   final key = '${medicineName}@${time}_${now.year}-${now.month}-${now.day}';

//   // Lookup medicine ID dynamically by name
//  final Medicine? medicine = medicinesBox.values.cast<Medicine?>().firstWhere(
//   (med) => med != null && med.name == medicineName,
//   orElse: () => null,
// );


//   if (medicine == null) {
//     print("⚠️ Medicine not found for name: $medicineName");
//     return;
//   }

//   final formattedTime =
//       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

//   HistoryEntry? entry;
//   if (historyBox.containsKey(key)) {
//     // Update existing entry
//     entry = historyBox.get(key);
//     if (entry != null) {
//       entry.status = status;
//       entry.time = formattedTime;
//       entry.snoozeCount = snoozeCount;
//       entry.medicineId = medicine.id; // assign medicine ID
//       await entry.save();
//     }
//   } else {
//     // Create new entry if not exists
//     entry = HistoryEntry(
//       date: now,
//       medicineName: medicineName, // store name only
//       medicineId: medicine.id,    // set medicine ID
//       status: status,
//       time: formattedTime,
//       snoozeCount: snoozeCount,
//     );
//     await historyBox.put(key, entry);
//   }

//   print("✅ History updated: $key → $status, snooze=$snoozeCount");
// }
//   }


  
  static Future<void> snoozeAlarm(AlarmModel alarm) async {
    try {
      print('🔔 Snoozing alarm id: ${alarm.id}');

      // Stop any existing snooze alarm
      if (alarm.snoozeId != null) {
        print('⏹ Stopping previous snooze id: ${alarm.snoozeId}');
        await Alarm.stop(alarm.snoozeId!);
        await box.delete(alarm.snoozeId!); // remove old snooze from Hive
      }

      // Cancel main notification if needed
      await NotificationService.cancelAlarm(alarm.id);

      // Assign a new snooze ID
      final snoozeId = alarm.id + 10000;
      alarm.snoozeId = snoozeId;

      // Update history
      print('📝 Updating history for snooze');
      final time =
          '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
      await HistoryService.updateHistoryStatus(alarm.medicineName, time, "snoozed",
          snoozeCount: 1);

      // Update alarm model
      alarm.lastAction = 'snoozed';
      alarm.lastActionTime = DateTime.now();
      await box.put(alarm.id, alarm);

      // Create a separate AlarmModel for snooze so getAlarmById works
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
      final snoozeTime =
          DateTime.now().add(const Duration(minutes: 1)); // change as needed
      print('⏰ Scheduling snooze for $snoozeTime with id $snoozeId');

      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: snoozeId,
          dateTime: snoozeTime,
          assetAudioPath: '', // sound handled in AlarmRingScreen
          notificationTitle: '${alarm.title} (Snoozed)', // required
          notificationBody: alarm.description, // required
          loopAudio: true,
          vibrate: false,
          enableNotificationOnKill: true,
          androidFullScreenIntent: true,
        ),
      );

      print('✅ Snooze scheduled successfully');

      // Schedule next main alarm if repeating
      if (alarm.isRepeating) {
        print('📅 Scheduling main alarm for next repetition');
        await _scheduleAlarm(alarm);
      }
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

      // Update history
      final now = DateTime.now();

      final time =
          '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';

      if (alarm.lastAction == 'snoozed' && alarm.lastActionTime != null) {
        final diffMinutes = now.difference(alarm.lastActionTime!).inMinutes;
        final snoozeCount = (diffMinutes / 5).ceil();
        print('📝 Updating history: takenLate, snoozeCount=$snoozeCount');
        await HistoryService.updateHistoryStatus(alarm.medicineName, time, "takenLate",
            snoozeCount: snoozeCount);
      } else {
        print('📝 Updating history: taken');
        await HistoryService.updateHistoryStatus(alarm.medicineName, time, "taken");
      }

      // Update alarm model
      alarm.lastAction = 'taken';
      alarm.lastActionTime = now;
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

  // ... rest of your existing methods
}
