import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../services/hive_services.dart';
import '../services/fetch_and_store_medicine.dart';
import '../../Hivemodel/user_settings.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  Future<void> _initHistory() async {
    _populateMissedEntries();
    await syncHistoryToSupabase();
    if (!mounted) return;

    setState(() {}); // refresh UI safely
  }

  Future<void> syncHistoryToSupabase() async {
    final supabase = Supabase.instance.client;
    final historyBox = Hive.box<HistoryEntry>('historyBox');

    final entriesToSync = historyBox.values.toList();
    if (entriesToSync.isEmpty) return;

    for (var entry in entriesToSync) {
      try {
        // New or status changed entry
        if (entry.remoteId == null || entry.statusChanged) {
          await supabase.from('history_entry').upsert({
            'child_id': entry.childId,
            'medicine_id': entry.medicineId,
            'medicine_name': entry.medicineName,
            'date': entry.date.toIso8601String(),
            'time': entry.time,
            'status': entry.status,
          }, onConflict: 'medicine_id,date,time') // uses unique constraint
              .select();

          // Reset Hive flag
          entry.statusChanged = false;
          await entry.save();

          print('✅ Entry synced/upserted: ${entry.medicineName}');
        }
      } catch (e) {
        print('❌ Error syncing entry ${entry.medicineName}: $e');
      }
    }
  }

  void _populateMissedEntries() {
    final history = Hive.box<HistoryEntry>(historyBox);
    final medicines = Hive.box<Medicine>(medicinesBox);
    final userBox = Hive.box<UserSettings>('settingsBox');
    final userSettings = userBox.get('user');
    if (userSettings == null) return;
    final childId = userSettings.childId;

    final now = DateTime.now();
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    for (var med in medicines.values) {
      final medId = med.id;

      for (var time in med.dailyIntakeTimes) {
        final doseKey = buildDoseKey(medId, now, time, childId);

        // only mark as missed if time has passed and entry doesn’t already exist
        if (!history.containsKey(doseKey) && time.compareTo(currentTime) < 0) {
          history.put(
            doseKey,
            HistoryEntry(
              date: now,
              medicineName: med.name, // plain name only
              time: time,
              status: 'missed',
              medicineId: med.id,
              childId: childId, // set childId consistently
              remoteId: null,
            ),
          );
        }
      }
    }
  }

  bool _filterEntry(HistoryEntry entry) {
    switch (selectedFilter) {
      case 'Taken':
        return entry.status == 'taken';
      case 'Late Taken':
        return entry.status == 'takenLate';
      case 'Missed':
        return entry.status == 'missed';
      default:
        return true; // All
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History Log',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Taken', 'Late Taken', 'Missed'].map((filter) {
                final bool isSelected = selectedFilter == filter;
                return ElevatedButton(
                  onPressed: () {
                    setState(() => selectedFilter = filter);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.green[700] : Colors.grey[300],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                  ),
                  child: Text(filter),
                );
              }).toList(),
            ),
          ),

          // History List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<HistoryEntry>(historyBox).listenable(),
              builder: (context, Box<HistoryEntry> box, _) {
                // Group entries by date
                Map<String, List<HistoryEntry>> grouped = {};
                for (var entry in box.values) {
                  final dateStr =
                      "${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}";
                  grouped.putIfAbsent(dateStr, () => []).add(entry);
                }

                // Sort dates descending
                final sortedDates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                if (sortedDates.isEmpty) {
                  return const Center(child: Text("No history yet."));
                }

                return ListView(
                  children: sortedDates.map((date) {
                    // Filter by status
                    final meds = grouped[date]!.where(_filterEntry).toList();

                    if (meds.isEmpty) return const SizedBox();

                    // Sort by time ascending
                    meds.sort((a, b) {
                      String timeA = a.medicineName.contains('@')
                          ? a.medicineName.split('@')[1]
                          : '00:00';
                      String timeB = b.medicineName.contains('@')
                          ? b.medicineName.split('@')[1]
                          : '00:00';
                      return timeA.compareTo(timeB);
                    });

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date: $date",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Divider(),
                              ...meds.map((entry) {
                                final medName =
                                    entry.medicineName; // just the name
                                final timeStr =
                                    entry.time; // use the stored time directly

                                // Format time
                                String formattedTime = '';
                                if (timeStr != null && timeStr.isNotEmpty) {
                                  final parts = timeStr.split(':');
                                  if (parts.length == 2) {
                                    final hour = int.tryParse(parts[0]) ?? 0;
                                    final minute = int.tryParse(parts[1]) ?? 0;
                                    final dt = DateTime(0, 0, 0, hour, minute);
                                    formattedTime = DateFormat.jm()
                                        .format(dt); // e.g., 8:30 AM
                                  }
                                }

                                Color statusColor;
                                String statusText;
                                switch (entry.status) {
                                  case 'taken':
                                    statusColor = Colors.green;
                                    statusText = 'Taken';
                                    break;
                                  case 'takenLate':
                                    statusColor = Colors.orange;
                                    statusText = 'Late Taken';
                                    break;
                                  case 'missed':
                                  default:
                                    statusColor = Colors.red;
                                    statusText = 'Missed';
                                }

                                return ListTile(
                                  leading: Icon(Icons.medication,
                                      color: statusColor),
                                  title: Text(medName),
                                  subtitle: formattedTime.isNotEmpty
                                      ? Text("Time: $formattedTime")
                                      : null,
                                  trailing: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
