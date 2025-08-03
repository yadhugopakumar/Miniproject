import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/medicine.dart';

class Calendarpage extends StatefulWidget {
  const Calendarpage({super.key});

  @override
  State<Calendarpage> createState() => _CalendarpageState();
}

class _CalendarpageState extends State<Calendarpage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> expiryDates = {};

  @override
  void initState() {
    super.initState();
    _initializeExpiryDates();
  }

  void _initializeExpiryDates() {
    final medicineBox = Hive.isBoxOpen('medicinesBox')
        ? Hive.box<Medicine>('medicinesBox')
        : null;
    if (medicineBox != null) {
      expiryDates = medicineBox.values
          .map((med) =>
              DateTime(med.expiryDate.year, med.expiryDate.month, med.expiryDate.day))
          .toSet();
    }
  }

  List<Map<String, String>> _getMedicinesForDay(DateTime day) {
    final historyBox = Hive.isBoxOpen('historyBox')
        ? Hive.box<HistoryEntry>('historyBox')
        : null;
    if (historyBox == null) {
      return [];
    }
    final selectedDate = DateTime(day.year, day.month, day.day);

    return historyBox.values
        .where((entry) =>
            entry.date.year == selectedDate.year &&
            entry.date.month == selectedDate.month &&
            entry.date.day == selectedDate.day)
        .map((entry) => {
              'name': entry.medicineName,
              'status': entry.status,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Medicine>('medicinesBox').listenable(),
      builder: (context, Box<Medicine> medicineBox, _) {
        // Keep expiryDates updated live
        expiryDates = medicineBox.values
            .map((med) => DateTime(med.expiryDate.year, med.expiryDate.month, med.expiryDate.day))
            .toSet();


        return Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Calendar View',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green[700],
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final isExpiredDate = expiryDates.contains(DateTime(day.year, day.month, day.day));
                      if (isExpiredDate) {
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Medicines on ${(_selectedDay ?? _focusedDay).toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable: Hive.box<HistoryEntry>('historyBox').listenable(),
                  builder: (context, Box<HistoryEntry> historyBox, _) {
                    final meds = _selectedDay != null
                        ? _getMedicinesForDay(_selectedDay!)
                        : _getMedicinesForDay(_focusedDay);

                    if (meds.isEmpty) {
                      return const Text(
                        "No medicine history found for this day.",
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Column(
                      children: meds.map((med) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.medical_services, color: Colors.teal),
                            title: Text(
                              med['name']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: med['status'] == 'taken'
                                    ? const Color.fromARGB(255, 121, 255, 125)
                                    : const Color.fromARGB(255, 255, 128, 69),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                med['status']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
