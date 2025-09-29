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

Future<void> pushUnsyncedHistoryToSupabase() async {
  final supabase = Supabase.instance.client;
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final medicinesBox = Hive.box<Medicine>('medicinesBox');

  final today = DateTime.now();
  final unsynced = historyBox.values
      .where((e) =>
          e.remoteId == null &&
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day)
      .toList();

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
      final medicine = medicinesBox.values.firstWhereOrNull((m) =>
          m.name.trim().toLowerCase() ==
          entry.medicineName.trim().toLowerCase());
      if (medicine != null) {
        entry.medicineId = medicine.id;
        await entry.save();
        print("Linked ${entry.medicineName} -> ${medicine.id}");
      } else {
        print(
            "Skipping entry '${entry.medicineName}@${entry.time}' because medicine not found in Hive");
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
  final userBox = Hive.box<UserSettings>('settingsBox');
  final userSettings = userBox.get('user');
  final childId = userSettings?.childId;

  final batch = readyToSync
      .map((e) => {
            'medicine_id': e.medicineId,
            'child_id': childId,
            'medicine_name': e.medicineName,
            'date': e.date.toIso8601String().substring(0, 10),
            'status': e.status,
            'time': e.time,
          })
      .toList();

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

      // final key = '${medId}_${dateStr}_$time';
      final key = '${medId}_${dateStr}_${time}_${childId}';

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

String buildDoseKey(
    String medicineId, DateTime date, String time, String childId) {
  final formattedDate = DateFormat('yyyy-MM-dd').format(date); // zero-padded
  return '${medicineId}_${formattedDate}_${time}_${childId}';
}

// --- Fetch and store medicines ---
Future<void> fetchAndStoreMedicines() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final userBox = Hive.box<UserSettings>('settingsBox');

  final userSettings = userBox.get('user');
  if (userSettings == null) return;
  final childId = userSettings.childId;

  final medResponse =
      await supabase.from('medicine').select().eq('child_id', childId);

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

  print("✅ Medicines fetched and stored in Hive.");
}

// --- Fetch and store recent history ---
Future<void> fetchAndStoreRecentHistory() async {
  final supabase = Supabase.instance.client;
  final historyBox = Hive.box<HistoryEntry>('historyBox');
  final userBox = Hive.box<UserSettings>('settingsBox');

  final userSettings = userBox.get('user');
  if (userSettings == null) return;
  final childId = userSettings.childId;

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
    final medicineId = h['medicine_id'] ?? normalizedName;

    final key = buildDoseKey(
        medicineId.toString(), DateTime.parse(dateStr), time, childId);

    final existingEntry = historyBox.get(key);
    if (existingEntry != null) {
      existingEntry
        ..status = h['status']
        ..medicineId = h['medicine_id']
        ..childId = childId
        ..remoteId = h['id'];
      await existingEntry.save();
    } else {
      final entry = HistoryEntry(
        date: DateTime.parse(dateStr),
        medicineName: normalizedName,
        status: h['status'],
        time: time,
        medicineId: h['medicine_id'] ?? normalizedName,
        remoteId: h['id'],
        childId: childId,
      );
      await historyBox.put(key, entry);
    }
  }

  print("✅ Recent history fetched and stored in Hive.");
}
