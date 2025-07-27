import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> staticHistory = [
    {
      "date": "2025-07-27",
      "entries": [
        {"medicineName": "Paracetamol", "time": "09:00 AM", "status": "taken"},
        {"medicineName": "Amoxicillin", "time": "01:00 PM", "status": "missed"},
      ]
    },
    {
      "date": "2025-07-26",
      "entries": [
        {"medicineName": "Cetirizine", "time": "08:00 AM", "status": "taken"},
      ]
    }
  ];

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
          Expanded(
            child: ListView(
              children: staticHistory.map((day) {
                final date = day["date"];
                final entries = (day["entries"] as List<Map<String, dynamic>>)
                    .where((entry) {
                  if (selectedFilter == 'All') return true;
                  if (selectedFilter == 'Taken') return entry['status'] == 'taken';
                  if (selectedFilter == 'Missed') return entry['status'] != 'taken';
                  return false;
                }).toList();

                if (entries.isEmpty) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          ...entries.map((entry) {
                            return ListTile(
                              leading: Icon(Icons.medication,
                                  color: entry['status'] == 'taken'
                                      ? Colors.green
                                      : Colors.red),
                              title: Text(entry['medicineName']),
                              subtitle: entry['time'] != null
                                  ? Text("Time: ${entry['time']}")
                                  : null,
                              trailing: Text(
                                  entry['status'] == 'taken' ? 'Taken' : 'Missed',
                                  style: TextStyle(
                                      color: entry['status'] == 'taken'
                                          ? Colors.green
                                          : Colors.red)),
                            );
                          })
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
