import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';


Future<void> fetchAndStoreTodaysMedicines() async {
  final supabase = Supabase.instance.client;
  final medicinesBox = Hive.box<Medicine>('medicinesBox');
  final userBox = Hive.box<UserSettings>('settingsBox');
  final userSettings = userBox.get('user'); // 'user' is the key you saved it with

if (userSettings == null) {
  print("No user found in Hive.");
  return;
}

final childId = userSettings.childId; // <-- String, UUID
print(childId);

  final today = DateTime.now().toIso8601String().substring(0, 10);
print(today);
  final response = await supabase
      .from('medicine')
      .select()
      .eq('child_id', childId);
      
print(response);
  if (response.isEmpty) {
    print("No medicines for today.");
    return;
  }

  // Clear old data so only today’s meds show
  await medicinesBox.clear();

  for (var med in response) {
    final medicine = Medicine(
      name: med['name'],
      dosage: med['dosage'],
      expiryDate: DateTime.parse(med['expiry_date']),
      dailyIntakeTimes: List<String>.from(med['daily_intake_times']),
      totalQuantity: med['total_quantity'],
      quantityLeft: med['quantity_left'],
      refillThreshold: med['refill_threshold'],
    );

    await medicinesBox.add(medicine);
  }

  print("Today's medicines fetched & stored in Hive.");
}
