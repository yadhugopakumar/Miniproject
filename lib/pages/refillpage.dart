import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/pages/screens/editmedicinepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/medicine.dart';
import '../Hivemodel/alarm_model.dart';
import '../Hivemodel/user_settings.dart';
import '../reminder/services/alarm_service.dart';
import '../utils/customsnackbar.dart';

class RefillTrackerPage extends StatefulWidget {
  const RefillTrackerPage({super.key});

  @override
  State<RefillTrackerPage> createState() => _RefillTrackerPageState();
}

class _RefillTrackerPageState extends State<RefillTrackerPage> {
  final _supabase = Supabase.instance.client;


Future<void> _refreshData() async {
  try {
    final userBox = Hive.box<UserSettings>('settingsBox');
    final userSettings = userBox.get('user') as UserSettings?;
    if (userSettings == null) {
      AppSnackbar.show(context,
          message: "No user settings found", success: false);
      return;
    }
    final childId = userSettings.childId;
    final box = Hive.box<Medicine>('medicinesBox');

    // Push all Hive medicines to Supabase
    for (final med in box.values) {
      try {
        await _supabase.from('medicine').upsert({
          'id': med.id,
          'child_id': childId,
          'name': med.name,
          'dosage': med.dosage,
          'total_quantity': med.totalQuantity,
          'quantity_left': med.quantityLeft,
          'expiry_date': med.expiryDate.toIso8601String(),
          'refill_threshold': med.refillThreshold,
          'daily_intake_times': med.dailyIntakeTimes,
        });
      } catch (e) {
        print("Supabase update failed for ${med.name}: $e");
      }
    }

    AppSnackbar.show(context,
        message: "Local changes synced to server", success: true);
  } catch (e) {
    print(e);
    AppSnackbar.show(context,
        message: "Failed to sync with server", success: false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Refill Tracker",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 20.0, left: 20, right: 20, bottom: 50),
          child: ValueListenableBuilder<Box<Medicine>>(
            valueListenable: Hive.box<Medicine>('medicinesBox').listenable(),
            builder: (context, box, _) {
              final meds = box.values.toList();
              if (meds.isEmpty) {
                return const Center(
                  child: Text(
                    'No medicines added yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: meds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final med = meds[index];
                  final lowStock = med.quantityLeft <= med.refillThreshold;

                  return Card(
                    key: ValueKey(med.id), // ⚡ add this
                    color: Colors.teal[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.medication,
                                  color: Color(0xFF166D5B)),
                            ),
                            title: Text(
                              med.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${med.quantityLeft} of ${med.totalQuantity} left",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: med.totalQuantity == 0
                                      ? 0
                                      : med.quantityLeft / med.totalQuantity,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    lowStock ? Colors.red : Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                            trailing: _statusChip(
                              lowStock ? "Refill Soon" : "Sufficient",
                              lowStock ? Colors.red[400]! : Colors.green[100]!,
                              textColor:
                                  lowStock ? Colors.white : Colors.green[800]!,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final TextEditingController _stockController =
                                      TextEditingController();

                                  bool? added = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Add Stock"),
                                      content: TextField(
                                        controller: _stockController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: "Quantity to add",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_stockController.text
                                                .trim()
                                                .isEmpty) return;
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text("Add"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (added == true) {
                                    int addedQty = int.tryParse(
                                            _stockController.text.trim()) ??
                                        0;
                                    if (addedQty <= 0) return;

                                    final box =
                                        Hive.box<Medicine>('medicinesBox');

                                    int newTotal = med.totalQuantity + addedQty;
                                    int newLeft = med.quantityLeft +
                                        addedQty; // optional: increase quantityLeft too

                                    final updatedMedicine = Medicine(
                                      id: med.id,
                                      name: med.name,
                                      dosage: med.dosage,
                                      expiryDate: med.expiryDate,
                                      dailyIntakeTimes: med.dailyIntakeTimes,
                                      totalQuantity: newTotal,
                                      quantityLeft: newLeft,
                                      refillThreshold: med.refillThreshold,
                                    );

                                    // Update Hive
                                    await box.put(med.id, updatedMedicine);

                                    // Update Supabase
                                    await Supabase.instance.client
                                        .from('medicine')
                                        .update({
                                      'total_quantity': newTotal,
                                      'quantity_left': newLeft,
                                    }).eq('id', med.id);

                                    AppSnackbar.show(context,
                                        message: "Stock updated successfully",
                                        success: true);
                                  }
                                },
                                icon: const Icon(
                                  Icons.stacked_bar_chart_outlined,
                                  color: Color.fromARGB(255, 255, 242, 123),
                                ),
                                label: const Text(
                                  "Add Stock",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 242, 123),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditMedicinePage(
                                        medicine: med,
                                        medicineKey: med.id,
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                label: const Text("Edit",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Confirm Deletion"),
                                      content: Text(
                                          "Are you sure you want to delete this medicine?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Delete"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    try {
                                      // 1. Cancel alarm first
                                      final alarmBox =
                                          Hive.box<AlarmModel>('alarms');
                                      final relatedAlarms = alarmBox.values
                                          .where((alarm) =>
                                              alarm.medicineName == med.name)
                                          .toList();

                                      // 🗑 Cancel and delete each alarm
                                      for (var alarm in relatedAlarms) {
                                        await AlarmService.deleteAlarm(
                                            alarm.id);
                                        await alarmBox.delete(alarm.id);
                                      }
                                      // 2. Delete from Supabase
                                      await _supabase
                                          .from('medicine')
                                          .delete()
                                          .eq('id', med.id);

                                      // 3. Delete from Hive
                                      await med.delete();

                                      AppSnackbar.show(
                                        context,
                                        message: "Deleted successfully",
                                        success: true,
                                      );
                                    } catch (e) {
                                      AppSnackbar.show(
                                        context,
                                        message: "Failed to delete medicine",
                                        success: false,
                                      );
                                    }
                                  }
                                },
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color,
      {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
