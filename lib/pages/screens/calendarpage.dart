import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';


class Calendarpage extends StatefulWidget {
  const Calendarpage({super.key});

  @override
  State<Calendarpage> createState() => _CalendarpageState();
}

class _CalendarpageState extends State<Calendarpage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
// Dummy medicine data map by date
final Map<String, List<Map<String, String>>> dummyHistory = {
  '2025-07-27': [
    {'name': 'Paracetamol', 'status': 'taken'},
    {'name': 'Vitamin C', 'status': 'missed'},
  ],
  '2025-07-28': [
    {'name': 'Ibuprofen', 'status': 'taken'},
  ],
};

List<Map<String, String>> _getMedicinesForDay(DateTime day) {
  final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
  return dummyHistory[key] ?? [];
}

  @override
  Widget build(BuildContext context) {
    final selectedMeds = _selectedDay != null
        ? _getMedicinesForDay(_selectedDay!)
        : _getMedicinesForDay(_focusedDay);

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
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
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
              "Medicines on ${_selectedDay?.toLocal().toString().split(' ')[0] ?? 'Today'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...selectedMeds.map(
              (med) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: Colors.amber,
                  ),
                  title: Text(med['name']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  trailing: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement edit action
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: med['status'] == 'taken'
                          ? const Color.fromARGB(255, 121, 255, 125)
                          : Color.fromARGB(255, 255, 128, 69),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(med['status']!), // ✅ Status displayed
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}