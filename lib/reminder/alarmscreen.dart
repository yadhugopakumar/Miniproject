import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medremind/reminder/vibrationcontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Hivemodel/alarm_model.dart';
import '../Hivemodel/medicine.dart';
import '../utils/customsnackbar.dart';
import 'services/alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;
  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _startVibration();
    _startRingtone();
  }

  Future<void> _startRingtone() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final selected = prefs.getString("selectedSound") ?? "alarm1.mp3";

      await _player.setReleaseMode(ReleaseMode.loop); // loop until stopped
      await _player.play(
        AssetSource("sounds/$selected"),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Error starting ringtone: $e");
    }
  }

  Future<void> _startVibration() async {
    final prefs = await SharedPreferences.getInstance();
    final vibrationEnabled = prefs.getBool("vibrationEnabled") ?? true;
    if (!vibrationEnabled) return;

    await VibrationController.startVibration();
  }

  Future<void> _stopAlarmAndVibration() async {
    await VibrationController.stopVibration();
    await Alarm.stop(widget.alarm.id);
    if (widget.alarm.snoozeId != null) {
      await Alarm.stop(widget.alarm.snoozeId!);
    }
  }

  Future<void> _handleSnooze() async {
    await _stopAlarmAndVibration();

    final alarm = widget.alarm;

    // Call service to snooze
    await AlarmService.snoozeAlarm(alarm);

    if (mounted) {
      Navigator.pop(context);
    
       AppSnackbar.show(context,
          message: "Alarm snoozed for 5 minutes", success: true);
    }
  }

  Future<void> _handleTaken() async {
    await _stopAlarmAndVibration();

    final alarm = widget.alarm;
    final medicineBox = Hive.box<Medicine>('medicinesBox');

    // Tell service to dismiss the alarm and update history
    await AlarmService.dismissAlarm(alarm);

    // Reduce medicine stock (safe lookup)
    Medicine? medicine;
    try {
      medicine =
          medicineBox.values.firstWhere((m) => m.name == alarm.medicineName);
    } catch (e) {
      medicine = null;
    }

    if (medicine != null) {
      // medicine.quantityLeft = (medicine.quantityLeft - 1).clamp(0, 9999);
      int dosageCount = int.tryParse(medicine.dosage) ?? 1;
      // Decrease stock based on dosage
      medicine.quantityLeft = (medicine.quantityLeft - dosageCount)
          .clamp(0, medicine.totalQuantity);
      await medicine.save();
    }

    if (mounted) {
      Navigator.pop(context);

      // The service marked history as "taken" or "takenLate" internally.
      // If you want to show late message, read history or keep logic in the service.
      AppSnackbar.show(context,
          message: "Medication taken successfully", success: true);
    }
  }

  Future<void> _handleMissed() async {
    await _stopAlarmAndVibration();

    final alarm = widget.alarm;
    final time =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';

    // Mark missed in history
    await HistoryService.updateHistoryStatus(alarm.medicineName, time, "missed");

    // Update alarm model state for UI
    alarm.lastAction = 'missed';
    alarm.lastActionTime = DateTime.now();
    await AlarmService.box.put(alarm.id, alarm);

    // Stop alarms
    await Alarm.stop(alarm.id);
    if (alarm.snoozeId != null) {
      await Alarm.stop(alarm.snoozeId!);
      alarm.snoozeId = null;
      await AlarmService.box.put(alarm.id, alarm);
    }

    if (mounted) {
      Navigator.pop(context);

      AppSnackbar.show(context,
          message: "Dose marked as missed", success: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.dispose(); // release resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 197, 255, 219),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_pulseController.value * 0.4),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medication,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'MEDICATION TIME!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            widget.alarm.medicineName,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Dosage:" + widget.alarm.dosage,
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.alarm.description,
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Row(
                        children: [
                          // Snooze button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleSnooze,
                              icon: const Icon(Icons.schedule),
                              label: const Text('SNOOZE\n5 MIN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Taken button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleTaken,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('TAKEN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Missed / Can't Take button below
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleMissed,
                          icon: const Icon(Icons.close),
                          label: const Text("CAN'T TAKE TODAY"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
