import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/pages/screens/addmedicinepage.dart';
import 'package:medremind/pages/screens/calendarpage.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../services/fetch_and_store_medicine.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageStateContent();
}

class _HomepageStateContent extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    fetchAndStoreTodaysMedicines();
  }

  final DateTime today = DateTime.now();

  bool _isTaken(String medicineName, String time, DateTime date,
      Box<HistoryEntry> historyBox) {
    return historyBox.values.any((entry) =>
        entry.medicineName == "$medicineName@$time" &&
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day &&
        entry.status == 'taken');
  }

  String _formatTime(TimeOfDay time, BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundGreen = Color(0xFF166D5B);
    final historyBox = Hive.box<HistoryEntry>('historyBox');

    Future<void> _refreshData() async {
      await fetchAndStoreTodaysMedicines(); // call your Supabase fetch
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
              List<_TodaySchedule> sortMedicines(List<_TodaySchedule> meds) {
                final now = DateTime.now();

                meds.sort((a, b) {
                  // Convert schedule times to DateTime for today
                  DateTime timeA = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(a.time.split(':')[0]),
                    int.parse(a.time.split(':')[1]),
                  );
                  DateTime timeB = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(b.time.split(':')[0]),
                    int.parse(b.time.split(':')[1]),
                  );

                  // Determine categories
                  int catA = a.taken
                      ? 1 // Taken → last
                      : now.isAfter(timeA)
                          ? 2 // Missed → middle
                          : 0; // Incoming → first

                  int catB = b.taken
                      ? 2
                      : now.isAfter(timeB)
                          ? 1
                          : 0;

                  // First sort by category (incoming → missed → taken)
                  if (catA != catB) return catA.compareTo(catB);

                  // Then by time (earlier times first)
                  return timeA.compareTo(timeB);
                });

                return meds;
              }

              // ✅ sort AFTER filling the list
              final sortedMeds = sortMedicines(todayMeds);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // final sched = todayMeds[index];
                    final sched = sortedMeds[index];
                    final timeFormatted = _formatTime(
                      TimeOfDay(
                        hour: int.parse(sched.time.split(':')[0]),
                        minute: int.parse(sched.time.split(':')[1]),
                      ),
                      context,
                    );

// Determine if the dose is missed
                    final now = DateTime.now();
                    final doseTimeParts = sched.time.split(':');
                    final doseDateTime = DateTime(
                      today.year,
                      today.month,
                      today.day,
                      int.parse(doseTimeParts[0]),
                      int.parse(doseTimeParts[1]),
                    );

                    final isMissed = now.isAfter(doseDateTime) && !sched.taken;

                    return _scheduleTile(context,
                        medicine: sched.medicine.name,
                        dosage: sched.dosage,
                        time: isMissed ? 'Missed' : timeFormatted,
                        taken: sched.taken,
                        backgroundGreen: backgroundGreen,
                        isMissed: isMissed, // pass it here
                        onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Color.fromARGB(255, 244, 255, 251),
                          title: const Text("Mark Dose as Taken"),
                          content: const Text(
                              "Do you want to mark this dose as taken?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Yes"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final now = DateTime.now();
                        final doseKey =
                            '${sched.medicine.name}_${sched.time}_${now.year}-${now.month}-${now.day}';

                        await historyBox.put(
                          doseKey,
                          HistoryEntry(
                            date: now,
                            time: sched.time,
                            medicineName:
                                "${sched.medicine.name}@${sched.time}",
                            status: 'taken',
                          ),
                        );

                        final med = sched.medicine;
                        final key = med.key;
                        if (key != null) {
                          med.quantityLeft =
                              (med.quantityLeft > 0) ? med.quantityLeft - 1 : 0;
                          await med.save();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text(
                              'Marked as taken!',
                              style: TextStyle(color: Colors.black),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color.fromARGB(255, 198, 252, 200),
                            margin: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                          ),
                        );

                        setState(() {});
                      }
                    });
                  },
                  childCount: todayMeds.length,
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
      pinned: true,
      expandedHeight: 60.0,
      backgroundColor: Colors.green[800],
      elevation: 0,
      centerTitle: true,
      flexibleSpace: const FlexibleSpaceBar(
        stretchModes: [StretchMode.zoomBackground],
        expandedTitleScale: 1.8,
        title: Text('MedRemind',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
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

  Widget _scheduleTile(
    BuildContext context, {
    required String medicine,
    required String time,
    required String dosage,
    required bool taken,
    required VoidCallback onTap,
    required Color backgroundGreen,
    bool isMissed = false, // NEW PARAM
  }) {
    return Card(
      color: taken ? Color.fromARGB(255, 214, 245, 255) : Colors.white,
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.7),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.medication_liquid,
          color: isMissed ? Colors.red : Colors.green[700],
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
          onPressed: (taken || isMissed) ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: taken
                ? backgroundGreen
                : isMissed
                    ? Colors.red[400]
                    : Colors.yellow[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              taken
                  ? "Taken"
                  : isMissed
                      ? "Missed"
                      : "Take",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
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
