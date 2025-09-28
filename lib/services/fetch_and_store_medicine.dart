
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';
import 'package:collection/collection.dart'; // at top of file

String convertTo24HourSafe(String time) {
  time = time.trim();
  if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
    final parsed = DateFormat("hh:mm a").parse(time);
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
  return time; // already in 24-hour format
}

// Future<void> pushUnsyncedHistoryToSupabase() async {
//   final supabase = Supabase.instance.client;
//   final historyBox = Hive.box<HistoryEntry>('historyBox');
//   final medicinesBox = Hive.box<Medicine>('medicinesBox');
//
//   final today = DateTime.now();
//   final unsynced = historyBox.values.where((e) =>
//   e.remoteId == null &&
//   e.date.year == today.year &&
//   e.date.month == today.month &&
//   e.date.day == today.day
//   ).toList();
//
//   if (unsynced.isEmpty) {
//     print("No unsynced history found for today.");
//     return;
//   }
//   print("Medicines in Hive:");
//   for (var m in medicinesBox.values) {
//     print("${m.name} -> ${m.id}");
//   }
//
//   // Ensure medicineId is filled from medicinesBox
//   for (var entry in unsynced) {
//     if (entry.medicineId == null) {
//       final medicine = medicinesBox.values
//       .firstWhereOrNull((m) => m.name == entry.medicineName);
//
//       if (medicine != null) {
//         entry.medicineId = medicine.id;
//         await entry.save();
//       } else {
//         print(
//           "Skipping entry '${entry.medicineName}@${entry.time}' because medicineId is still null");
//       }
//     }
//   }
//
//   for (var entry in unsynced) {
//     if (entry.medicineId == null) {
//       final medicine = medicinesBox.values.firstWhereOrNull(
//         (m) => m.name.trim().toLowerCase() == entry.medicineName.trim().toLowerCase()
//                                            );
//       if (medicine != null) {
//         entry.medicineId = medicine.id;
//         await entry.save();
//         print("Linked ${entry.medicineName} -> ${medicine.id}");
//       } else {
//         print("Skipping entry '${entry.medicineName}@${entry.time}@${entry.date}' because medicine not found in Hive");
//       }
//     }
//   }
//
//   // Filter out any still-null entries
//   final readyToSync = unsynced.where((e) => e.medicineId != null).toList();
//   if (readyToSync.isEmpty) {
//     print("No history entries ready to sync after medicineId check.");
//     return;
//   }
//
//   final batch = readyToSync.map((e) => {
//     'medicine_id': e.medicineId,
//     'child_id': e.childId,
//     'medicine_name': e.medicineName,
//     'date': e.date.toIso8601String().substring(0, 10),
//     'status': e.status,
//     'time': e.time,
//   }).toList();
//
//   try {
//     final data = await supabase
//     .from('history_entry')
//     .upsert(batch, onConflict: 'history_unique')
//     .select(); // Returns the inserted/updated rows
//
//     print("Upsert response: $data");
//
//     // Update remoteId in Hive
//     for (var row in data) {
//       final medicineName = row['medicine_name'];
//       final time = row['time'];
//       final dateStr = row['date'];
//
//       final entry = readyToSync.firstWhere(
//         (e) =>
//         e.medicineName == medicineName &&
//         e.time == time &&
//         e.date.toIso8601String().substring(0, 10) == dateStr,
//       );
//
//         entry.remoteId = row['id']; // Supabase UUID
//         await entry.save();
//
//     }
//
//     print("✅ Today's local history synced to Supabase successfully.");
//   } catch (e, s) {
//     print("Exception syncing today's history: $e");
//     print(s);
//   }
// }
Future<void> pushUnsyncedHistoryToSupabase() async {
  final supabase = Supabase.instance.client;
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final medicinesBox = Hive.box<Medicine>('medicinesBox');

  final today = DateTime.now();
  final unsynced = historyBox.values.where((e) =>
  e.remoteId == null &&
  e.date.year == today.year &&
  e.date.month == today.month &&
  e.date.day == today.day).toList();

  if (unsynced.isEmpty) {
    print("No unsynced history found for today.");
    return;
  }

  print("Medicines in Hive:");
  for (var m in medicinesBox.values) {
    print("${m.name} -> ${m.id}");
  }

  // --- Ensure medicineId is linked properly ---
  for (var entry in unsynced) {
    if (entry.medicineId == null) {
      final medicine = medicinesBox.values.firstWhereOrNull(
        (m) => m.name.trim().toLowerCase() ==
        entry.medicineName.trim().toLowerCase());
      if (medicine != null) {
        entry.medicineId = medicine.id;
        await entry.save();
        print("Linked ${entry.medicineName} -> ${medicine.id}");
      } else {
        print("Skipping entry '${entry.medicineName}@${entry.time}' because medicine not found in Hive");
      }
    }
  }

  // --- Filter only entries ready for sync ---
  final readyToSync = unsynced.where((e) => e.medicineId != null).toList();
  if (readyToSync.isEmpty) {
    print("No history entries ready to sync after medicineId check.");
    return;
  }

  // --- Prepare batch for Supabase ---
  final batch = readyToSync.map((e) => {
    'medicine_id': e.medicineId,
    'child_id': e.childId,
    'medicine_name': e.medicineName,
    'date': e.date.toIso8601String().substring(0, 10),
    'status': e.status,
    'time': e.time,
  }).toList();

  try {
    final data = await supabase
    .from('history_entry')
    .upsert(batch, onConflict: 'history_unique')
    .select();

    print("Upsert response: $data");

    // --- Update remoteId + deduplicate in Hive ---
    for (var row in data) {
      final medId = row['medicine_id'];
      final dateStr = row['date'];
      final time = row['time'];

      final key = '${medId}_${dateStr}_$time';

      final entry = historyBox.get(key);
      if (entry != null) {
        entry.remoteId = row['id'];
        await entry.save();
      } else {
        // in case entry wasn't keyed yet, fix it
        final match = readyToSync.firstWhere(
          (e) =>
          e.medicineId == medId &&
          e.time == time &&
          e.date.toIso8601String().substring(0, 10) == dateStr,
        );
        match.remoteId = row['id'];
        await historyBox.put(key, match);
      }
    }

    print("✅ Today's local history synced to Supabase successfully.");
  } catch (e, s) {
    print("Exception syncing today's history: $e");
    print(s);
  }
}

