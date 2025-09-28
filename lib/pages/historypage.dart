import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../services/hive_services.dart';
import '../services/fetch_and_store_medicine.dart';

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
    _populateMissedEntries();
    pushUnsyncedHistoryToSupabase();
  }

  // void _populateMissedEntries() {
  //   final history = Hive.box<HistoryEntry>(historyBox);
  //   final medicines = Hive.box<Medicine>(medicinesBox);
  //
  //   final now = DateTime.now();
  //   final todayKey = "${now.year}-${now.month}-${now.day}";
  //   final currentTime =
  //       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  //
  //   for (var med in medicines.values) {
  //     for (var time in med.dailyIntakeTimes) {
  //       final doseKey = "${med.name}@${time}_$todayKey";
  //
  //       if (!history.containsKey(doseKey) && time.compareTo(currentTime) < 0) {
  //         history.put(
  //           doseKey,
  //           HistoryEntry(
  //             // medicineId: med.id,
  //             date: now,
  //             medicineName: "${med.name}@$time",
  //             status: 'missed',
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }
  void _populateMissedEntries() {
    final history = Hive.box<HistoryEntry>(historyBox);
    final medicines = Hive.box<Medicine>(medicinesBox);

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now); // zero-padded date
    final currentTime =
    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  for (var med in medicines.values) {
    final medId = med.id ?? med.name; // fallback if no ID

    for (var time in med.dailyIntakeTimes) {
      final doseKey = "${medId}_${todayKey}_$time";

      // only mark as missed if time has passed and entry doesn’t already exist
      if (!history.containsKey(doseKey) && time.compareTo(currentTime) < 0) {
        history.put(
          doseKey,
          HistoryEntry(
            date: now,
            medicineName: med.name, // ✅ plain name only
            time: time,             // ✅ store time separately
            status: 'missed',
            medicineId: med.id,
            childId: null, // set if you have user/child context
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
                                String medName = entry.medicineName;
                                String timeStr = '';
                                if (medName.contains('@')) {
                                  final parts = medName.split('@');
                                  medName = parts[0];
                                  timeStr = parts.length > 1 ? parts[1] : '';
                                }

                                // Format time
                                String formattedTime = '';
                                if (timeStr.isNotEmpty) {
                                  final parts = timeStr.split(':');
                                  if (parts.length == 2) {
                                    final hour = int.tryParse(parts[0]) ?? 0;
                                    final minute = int.tryParse(parts[1]) ?? 0;
                                    final dt = DateTime(0, 0, 0, hour, minute);
                                    formattedTime =
                                        "${DateFormat.jm().format(dt)}"; // e.g., 8:30 AM
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
