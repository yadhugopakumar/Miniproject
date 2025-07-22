
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageStateContent(); // Renamed to avoid conflict
}

class _HomepageStateContent extends State<Homepage> { // Renamed to avoid conflict
  final DateTime today = DateTime.now();

  // Removed initState as it contained Hive logic

  @override
  Widget build(BuildContext context) {
    const Color backgroundGreen = Color(0xFF166D5B);

    // Static data for demonstration
    final double staticProgress = 0.75;
    final int staticTakenCount = 3;
    final int staticTotalDoses = 4;

    // Static schedule entries
    final List<Map<String, dynamic>> staticSchedule = [
      {'medicine': 'Amoxicillin', 'time': '8:00 AM', 'taken': true},
      {'medicine': 'Ibuprofen', 'time': '12:00 PM', 'taken': false},
      {'medicine': 'Vitamin D', 'time': '6:00 PM', 'taken': true},
      {'medicine': 'Melatonin', 'time': '9:00 PM', 'taken': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedRemind',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 5, bottom: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[300],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: IconButton(
                onPressed: () {
                  print('Profile button pressed!');
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => Profilepg())), // Removed navigation
                },
                icon: const Icon(Icons.person_3_outlined,
                    color: Colors.white, size: 28),
              ),
            ),
          )
        ],
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          _buildProgressBar(staticProgress, staticTakenCount, staticTotalDoses),
          _buildQuickActions(context, backgroundGreen),
          const Padding(
            padding: EdgeInsets.only(left: 20.0, bottom: 3, top: 16),
            child: Text("Today's Schedule",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          // Dynamically build schedule tiles from static data
          ...staticSchedule.map((entry) {
            return _scheduleTile(
              context,
              medicine: entry['medicine'],
              dose: entry['time'],
              taken: entry['taken'],
              backgroundGreen: backgroundGreen,
              onTap: () {
                print('Tapped on ${entry['medicine']} - ${entry['time']}');
                // You can add local state management here if needed for 'taken' status
              },
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, int taken, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800!, Colors.green.shade400!], // Added ! for null safety
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
            offset: const Offset(0, 6), // x=0, y=6 (bottom shadow)
            blurRadius: 8,
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
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 11,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                color: Color.fromARGB(255, 71, 72, 94),
                icon: Icons.add_alert,
                label: "Add Medicine",
                onTap: () {
                  print('Add Medicine tapped!');
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => AddMedicinePage())), // Removed navigation
                },
              ),
              _quickActionCard(
                context: context,
                color: Color.fromARGB(255, 194, 123, 43),
                icon: Icons.calendar_month_outlined,
                label: "Calendar View",
                onTap: () {
                  print('Calendar View tapped!');
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => Calenderpg())), // Removed navigation
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
        elevation: 5,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
    required String dose,
    required bool taken,
    required VoidCallback onTap,
    required Color backgroundGreen,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), // Added margin for spacing
      child: ListTile(
        leading: Icon(Icons.medical_services, color: backgroundGreen),
        title: Text(medicine,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle:
            Text(dose, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        trailing: ElevatedButton(
          onPressed: taken ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: taken ? backgroundGreen : Colors.yellow[700],
            foregroundColor: taken ? Colors.white : Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(taken ? "Taken" : "Take"),
        ),
      ),
    );
  }
}

// Removed formatTime and navigatorKey as they were related to Hive data and navigation
