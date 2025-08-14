import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/pages/screens/editmedicinepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';

class RefillTrackerPage extends StatefulWidget {
  const RefillTrackerPage({super.key});

  @override
  State<RefillTrackerPage> createState() => _RefillTrackerPageState();
}

class _RefillTrackerPageState extends State<RefillTrackerPage> {
  final _supabase = Supabase.instance.client;

  Future<void> _refreshData() async {
    try {
      final userBox = Hive.box('settingsBox');
      final userSettings = userBox.get('user') as UserSettings?;
      if (userSettings == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user settings found")),
        );
        return;
      }
      final childId = userSettings.childId;
      // Fetch from Supabase
      final response = await _supabase
          .from('medicine')
          .select()
          .eq('child_id', childId) // filter only this child's medicines
          .order('id', ascending: true);

      if (response.isNotEmpty) {
        final box = Hive.box<Medicine>('medicinesBox');

        // Clear old data before inserting fresh data
        await box.clear();

        for (final item in response) {
          final medicine = Medicine(
            id: item['id'], // Use Supabase ID
            name: item['name'],
            dosage: item['dosage'],
            totalQuantity: item['total_quantity'],
            quantityLeft: item['quantity_left'],
            expiryDate: DateTime.parse(item['expiry_date']),
            refillThreshold: item['refill_threshold'],
            dailyIntakeTimes:
                List<String>.from(item['daily_intake_times'] ?? []),
          );
          await box.add(medicine);
        }
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch updates from server")),
      );
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
                  final lowStock = med.quantityLeft <= med.totalQuantity * 0.25;

                  return Card(
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
                                onPressed: () {
                                  Navigator.push(
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
                                      await _supabase
                                          .from('medicine')
                                          .delete()
                                          .eq('id', med.id); // Supabase delete
                                      await med.delete(); // Hive delete

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 1),
                                          
                                          content: Text(
                                              "Medicine ${med.name} deleted successfully"),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                            content: Text(
                                                "Failed to delete on server")),
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
