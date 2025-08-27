import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reminder/services/alarm_service.dart';
import 'addalarm.dart';
import 'alarmscreen.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/alarm_model.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _player = AudioPlayer();
  List<AlarmModel> alarms = [];
  late StreamSubscription<AlarmSettings> _alarmSubscription;
  final List<String> availableSounds = [
    "alarm1.mp3",
    "alarm2.mp3",
    "alarm3.mp3",
  ];
  String? _selectedSound;
  @override
  void initState() {
    super.initState();

    getSelectedSound().then((value) {
      setState(() => _selectedSound = value);
    });
    _requestPermissions();
    _loadAlarms();

    // Listen for alarm rings (this replaces complex isolate setup)
    _alarmSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      _onAlarmRing(alarmSettings);
    });
  }

  @override
  void dispose() {
    _alarmSubscription.cancel();
    super.dispose();
  }

  Future<void> saveSelectedSound(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedSound", path);
  }

  Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("selectedSound") ?? availableSounds.first;
  }

  // Simple alarm ring handler
  void _onAlarmRing(AlarmSettings alarmSettings) {
    final alarm = alarms.firstWhere(
      (a) => a.id == alarmSettings.id || a.id == alarmSettings.id - 10000,
      orElse: () => AlarmModel(
        id: alarmSettings.id,
        title: alarmSettings.notificationTitle,
        description: alarmSettings.notificationBody,
        hour: DateTime.now().hour,
        minute: DateTime.now().minute,
      ),
    );

    // Show alarm screen when alarm rings
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AlarmRingScreen(alarm: alarm),
            fullscreenDialog: true,
          ),
        )
        .then((_) => _loadAlarms());
  }

  void _loadAlarms() {
    setState(() {
      alarms = AlarmService.getAllAlarms();
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  void _showAddAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAlarmDialog(onAlarmAdded: _loadAlarms),
    );
  }

  bool _vibrationEnabled = true; // default

  void _chooseSound() async {
    String? sound = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selectedSound = _selectedSound;
        bool tempVibration = _vibrationEnabled;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Choose Notification Sound"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // List of sounds with preview on tap
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableSounds.length,
                  itemBuilder: (context, index) {
                    final soundFile = availableSounds[index];
                    return RadioListTile<String>(
                      title: Text(soundFile),
                      value: soundFile,
                      groupValue: selectedSound,
                      onChanged: (value) async {
                        setState(() => selectedSound = value);

                        // play preview
                        await _player.stop();
                        await _player.play(AssetSource("sounds/$soundFile"));
                        print("Playing $soundFile");
                      },
                    );
                  },
                ),
                const Divider(),
                // Vibration toggle
                SwitchListTile(
                  title: const Text("Vibration"),
                  secondary: const Icon(Icons.vibration),
                  value: tempVibration,
                  onChanged: (val) {
                    setState(() => tempVibration = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _player.stop();
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _vibrationEnabled = tempVibration;
                    _selectedSound = selectedSound;
                  });
                  saveSelectedSound(_selectedSound!);
                  saveVibrationPref(_vibrationEnabled);

                  _player.stop();
                  Navigator.pop(context, selectedSound);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Save vibration preference
  Future<void> saveVibrationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("vibrationEnabled", value);
  }

  /// Load vibration preference
  Future<bool> getVibrationPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("vibrationEnabled") ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Colors.white),
            SizedBox(width: 8),
            Text('MedRemind'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: _chooseSound,
          ),
        ],
      ),
      body: alarms.isEmpty ? _buildEmptyState() : _buildAlarmList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 100, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'No medication reminders set',
            style: TextStyle(
              fontSize: 18,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first reminder',
            style: TextStyle(fontSize: 14, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        final isTakenToday = alarm.isTakenToday;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: isTakenToday ? Colors.green.shade50 : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTakenToday
                  ? Colors.green.shade300
                  : (alarm.isActive ? Colors.green : Colors.grey),
              child: Icon(
                isTakenToday ? Icons.check : Icons.medication,
                color: Colors.white,
              ),
            ),
            title: Text(
              alarm.timeString,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: isTakenToday ? TextDecoration.lineThrough : null,
                color: isTakenToday ? Colors.green.shade700 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alarm.title),
                Text(
                  alarm.createdAt != null
                      ? 'Created on ${alarm.createdAt.day}/${alarm.createdAt.month}/${alarm.createdAt.year}'
                      : '',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
                // NEW: Status display
                Text(
                  alarm.statusText,
                  style: TextStyle(
                    color: isTakenToday
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NEW: History button
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  onPressed: () => _showAlarmHistory(alarm),
                ),
                Switch(
                  value: alarm.isActive,
                  onChanged: (_) async {
                    await AlarmService.toggleAlarm(alarm);
                    _loadAlarms();
                  },
                  activeColor: Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await AlarmService.deleteAlarm(alarm.id);
                    _loadAlarms();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// NEW: Show alarm history
  void _showAlarmHistory(AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${alarm.title} - History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: alarm.history.isEmpty
              ? const Center(child: Text('No history yet'))
              : ListView.builder(
                  itemCount: alarm.history.length,
                  itemBuilder: (context, index) {
                    final history =
                        alarm.history[alarm.history.length - 1 - index];
                    return ListTile(
                      leading: Icon(_getHistoryIcon(history.action)),
                      title: Text(_getHistoryTitle(history.action)),
                      subtitle: Text(
                        '${history.timestamp.day}/${history.timestamp.month}/${history.timestamp.year} at ${history.timestamp.hour.toString().padLeft(2, '0')}:${history.timestamp.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing:
                          history.note != null ? const Icon(Icons.note) : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getHistoryIcon(String action) {
    switch (action) {
      case 'triggered':
        return Icons.alarm;
      case 'snoozed':
        return Icons.schedule;
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getHistoryTitle(String action) {
    switch (action) {
      case 'triggered':
        return 'Alarm Triggered';
      case 'snoozed':
        return 'Snoozed';
      case 'taken':
        return 'Medication Taken';
      case 'missed':
        return 'Missed';
      default:
        return 'Unknown';
    }
  }
}
