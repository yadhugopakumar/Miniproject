import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Hivemodel/alarm_model.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
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

    if (!vibrationEnabled) {
      debugPrint("Vibration is disabled by user");
      return;
    }

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
        pattern: [500, 1000, 500, 1000],
        repeat: 0,
      );
    }
  }

  Future<void> _stopAlarmAndVibration() async {
    await Vibration.cancel();
    await Alarm.stop(widget.alarm.id);
    await Alarm.stop(widget.alarm.id + 10000);
    await _player.stop();
  }


  Future<void> _handleSnooze() async {
    await _stopAlarmAndVibration();

    final historyBox = Hive.box<HistoryEntry>('historyBox');
    historyBox.add(
      HistoryEntry(
        date: DateTime.now(),
        medicineName: widget.alarm.medicineName,
        status: "taken Late",
        time: TimeOfDay.now().format(context),
      ),
    );

    await AlarmService.snoozeAlarm(widget.alarm);
    if (mounted) {
      Navigator.pop(context);
      
    }
  }

  Future<void> _handleTaken() async {
    await _stopAlarmAndVibration();

    final historyBox = Hive.box<HistoryEntry>('historyBox');
    final medicineBox = Hive.box<Medicine>('medicinesBox');

    // Save to history
    historyBox.add(
      HistoryEntry(
        date: DateTime.now(),
        medicineName: widget.alarm.medicineName,
        status: "taken",
        time: TimeOfDay.now().format(context),
      ),
    );

    // Reduce stock
    final medicine = medicineBox.values.firstWhere(
      (m) => m.name == widget.alarm.medicineName,
    );
    medicine.quantityLeft = (medicine.quantityLeft - 1).clamp(0, 9999);
    medicine.save();

    await AlarmService.dismissAlarm(widget.alarm);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great! Medication taken successfully')),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    Vibration.cancel();
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
                          Text("Dosage:"+widget.alarm.dosage,style: TextStyle(fontSize: 15),),
                          const SizedBox(height: 4),
                          Text(widget.alarm.description,style: TextStyle(fontSize: 15),),
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


