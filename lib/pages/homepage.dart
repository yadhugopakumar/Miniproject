import 'package:flutter/material.dart';
import 'package:medremind/pages/screens/addmedicinepage.dart';
import 'package:medremind/pages/screens/calendarpage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageStateContent();
}

class _HomepageStateContent extends State<Homepage> {
  final DateTime today = DateTime.now();

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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          pinned: true,
          expandedHeight: 60.0,
          // backgroundColor: Colors.green[800],
          backgroundColor:
              Colors.green[800], // Changed to purple for better contrast

          elevation: 0,
          centerTitle: true,
          flexibleSpace: const FlexibleSpaceBar(
            stretchModes: [StretchMode.zoomBackground],
            centerTitle: false,
            expandedTitleScale: 1.8,
            title: Text('MedRemind',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            titlePadding: const EdgeInsets.only(left: 60, bottom: 18),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(
                  staticProgress, staticTakenCount, staticTotalDoses),
              _buildQuickActions(context, backgroundGreen),
              const Padding(
                padding: EdgeInsets.only(left: 20.0, bottom: 3, top: 16),
                child: Text("Today's Schedule",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = staticSchedule[index];
              return _scheduleTile(
                context,
                medicine: entry['medicine'],
                dose: entry['time'],
                taken: entry['taken'],
                backgroundGreen: backgroundGreen,
                onTap: () {
                  print('Tapped on ${entry['medicine']} - ${entry['time']}');
                },
              );
            },
            childCount: staticSchedule.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 130)),
      ],
    );
  }

  Widget _buildProgressBar(double progress, int taken, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // Colors.green.shade800,
            // Colors.green.shade500
            Colors.green[800]!, // Changed to purple for better contrast
            Colors.green[400]!, // Changed to purple for better contrast
          ], // Added ! for null safety
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
                      // color: Colors.purple[800],

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
                // color: Color.fromARGB(255, 68, 120, 161),
                color: Color.fromARGB(255, 19, 71, 214),
                // color: Color.fromARGB(255, 21, 95, 79),
                // color:Color.fromARGB(255, 248, 73, 50),

                icon: Icons.add_alert,
                label: "Add Medicine",
                onTap: () {
                  print('Add Medicine tapped!');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddMedicinePage())); // Removed navigation
                },
              ),
              _quickActionCard(
                context: context,
                // color: Color.fromARGB(255, 189, 21, 240),
                color: Color.fromARGB(255, 123, 0, 148),
// color: Color.fromARGB(255, 91, 73, 255),
                icon: Icons.calendar_month_outlined,
                label: "Calendar View",
                onTap: () {
                  print('Calendar View tapped!');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              Calendarpage())); // Removed navigation
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
    required String dose,
    required bool taken,
    required VoidCallback onTap,
    required Color backgroundGreen,
  }) {
    return Card(
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.7),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.panorama_photosphere_rounded,
          // Icons.lens_blur_outlined,
          color: Colors.green[700],
          size: 30,
        ),
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
