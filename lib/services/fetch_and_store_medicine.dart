import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';

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

Future<void> pushTodayHistoryToSupabase() async {
  final supabase = Supabase.instance.client;
  final historyBox = Hive.box<HistoryEntry>('historyBox');

  if (historyBox.isEmpty) return;

  final today = DateTime.now();
  List<Map<String, dynamic>> batch = [];

  for (var entry in historyBox.values) {
    if (entry.date.year != today.year ||
        entry.date.month != today.month ||
        entry.date.day != today.day) continue;

    // Use stored medicine_id instead of name
    // Removed redundant null check for entry.medicineId

    String? timeStr;
    if (entry.time != null) {
      timeStr = entry.time;
    }

    batch.add({
      'medicine_id': entry.medicineId,
      'date': entry.date.toIso8601String().substring(0, 10),
      'status': entry.status,
      'time': timeStr,
    });
  }

  // Deduplicate batch
  final seenKeys = <String>{};
  final dedupedBatch = <Map<String, dynamic>>[];
  for (var row in batch) {
    final key = '${row['medicine_id']}-${row['date']}-${row['time']}';
    if (!seenKeys.contains(key)) {
      dedupedBatch.add(row);
      seenKeys.add(key);
    }
  }

  if (dedupedBatch.isEmpty) return;

  try {
    await supabase
        .from('history_entry')
        .upsert(dedupedBatch, onConflict: 'history_unique');

    print("Today's local history synced to Supabase successfully.");
  } catch (e, stackTrace) {
    print("Error syncing today's history: $e");
    print(stackTrace);
  }
}

Future<void> fetchAndStoreTodaysMedicines() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
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
  pushTodayHistoryToSupabase();
}
