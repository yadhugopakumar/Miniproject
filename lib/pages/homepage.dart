import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/pages/screens/addmedicinepage.dart';
import 'package:medremind/pages/screens/calendarpage.dart';
import '../Hivemodel/alarm_model.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../reminder/vibrationcontroller.dart';
import '../services/fetch_and_store_medicine.dart';
import 'package:badges/badges.dart' as badges;
import '../../Hivemodel/user_settings.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageStateContent();
}

class _HomepageStateContent extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    fetchAndStoreTodaysMedicinesAndHistory();
  }

  final DateTime today = DateTime.now();

  // bool _isTaken(String medicineName, String time, DateTime date,
  //     Box<HistoryEntry> historyBox) {
  //   return historyBox.values.any((entry) =>
  //       entry.medicineName == "$medicineName@$time" &&
  //       entry.date.year == date.year &&
  //       entry.date.month == date.month &&
  //       entry.date.day == date.day &&
  //       entry.status == 'taken');
  // }

  bool _isTaken(String medicineName, String time, DateTime date, Box<HistoryEntry> historyBox) {
    return historyBox.values.any((entry) =>
    entry.medicineName == medicineName &&
    entry.time == time &&
    entry.date.year == date.year &&
    entry.date.month == date.month &&
    entry.date.day == date.day &&
    (entry.status == 'taken' || entry.status == 'takenLate')
    );
  }

  String formatTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12; // midnight or noon correction

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _stopAlarmAndVibrationForMedicine(Medicine medicine) async {
    final alarmBox = await Hive.openBox<AlarmModel>('alarmBox');
    final alarms =
        alarmBox.values.where((a) => a.medicineName == medicine.name);
    for (var alarm in alarms) {
      await VibrationController.stopVibration();
      await Alarm.stop(alarm.id);
      if (alarm.snoozeId != null) {
        await Alarm.stop(alarm.snoozeId!);
      }
    }
  }

