import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/pages/screens/pdfviewerpage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../Hivemodel/history_entry.dart';
import '../../Hivemodel/medicine.dart';
import '../../utils/generatereport.dart';

class Calendarpage extends StatefulWidget {
  const Calendarpage({super.key});

  @override
  State<Calendarpage> createState() => _CalendarpageState();
}

class _CalendarpageState extends State<Calendarpage> {
  bool _isExporting = false; // loading flag

  CalendarFormat _calendarFormat = CalendarFormat.month;

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
          .map((med) => DateTime(
              med.expiryDate.year, med.expiryDate.month, med.expiryDate.day))
          .toSet();
    }
  }

  // List<Map<String, String>> _getMedicinesForDay(DateTime day) {
  //   final historyBox = Hive.isBoxOpen('historyBox')
  //       ? Hive.box<HistoryEntry>('historyBox')
  //       : null;
  //   if (historyBox == null) {
  //     return [];
  //   }
  //   final selectedDate = DateTime(day.year, day.month, day.day);

  //   return historyBox.values
  //       .where((entry) =>
  //           entry.date.year == selectedDate.year &&
  //           entry.date.month == selectedDate.month &&
  //           entry.date.day == selectedDate.day)
  //       .map((entry) => {
  //             'name': entry.medicineName,
  //             'status': entry.status,
  //           })
  //       .toList();
  // }
  List<Map<String, dynamic>> _getMedicinesForDay(DateTime day) {
    final historyBox = Hive.isBoxOpen('historyBox')
        ? Hive.box<HistoryEntry>('historyBox')
        : null;
    if (historyBox == null) return [];

    final selectedDate = DateTime(day.year, day.month, day.day);

    return historyBox.values
        .where((entry) =>
            entry.date.year == selectedDate.year &&
            entry.date.month == selectedDate.month &&
            entry.date.day == selectedDate.day)
        .map((entry) => {
              'name': entry.medicineName,
              'status': entry.status,
              'time':
                  DateFormat('hh:mm a').format(entry.date), // formatted time
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
            .map((med) => DateTime(
                med.expiryDate.year, med.expiryDate.month, med.expiryDate.day))
            .toSet();

        return Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Calendar View',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green[700],
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ElevatedButton(
                        onPressed: _isExporting
                            ? null // disable button while exporting
                            : () async {
                                setState(
                                    () => _isExporting = true); // start loading

                                try {
                                  final file = await generateMonthlyReportPdf(
                                      selectedMonth: _focusedDay);
                                  if (file != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PdfViewPage(filePath: file.path),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() =>
                                      _isExporting = false); // stop loading
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 58, 104, 79),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3.0, horizontal: 20),
                          child: _isExporting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text("Generating...",
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.file_download,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text("Export this month History"),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // Check if it's an expiry date
                    final selectedDate = DateTime(
                        selectedDay.year, selectedDay.month, selectedDay.day);

                    if (expiryDates.contains(selectedDate)) {
                      final medicineBox = Hive.box<Medicine>('medicinesBox');
                      final expiringMeds = medicineBox.values
                          .where((med) =>
                              med.expiryDate.year == selectedDate.year &&
                              med.expiryDate.month == selectedDate.month &&
                              med.expiryDate.day == selectedDate.day)
                          .toList();

                      // Show a dialog with the details
                      if (expiringMeds.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 233, 251, 255),
                            title: Text(
                                "Medicines Expiring on - (${selectedDate.toLocal().toString().split(' ')[0]} )",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 66, 4, 0))),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: expiringMeds.map(
                                (med) {
                                  return Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey, width: 0.8),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Icons.warning,
                                          color: Colors.red),
                                      title: Text(med.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Dosage: ${med.dosage} pill(s)",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Remaining: ${med.quantityLeft} only",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final isExpiredDate = expiryDates
                          .contains(DateTime(day.year, day.month, day.day));
                      if (isExpiredDate) {
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable:
                      Hive.box<HistoryEntry>('historyBox').listenable(),
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
                            leading: const Icon(Icons.medical_services,
                                color: Colors.teal),
                            title: Text(
                              med['name']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            subtitle: med.containsKey('time')
                                ? Text(
                                    "Time: ${med['time']!}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  )
                                : null,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: med['status']!.toLowerCase() == 'taken'
                                    ? const Color.fromARGB(255, 121, 255, 125)
                                    : const Color.fromARGB(255, 255, 128, 69),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                med['status']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
