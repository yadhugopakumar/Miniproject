import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../Hivemodel/alarm_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Backup Alarms',
      description: 'Backup alarm notifications when app is closed',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestFullScreenIntentPermission();

    // Add to your init() method
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // ADD THIS: Critical for preventing notification cancellation when app is killed
  }

  static Future<void> _requestBatteryOptimizationPermissions() async {
    // Check if battery optimization is already disabled
    bool? isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;

    if (isBatteryOptimizationDisabled!) {
      // Show dialog to disable battery optimization
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    }

    // Also check for manufacturer-specific optimizations (Xiaomi, OnePlus, etc.)
    bool? isManufacturerOptimizationDisabled = await DisableBatteryOptimization
        .isManufacturerBatteryOptimizationDisabled;

    if (isManufacturerOptimizationDisabled!) {
      await DisableBatteryOptimization
          .showDisableManufacturerBatteryOptimizationSettings(
              "Additional Battery Optimization Detected",
              "Please disable battery optimization for reliable medicine reminders");
    }
  }

  // Add a method to check if all optimizations are disabled
  static Future<bool?> areAllOptimizationsDisabled() async {
    return await DisableBatteryOptimization.isAllBatteryOptimizationDisabled;
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Backup notification tapped: ${response.payload}');
    if (response.payload != null) {
      final alarmId = int.tryParse(response.payload!);
      if (alarmId != null) {
        // Handle notification actions here
        if (response.actionId?.startsWith('snooze_') == true) {
          _handleSnoozeAction(alarmId);
        } else if (response.actionId?.startsWith('dismiss_') == true) {
          _handleDismissAction(alarmId);
        }
      }
    }
  }

  static Future<void> _handleSnoozeAction(int alarmId) async {
    print('Snoozing backup alarm $alarmId');
    await _notifications.cancel(alarmId + 20000); // Cancel backup notification
    // Reschedule backup for 5 minutes
    await _scheduleBackupSnooze(alarmId);
  }

  static Future<void> _handleDismissAction(int alarmId) async {
    print('Dismissing backup alarm $alarmId');
    await cancelAlarm(alarmId);
  }

  static Future<void> _scheduleBackupSnooze(int alarmId) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Backup Alarms',
      channelDescription: 'Backup snooze alarm',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public, // ADD THIS LINE
      sound:
          UriAndroidNotificationSound('content://settings/system/alarm_alert'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
      actions: [
        AndroidNotificationAction('dismiss_$alarmId', '✅ Stop'),
      ],
    );

    await _notifications.zonedSchedule(
      alarmId + 30000, // Snooze ID
      '😴 BACKUP ALARM (Snoozed)',
      'Main alarm may not be working - Tap to dismiss',
      tz.TZDateTime.from(snoozeTime, tz.local),
      NotificationDetails(android: androidDetails),
      payload: alarmId.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // MAIN BACKUP NOTIFICATION SCHEDULER
  static Future<void> scheduleBackupAlarm(AlarmModel alarm) async {
    final now = DateTime.now();
    DateTime nextAlarm =
        DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

    if (nextAlarm.isBefore(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Backup Alarms',
      channelDescription: 'Backup alarm when main app fails',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public, // ADD THIS LINE
      sound:
          UriAndroidNotificationSound('content://settings/system/alarm_alert'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
      actions: [
        AndroidNotificationAction(
          'snooze_${alarm.id}',
          '😴 Snooze 5min',
          contextual: true,
        ),
        AndroidNotificationAction(
          'dismiss_${alarm.id}',
          '✅ Dismiss',
          contextual: true,
        ),
      ],
    );

    await _notifications.zonedSchedule(
      alarm.id + 20000, // Different ID for backup
      '⚠️ BACKUP ALARM',
      '${alarm.title} - Main alarm may not be working!',
      tz.TZDateTime.from(nextAlarm, tz.local),
      NotificationDetails(android: androidDetails),
      payload: alarm.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('✅ Backup notification scheduled for: $nextAlarm');
  }

  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id + 20000); // Cancel backup
    await _notifications.cancel(id + 30000); // Cancel snooze
  }
}