// Inside your SliverList builder:
  String _getDoseStatus(String medicineName, String time, DateTime date,
      Box<HistoryEntry> historyBox) {
    final entry = historyBox.values.cast<HistoryEntry?>().firstWhere(
          (e) =>
              e != null &&
              e.medicineName == "$medicineName@$time" &&
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
          orElse: () => null,
        );
    if (entry == null) return 'pending';
    return entry.status;
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundGreen = Color(0xFF166D5B);
    final historyBox = Hive.box<HistoryEntry>('historyBox');

    Future<void> _refreshData() async {
      await fetchAndStoreTodaysMedicinesAndHistory(); // call your Supabase fetch
      setState(() {}); // rebuild UI with updated Hive data
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<Box<Medicine>>(
                  valueListenable:
                      Hive.box<Medicine>('medicinesBox').listenable(),
                  builder: (context, box, _) {
                    final meds = box.values.toList();
                    int totalDoses = 0, takenCount = 0;
                    final todayMeds = <_TodaySchedule>[];
                    for (var med in meds) {
                      for (final time in med.dailyIntakeTimes) {
                        totalDoses++;
                        final isDoseTaken =
                            _isTaken(med.name, time, today, historyBox);
                        if (isDoseTaken) takenCount++;
                        todayMeds.add(_TodaySchedule(
                          medicine: med,
                          time: time,
                          dosage: med.dosage,
                          taken: isDoseTaken,
                        ));
                      }
                    }
                    double progress =
                        (totalDoses > 0) ? takenCount / totalDoses : 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressBar(progress, takenCount, totalDoses),
                        _buildQuickActions(context, backgroundGreen),
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 20.0, bottom: 3, top: 16),
                          child: Text("Today's Schedule",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder<Box<Medicine>>(
            valueListenable: Hive.box<Medicine>('medicinesBox').listenable(),
            builder: (context, box, _) {
              final meds = box.values.toList();
              final todayMeds = <_TodaySchedule>[];
              final historyBox = Hive.box<HistoryEntry>('historyBox');
              for (var med in meds) {
                for (final time in med.dailyIntakeTimes) {
                  todayMeds.add(_TodaySchedule(
                    medicine: med,
                    time: time,
                    dosage: med.dosage,
                    taken: _isTaken(med.name, time, today, historyBox),
                  ));
                }
              }
              List<_TodaySchedule> sortMedicines(List<_TodaySchedule> meds,
                  Box<HistoryEntry> historyBox, DateTime today) {
                // Status priority: lower → higher priority
                final statusPriority = {
                  'pending': 0, // not taken
                  'taken': 1,
                  'missed': 4,
                  'takenLate': 3,
                  'snoozed': 2,
                };

                meds.sort((a, b) {
                  final statusA = _getDoseStatus(
                      a.medicine.name, a.time, today, historyBox);
                  final statusB = _getDoseStatus(
                      b.medicine.name, b.time, today, historyBox);

                  final catA = statusPriority[statusA] ?? 5;
                  final catB = statusPriority[statusB] ?? 5;

                  if (catA != catB) return catA.compareTo(catB);

                  // If same category, sort by time
                  final timeA = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    int.parse(a.time.split(':')[0]),
                    int.parse(a.time.split(':')[1]),
                  );
                  final timeB = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    int.parse(b.time.split(':')[0]),
                    int.parse(b.time.split(':')[1]),
                  );

                  return timeA.compareTo(timeB);
                });

                return meds;
              }

// Usage in SliverList
              final sortedMeds = sortMedicines(todayMeds, historyBox, today);
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sched = sortedMeds[index];

                    final status = _getDoseStatus(
                        sched.medicine.name, sched.time, today, historyBox);

                    // Map status to visuals
                    Color iconColor;
                    Color buttonColor;
                    String buttonText;
                    bool disableButton;

                    switch (status) {
                      case 'taken':
                        iconColor = Colors.green;
                        buttonColor = Colors.green[700]!;
                        buttonText = "Taken";
                        disableButton = true;
                        break;
                      case 'takenLate':
                        iconColor = Colors.orange;
                        buttonColor = Colors.orange;
                        buttonText = "Taken Late"; // allow user to confirm
                        disableButton = true;
                        break;
                      case 'missed':
                        iconColor = Colors.red;
                        buttonColor = Colors.red[400]!;
                        buttonText = "Take Late";
                        disableButton = false;
                        break;
                      case 'snoozed':
                        iconColor = Colors.blue;
                        buttonColor = Colors.blue[400]!;
                        buttonText = "Snoozed";
                        disableButton = false;
                        break;
                      default: // pending
                        iconColor = Colors.green[700]!;
                        buttonColor = Colors.yellow[600]!;
                        buttonText = "Take";
                        disableButton = false;
                    }

                    final isMissed = status == 'missed';
                    final timeFormatted = formatTime(sched.time);
                    return _scheduleTile(
                      context,
                      medicine: sched.medicine.name,
                      dosage: sched.dosage,
                      time: timeFormatted,
                      taken: disableButton,
                      isMissed: isMissed,
                      backgroundGreen: backgroundGreen,
                      iconColor: iconColor,
                      buttonColor: buttonColor,
                      buttonText: buttonText,
                      disableButton: disableButton,
//                       onTap: () async {
//                         if (disableButton) return;
//
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (_) => AlertDialog(
//                             title: Text(buttonText == 'Confirm Taken'
//                                 ? "Confirm this dose was taken?"
//                                 : "Do you want to mark this dose as taken?"),
//                             actions: [
//                               TextButton(
//                                   onPressed: () =>
//                                       Navigator.pop(context, false),
//                                   child: Text("No")),
//                               TextButton(
//                                   onPressed: () => Navigator.pop(context, true),
//                                   child: Text("Yes")),
//                             ],
//                           ),
//                         );
//
//                         if (confirm != true) return;
//
//                         final now = DateTime.now();
//                         final doseKey =
//                             '${sched.medicine.name}@${sched.time}_${now.year}-${now.month}-${now.day}';
// print(doseKey);
//                         String newStatus;
//                         if (status == 'missed') {
//                           newStatus =
//                               'takenLate'; // first time marking a missed dose
//                         } else if (status == 'takenLate') {
//                           newStatus = 'Late Taken'; // confirm late
//                         } else if (status == 'taken') {
//                           newStatus = 'taken'; // already taken, confirmation
//                         } else {
//                           newStatus = 'taken'; // normal take
//                         }
//                         final userBox = Hive.box<UserSettings>('settingsBox');
//                         final userSettings = userBox.get('user');
//                         if (userSettings == null) {
//
//                           return;
//                         }
//
//
//                         final childId = userSettings.childId;
//
//                         print(childId);
//                         print(sched.medicine.name);
//                         print( sched.medicine.id);
//                         print(newStatus);
//                         await historyBox.put(
//                           doseKey,
//                           HistoryEntry(
//                             date: now,
//                             time: sched.time,
//                             medicineName: sched.medicine.name, // remove "@time" from name
//                             medicineId: sched.medicine.id,     // ✅ set medicineId
//                             childId: childId,     // ✅ set childId
//                             status: newStatus,
//                           ),
//                         );
//
//                         if (newStatus == 'taken') {
//                           final dose = int.tryParse(sched.medicine.dosage) ?? 1;
//                           sched.medicine.quantityLeft =
//                               (sched.medicine.quantityLeft - dose)
//                                   .clamp(0, sched.medicine.quantityLeft);
//                           await sched.medicine.save();
//                         }
//
//                         setState(() {}); // refresh tile
//                       },
                      onTap: () async {
                        if (disableButton) return;

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(buttonText == 'Confirm Taken'
                            ? "Confirm this dose was taken?"
                            : "Do you want to mark this dose as taken?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("No")),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Yes")),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        final today = DateTime.now();
                        final doseKey =
                        '${sched.medicine.name}@${sched.time}_${today.year}-${today.month}-${today.day}';
                    print(doseKey);

                    String newStatus;
                    if (status == 'missed') {
                      newStatus = 'takenLate'; // first time marking a missed dose
                    } else if (status == 'takenLate') {
                      newStatus = 'takenLate'; // keep same status or confirm late
                    } else {
                      newStatus = 'taken'; // normal or already taken
                    }

                    final userBox = Hive.box<UserSettings>('settingsBox');
                    final userSettings = userBox.get('user');
                    if (userSettings == null) return;
                    final childId = userSettings.childId;

                        // Check if entry already exists
                        HistoryEntry? entry = historyBox.get(doseKey);
                        if (entry != null) {
                          // Update existing entry
                          entry.status = newStatus;
                          entry.medicineId = sched.medicine.id; // ✅ set medicineId
                          entry.childId = childId;             // ✅ set childId
                          entry.time = sched.time;             // keep scheduled time
                          await entry.save();
                        } else {
                          // Create new entry
                          entry = HistoryEntry(
                            date: today,
                            time: sched.time,
                            medicineName: sched.medicine.name, // do NOT include @time
                            medicineId: sched.medicine.id,     // ✅ set medicineId
                            childId: childId,                 // ✅ set childId
                            status: newStatus,
                          );
                          await historyBox.put(doseKey, entry);
                        }

                        if (newStatus == 'taken') {
                          final dose = int.tryParse(sched.medicine.dosage) ?? 1;
                          sched.medicine.quantityLeft =
                          (sched.medicine.quantityLeft - dose).clamp(0, sched.medicine.quantityLeft);
                          await sched.medicine.save();
                        }

                        setState(() {}); // refresh tile
                      },

                    );
                  },
                  childCount: sortedMeds.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

Widget _buildAppBar() {
  return SliverAppBar(
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    actions: [
      ValueListenableBuilder(
        valueListenable: Hive.box<Medicine>('medicinesBox').listenable(),
        builder: (context, box, _) {
          final meds = box.values.toList();
          final today = DateTime.now();

          List<Map<String, dynamic>> allNotifs = [];

          // Low stock & expiry
          for (var med in meds) {
            if (med.quantityLeft <= med.refillThreshold) {
              allNotifs.add({
                "id": "med_stock_${med.key}",
                "title": med.name,
                "subtitle": "Low stock: ${med.quantityLeft} left",
                "icon": Icons.medication_liquid,
                "color": Colors.blue,
              });
            }
            if (med.expiryDate.isBefore(today.add(const Duration(days: 7)))) {
              allNotifs.add({
                "id": "med_expiry_${med.key}",
                "title": med.name,
                "subtitle":
                    "Expiring on: ${med.expiryDate.toLocal().toString().split(' ')[0]}",
                "icon": Icons.warning,
                "color": Colors.red,
              });
            }
          }

          // Health checkup at start or end of month
          if (today.day == 1 ||
              today.day == DateTime(today.year, today.month + 1, 0).day) {
            allNotifs.add({
              "id": "extra_checkup",
              "title": "It’s time for your monthly health checkup! 🩺",
              "subtitle": "",
              "icon": Icons.health_and_safety,
              "color": Colors.green,
            });
          }

          return badges.Badge(
            position: badges.BadgePosition.topEnd(top: 3, end: 5),
            showBadge: allNotifs.isNotEmpty,
            badgeContent: Text(
              allNotifs.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white,size: 30,),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) {
                    // Keep list mutable inside dialog
                    List<Map<String, dynamic>> dialogNotifs =
                        List.from(allNotifs);

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor:
                              const Color.fromARGB(255, 233, 251, 255),
                          title: const Text(
                            "Notifications",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: dialogNotifs.isEmpty
                                ? const Text("No notifications 🎉")
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: dialogNotifs.length,
                                    itemBuilder: (context, index) {
                                      final notif = dialogNotifs[index];
                                      return Dismissible(
                                        key: ValueKey(notif["id"]),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (_) {
                                          setState(() {
                                            dialogNotifs.removeAt(index);
                                          });
                                        },
                                        background: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: const Icon(Icons.delete,
                                              color: Colors.white),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            notif["icon"] as IconData,
                                            color: notif["color"] as Color,
                                          ),
                                          title: Text(
                                            notif["title"].toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: notif["subtitle"]
                                                  .toString()
                                                  .isNotEmpty
                                              ? Text(notif["subtitle"]
                                                  .toString())
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    ],
    pinned: true,
    expandedHeight: 60.0,
    backgroundColor: Colors.green[800],
    elevation: 0,
    centerTitle: true,
    flexibleSpace: const FlexibleSpaceBar(
      stretchModes: [StretchMode.zoomBackground],
      expandedTitleScale: 1.8,
      title: Text(
        'MedRemind',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      titlePadding: EdgeInsets.only(left: 60, bottom: 18),
    ),
  );
}

  Widget _buildProgressBar(double progress, int taken, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[800]!,
            Colors.green[400]!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 6),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[800],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 11,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
                Text("${(progress * 100).toInt()}%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Positioned(
                  bottom: 30,
                  child: Text("$taken of $total doses",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 10),
              child: Text("Today's Progress",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color backgroundGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          const Text("Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickActionCard(
                context: context,
                color: const Color.fromARGB(255, 19, 71, 214),
                icon: Icons.add_alert,
                label: "Add Medicine",
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddMedicinePage()));
                },
              ),
              _quickActionCard(
                context: context,
                color: const Color.fromARGB(255, 123, 0, 148),
                icon: Icons.calendar_month_outlined,
                label: "Calendar View",
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => Calendarpage()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 7,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 33, color: Colors.white),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

//   Widget _scheduleTile(
//     BuildContext context, {
//     required String medicine,
//     required String time,
//     required String dosage,
//     required bool taken,
//     required VoidCallback onTap,
//     required Color backgroundGreen,
//     bool isMissed = false, // NEW PARAM
//   }) {
//     return Card(
//       color: taken ? Color.fromARGB(255, 214, 245, 255) : Colors.white,
//       elevation: 6,
//       shadowColor: Colors.green.withOpacity(0.7),
//       margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
//       child: ListTile(
//         leading: Icon(
//           Icons.medication_liquid,
//           color: isMissed ? Colors.red : Colors.green[700],
//           size: 30,
//         ),
//         title: Text(
//           "$medicine ($dosage ${int.tryParse(dosage) == 1 ? 'pill' : 'pills'})",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             decoration: isMissed ? TextDecoration.lineThrough : null,
//             color: isMissed ? Colors.grey[700] : null,
//           ),
//         ),
//         subtitle: Text(
//           time,
//           style: TextStyle(
//             fontSize: 13,
//             color: isMissed ? Colors.red[700] : Colors.grey[600],
//             fontWeight: isMissed ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         trailing: ElevatedButton(
//           onPressed: (taken || isMissed) ? null : onTap,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: taken
//                 ? backgroundGreen
//                 : isMissed
//                     ? Colors.red[400]
//                     : Colors.yellow[600],
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(
//               taken
//                   ? "Taken"
//                   : isMissed
//                       ? "Missed"
//                       : "Take",
//               style: TextStyle(color: Colors.black),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
  Widget _scheduleTile(
    BuildContext context, {
    required String medicine,
    required String dosage,
    required String time,
    required bool taken,
    required VoidCallback onTap,
    required Color backgroundGreen,
    bool isMissed = false,
    Color? iconColor, // new
    Color? buttonColor, // new
    String? buttonText, // new
    bool? disableButton, // new
  }) {
    return Card(
      color: taken ? Color.fromARGB(255, 214, 245, 255) : Colors.white,
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.7),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.medication_liquid,
          color: iconColor ?? (isMissed ? Colors.red : Colors.green[700]),
          size: 30,
        ),
        title: Text(
          "$medicine ($dosage ${int.tryParse(dosage) == 1 ? 'pill' : 'pills'})",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: isMissed ? TextDecoration.lineThrough : null,
            color: isMissed ? Colors.grey[700] : null,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
            fontSize: 13,
            color: isMissed ? Colors.red[700] : Colors.grey[600],
            fontWeight: isMissed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: disableButton ?? false ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ??
                (taken
                    ? backgroundGreen
                    : isMissed
                        ? Colors.red[400]
                        : Colors.yellow[600]),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              buttonText ??
                  (taken
                      ? "Taken"
                      : isMissed
                          ? "Missed"
                          : "Take"),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

extension DateHelpers on DateTime {
  String toShortDateString() =>
      "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year}";
}

class _TodaySchedule {
  final Medicine medicine;
  final String time;
  final bool taken;
  final String dosage;

  _TodaySchedule({
    required this.medicine,
    required this.time,
    required this.taken,
    required this.dosage,
  });
}
