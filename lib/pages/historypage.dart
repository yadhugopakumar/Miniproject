import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../services/hive_services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    _populateMissedEntries();
  }

  void _populateMissedEntries() {
    final history = Hive.box<HistoryEntry>(historyBox);
    final medicines = Hive.box<Medicine>(medicinesBox);

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    for (var med in medicines.values) {
      for (var time in med.dailyIntakeTimes) {
        final doseKey = "${med.name}@$time@$todayKey";

        // ✅ Only mark as missed if the dose time has already passed
        if (!history.containsKey(doseKey) && time.compareTo(currentTime) < 0) {
          history.put(
            doseKey,
            HistoryEntry(
              date: now,
              medicineName: "${med.name}@$time",
              status: 'missed',
            ),
          );
        }
      }
    }
  }

  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('History Log',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              children: ['All', 'Taken', 'Missed'].map((filter) {
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
                    final meds = grouped[date]!.where((entry) {
                      if (selectedFilter == 'All') return true;
                      if (selectedFilter == 'Taken')
                        return entry.status == 'taken';
                      if (selectedFilter == 'Missed')
                        return entry.status != 'taken';
                      return false;
                    }).toList();

                    if (meds.isEmpty) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Text(
                                  "Date: " + date,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              const Divider(),
                              ...meds.map((entry) {
                                // Split medicineName into name and time if needed
                                String medName = entry.medicineName;
                                String time = '';
                                if (medName.contains('@')) {
                                  final parts = medName.split('@');
                                  medName = parts[0];
                                  time = parts.length > 1 ? parts[1] : '';
                                }
                                return ListTile(
                                  leading: Icon(Icons.medication,
                                      color: entry.status == 'taken'
                                          ? Colors.green
                                          : Colors.red),
                                  title: Text(medName),
                                  subtitle: time.isNotEmpty
                                      ? Text("Time: $time")
                                      : null,
                                  trailing: Text(
                                      entry.status == 'taken'
                                          ? 'Taken'
                                          : 'Missed',
                                      style: TextStyle(
                                          color: entry.status == 'taken'
                                              ? Colors.green
                                              : Colors.red)),
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
          SizedBox(
            height: 50,
          )
        ],
      ),
    );
  }
}
