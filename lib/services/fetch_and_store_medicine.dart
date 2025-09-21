import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Hivemodel/health_report.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';
import 'hive_services.dart';

String convertTo24Hour(String amPmTime) {
  final parsed = DateFormat("hh:mm a").parse(amPmTime);
  return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

String convertTo24HourSafe(String time) {
  time = time.trim();
  if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
    final parsed = DateFormat("hh:mm a").parse(time);
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
  // Already in 24-hour format
  return time;
}

// Future<void> fetchAndStoreTodaysMedicines() async {
//   final supabase = Supabase.instance.client;
//   final medicinesBox = Hive.box<Medicine>('medicinesBox');
//   final userBox = Hive.box<UserSettings>('settingsBox');
//     final historyBox = Hive.box<HistoryEntry>('historyBox');
//   final userSettings =
//       userBox.get('user'); // 'user' is the key you saved it with

//   if (userSettings == null) {
//     print("No user found in Hive.");
//     return;
//   }

//   final childId = userSettings.childId; // <-- String, UUID
//   // final today = DateTime.now().toIso8601String().substring(0, 10);

//   final response =
//       await supabase.from('medicine').select().eq('child_id', childId);

//   if (response.isEmpty) {
//     print("No medicines for today.");
//     return;
//   }

//   // Clear old data so only today’s meds show
//   await medicinesBox.clear();

//   for (var med in response) {
//     // Convert all times to "HH:mm" before storing
//     final convertedTimes = (med['daily_intake_times'] as List)
//         .map((t) => convertTo24HourSafe(t))
//         .toList();

//     final medicine = Medicine(
//       id: med['id'], // Assuming 'id' is the Supabase medicine ID
//       name: med['name'],
//       dosage: med['dosage'],
//       expiryDate: DateTime.parse(med['expiry_date']),
//       dailyIntakeTimes: convertedTimes,
//       totalQuantity: med['total_quantity'],
//       quantityLeft: med['quantity_left'],
//       refillThreshold: med['refill_threshold'],
//     );

//     await medicinesBox.add(medicine);
//   }

//   print("Today's medicines fetched & stored in Hive.");
// }

// Future<void> syncHealthReportsToHive(String childId) async {
// final hiveBox = Hive.box<HealthReport>('healthReportsBox');
//   final supabase = Supabase.instance.client;
//   if (hiveBox.isNotEmpty) {
//     return; // Already cached
//   }

//   final response = await supabase
//       .from('health_reports')
//       .select()
//       .eq('child_id', childId)
//       .order('report_date', ascending: false);

//   if (response == []  && response.isNotEmpty) {
//     for (var row in response) {
//       final report = HealthReport(
//         childId: row['child_id'],
//         reportDate: DateTime.parse(row['report_date']),
//         systolic: row['report_type'] == 'systolic'
//             ? row['value'] ?? 0
//             : 0,
//         diastolic: row['report_type'] == 'diastolic'
//             ? row['value'] ?? 0
//             : 0,
//         cholesterol: row['report_type'] == 'cholesterol'
//             ? row['value'] ?? 0
//             : 0,
//         notes: row['notes'] ?? '',
//         id: row['id'],
//       );
//       await hiveBox.add(report);
//     }
//   } else {
//     print("⚠️ No health reports found for child: $childId");
//   }

// // 2️⃣ Push local history entries to Supabase
//   if (historyBox.isNotEmpty) {
//     for (var entry in historyBox.values) {
//       // Find medicine ID
//       final localMed = medicinesBox.values.firstWhere(
//         (med) => entry.medicineName.contains(med.name),
//         orElse: () => null,
//       );

//       if (localMed == null) continue;

//       // Extract time
//       String? timeStr;
//       if (entry.medicineName.contains('@')) {
//         timeStr = entry.medicineName.split('@')[1];
//       }

//       try {
//         final result = await supabase.from('history_entry').insert({
//           'medicine_id': localMed.id,
//           'date': entry.date.toIso8601String().substring(0, 10),
//           'status': entry.status,
//           'time': timeStr,
//         }).execute();

//         if (result.error != null) {
//           print("Failed to push history: ${result.error!.message}");
//         }
//       } catch (e) {
//         print("Error pushing history: $e");
//       }
//     }
//     print("All local history pushed to Supabase.");
//   }

// }
Future<void> fetchAndStoreTodaysMedicines() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final userBox = Hive.box<UserSettings>('settingsBox');

  final userSettings = userBox.get('user');
  if (userSettings == null) return;

  final childId = userSettings.childId;

  // Fetch medicines
  final response =
      await supabase.from('medicine').select().eq('child_id', childId);

  if (response.isEmpty) return;

  await medicinesBox.clear();

  for (var med in response) {
    final convertedTimes = (med['daily_intake_times'] as List)
        .map((t) => convertTo24HourSafe(t))
        .toList();

    final medicine = Medicine(
      id: med['id'],
      name: med['name'],
      dosage: med['dosage'],
      expiryDate: DateTime.parse(med['expiry_date']),
      dailyIntakeTimes: convertedTimes,
      totalQuantity: med['total_quantity'],
      quantityLeft: med['quantity_left'],
      refillThreshold: med['refill_threshold'],
    );

    await medicinesBox.add(medicine);
  }

  print("Today's medicines fetched & stored in Hive.");

  // Push history entries
  if (historyBox.isNotEmpty) {
    List<Map<String, dynamic>> batch = [];

    for (var entry in historyBox.values) {
      final localMed = medicinesBox.values.cast<Medicine?>().firstWhere(
          (med) => med != null && entry.medicineName.contains(med.name),
          orElse: () => null);

      if (localMed == null) continue;

      String? timeStr;
      if (entry.medicineName.contains('@')) {
        timeStr = entry.medicineName.split('@')[1];
      }

      batch.add({
        'medicine_id': localMed.id,
        'date': entry.date.toIso8601String().substring(0, 10),
        'status': entry.status,
        'time': timeStr,
      });
    }

    if (batch.isNotEmpty) {
      try {
        await supabase.from('history_entry').insert(batch);
        print("All local history pushed to Supabase.");
      } catch (e, stackTrace) {
        print("Error pushing history: $e");
        print(stackTrace);
      }
    }
  }
}
