import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';

// String convertTo24Hour(String amPmTime) {
//   final parsed = DateFormat("hh:mm a").parse(amPmTime);
//   return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
// }
String convertTo24HourSafe(String time) {
  time = time.trim();
  if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
    final parsed = DateFormat("hh:mm a").parse(time);
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
  // Already in 24-hour format
  return time;
}

Future<void> fetchAndStoreTodaysMedicines() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final userBox = Hive.box<UserSettings>('settingsBox');
  final userSettings =
      userBox.get('user'); // 'user' is the key you saved it with

  if (userSettings == null) {
    print("No user found in Hive.");
    return;
  }

  final childId = userSettings.childId; // <-- String, UUID
  // final today = DateTime.now().toIso8601String().substring(0, 10);

  final response =
      await supabase.from('medicine').select().eq('child_id', childId);

  if (response.isEmpty) {
    print("No medicines for today.");
    return;
  }

  // Clear old data so only today’s meds show
  await medicinesBox.clear();

  for (var med in response) {
    // Convert all times to "HH:mm" before storing
    final convertedTimes = (med['daily_intake_times'] as List)
        .map((t) => convertTo24HourSafe(t))
        .toList();

    final medicine = Medicine(
      id: med['id'], // Assuming 'id' is the Supabase medicine ID
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
}
