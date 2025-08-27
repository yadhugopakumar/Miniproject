import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'models/alarm_model.dart';
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
  final _ringtone = FlutterRingtonePlayer();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    // ✅ Start vibration
    _startVibration();

    // ✅ Start sound manually
    _startRingtone();
  }

  Future<void> _startRingtone() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // read saved sound from prefs (fallback to alarm1.mp3 if none)
      final selected = prefs.getString("selectedSound") ?? "alarm1.mp3";

      await _ringtone.play(
        fromAsset: "assets/sounds/$selected",
        looping: true,
        asAlarm: true,
      );
    } catch (e) {
      debugPrint("Error starting ringtone: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    Vibration.cancel(); // make sure vibration stops if screen disposed
    super.dispose();
  }

  // Future<void> _startVibration() async {
  //   if (await Vibration.hasVibrator() ?? false) {
  //     Vibration.vibrate(
  //       pattern: [500, 1000, 500, 1000],
  //       repeat: 0, // loop indefinitely until cancel
  //     );
  //   }
  // }
  Future<void> _startVibration() async {
    final prefs = await SharedPreferences.getInstance();
    final vibrationEnabled = prefs.getBool("vibrationEnabled") ?? true;

    if (!vibrationEnabled) {
      debugPrint("Vibration is disabled by user");
      return;
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [500, 1000, 500, 1000],
        repeat: 0, // loop indefinitely until cancel
      );
    }
  }

  Future<void> _stopAlarmAndVibration() async {
    await Vibration.cancel();
    await Alarm.stop(widget.alarm.id);
    await Alarm.stop(widget.alarm.id + 10000);

    try {
      await _ringtone.stop(); // ✅ static call
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  Future<void> _handleSnooze() async {
    await _stopAlarmAndVibration();
    await AlarmService.snoozeAlarm(widget.alarm);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Snoozed for 5 minutes'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleTaken() async {
    await _stopAlarmAndVibration();
    await AlarmService.dismissAlarm(widget.alarm);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Great! Medication taken successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // NEW: Force stop any background audio
  Future<void> _forceStopAudio() async {
    try {
      await _ringtone.stop();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.red.shade100,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing medication icon
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
                            widget.alarm.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.alarm.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleSnooze,
                          icon: const Icon(Icons.schedule),
                          label: const Text('SNOOZE\n5 MIN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleTaken,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('TAKEN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