Future<void> fetchAndStoreTodaysMedicinesAndHistory() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final userBox = Hive.box<UserSettings>('settingsBox');

  final userSettings = userBox.get('user');
  if (userSettings == null) return;

  final childId = userSettings.childId;

  // --- Fetch medicines ---
  final medResponse = await supabase
  .from('medicine')
  .select()
  .eq('child_id', childId);

  await medicinesBox.clear();
  for (var med in medResponse) {
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

  // --- Fetch history (last 7 days) ---
  final lastWeek = DateTime.now().subtract(const Duration(days: 7));
  final historyResponse = await supabase
  .from('history_entry')
  .select()
  .eq('child_id', childId)
  .gte('date', lastWeek.toIso8601String());

  print("Fetched history: $historyResponse");

  for (var h in historyResponse) {
    final normalizedName = h['medicine_name'].toString().trim();
    final time = h['time'];
    final dateStr = h['date'];

    // // Normalize key for Hive
    // final key = '$normalizedName@$time\_$dateStr';
    //
    // // Check if an entry already exists in Hive
    // final existingEntry = historyBox.values.firstWhereOrNull(
    //   (e) =>
    //   (e.remoteId != null && e.remoteId == h['id']) ||
    //   (e.medicineName.trim().toLowerCase() == normalizedName.toLowerCase() &&
    //   e.time == time &&
    //   e.date.toIso8601String().substring(0, 10) == dateStr),
    // );
    //
    // if (existingEntry != null) {
    //   // Update existing entry
    //   existingEntry.status = h['status'];
    //   existingEntry.medicineId = h['medicine_id'];
    //   existingEntry.childId = h['child_id'];
    //   existingEntry.remoteId = h['id'];
    //   await existingEntry.save();
    // } else {
    //   // Insert new entry
    //   final entry = HistoryEntry(
    //     date: DateTime.parse(dateStr),
    //     medicineName: normalizedName,
    //     status: h['status'],
    //     time: time,
    //     medicineId: h['medicine_id'],
    //     remoteId: h['id'],
    //     childId: h['child_id'],
    //   );
    //   await historyBox.put(key, entry);
    // }
    // Use medicineId if available, else fallback to normalizedName
    final medId = h['medicine_id'] ?? normalizedName;
    final key = '${medId}_${dateStr}_${time}';

    // Check by this key
    final existingEntry = historyBox.get(key);

    if (existingEntry != null) {
      existingEntry
      ..status = h['status']
      ..medicineId = h['medicine_id']
      ..childId = h['child_id']
      ..remoteId = h['id'];
      await existingEntry.save();
    } else {
      final entry = HistoryEntry(
        date: DateTime.parse(dateStr),
        medicineName: normalizedName,
        status: h['status'],
        time: time,
        medicineId: h['medicine_id'],
        remoteId: h['id'],
        childId: h['child_id'],
      );
      await historyBox.put(key, entry);
    }

  }

  print("✅ Medicines & recent history fetched and stored in Hive without duplicates.");
}
