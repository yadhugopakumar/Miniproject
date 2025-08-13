import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:medremind/pages/chatpage.dart';
import 'package:medremind/pages/homepage.dart';
import 'package:medremind/pages/innerpages/profilepage.dart';
import 'package:medremind/pages/refillpage.dart';
import 'package:medremind/pages/historypage.dart';

import 'Hivemodel/history_entry.dart';
import 'Hivemodel/medicine.dart';
import 'Hivemodel/user_settings.dart';

class Bottomnavbar extends StatefulWidget {
  final int initialIndex;
  const Bottomnavbar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<Bottomnavbar> createState() => _BottomnavbarState();
}

class _BottomnavbarState extends State<Bottomnavbar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const Homepage(),
    Chatpage(),
    const HistoryPage(),
    const RefillTrackerPage()
  ];
  bool isNotificationEnabled = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(), // << Add this here
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex != 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: const Color.fromARGB(255, 93, 255, 101),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 20,
                child: Container(
                  height: 65.0,
                  width: 65.0,
                  child: FloatingActionButton(
                    // backgroundColor: Color.fromARGB(255, 75, 44, 90),
                    backgroundColor: const Color.fromARGB(255, 16, 59, 65),

                    onPressed: () {},
                    child: const Icon(
                      Icons.mic_none_sharp,
                      size: 33,
                      color: Color.fromARGB(255, 174, 233, 156),
                      // color: Color.fromARGB(255, 255, 216, 42),
                    ),
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _selectedIndex != 1
          ? Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
              child: BottomAppBar(
                color: Colors.transparent,
                shape: const CircularNotchedRectangle(),
                notchMargin: 6.0,
                elevation: 0,
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[900]!.withOpacity(0.85),
                      // color: Colors.purple[900]!.withOpacity(0.8),

                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green[900]!,
                        width: 0.1,
                      ),
                    ),
                    height: kToolbarHeight + 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                            icon: Icons.home_outlined, index: 0, label: "Home"),
                        _buildNavItem(
                          icon: Icons.message_outlined,
                          index: 1,
                          label: "Chat",
                        ),
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 8,
                              height: 50,
                              color: Colors
                                  .transparent, // optional background placeholder
                            ),
                            Positioned(
                              top:
                                  -48, // half of height to make it overlap nicely
                              child: Container(
                                width: 75,
                                height: 75,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildNavItem(
                            icon: Icons.history_rounded,
                            index: 2,
                            label: "History"),
                        _buildNavItem(
                            icon: Icons.recycling_outlined,
                            index: 3,
                            label: "Refill"),
                      ],
                    )),
              ),
            )
          : null,
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // Navigate only for Chat
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Chatpage()),
          );
        } else {
          // Bottom bar behavior for others
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 5.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected
              ? const Color.fromARGB(255, 165, 255, 123)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: isSelected
                  ? const TextStyle(fontSize: 12, color: Colors.black)
                  : const TextStyle(
                      fontSize: 12, color: Color.fromARGB(255, 240, 240, 240)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green[800],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CircleAvatar(
                //   radius: 30,
                //   backgroundImage: AssetImage(
                //       'assets/avatar.png'), // Replace with your asset
                // ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 32,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.person_2,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Yadhu Gopakumar", // Or dynamically fetch user name
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8),
                child: ListTile(
                  title: const Text("Push Notifications"),
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color.fromARGB(255, 255, 153, 0),
                  ),
                  trailing: Switch(
                    trackColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 255, 202, 159),
                    ),
                    activeColor: Colors.green[700],
                    value: isNotificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        isNotificationEnabled = value;
                      });
                    },
                  ),
                ),
              ),
              draweritem(
                context,
                const Text('Profile'),
                Icons.person_pin,
                const Homepage(),
              ),
              // draweritem(
              //   context,
              //   const Text('Settings'),
              //   Icons.settings,
              //   Chatpage(),
              // ),
              draweritem(context, const Text("Overall report"), Icons.report,
                  const HistoryPage()),
              draweritem(context, const Text("Logout"), Icons.logout,
                  const Homepage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget draweritem(
      BuildContext context, Text title, IconData icon, Widget pagename) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 219, 222, 223),
          ),
          child: Builder(
            builder: (innerContext) => ListTile(
              leading: Icon(icon),
              title: title,
              onTap: () {
                if (title.data == "Logout") {
                  showDialog(
                    context: innerContext,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color.fromARGB(
                          255, 227, 255, 227), // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15), // Rounded corners
                      ),
                      title: const Text(
                        "Confirm Logout",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromARGB(255, 61, 13, 1),
                        ),
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog

                            // Clear local Hive data
                            // Clear Hive boxes
                            await Hive.box<UserSettings>('settingsBox').clear();
                            await Hive.box<Medicine>('medicinesBox').clear();
                            await Hive.box<HistoryEntry>('historyBox').clear();
                            await Hive.box('session').clear();

                            // Navigate to login page

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                                color: Color.fromARGB(255, 107, 0, 0),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    innerContext,
                    MaterialPageRoute(
                      builder: (context) =>
                          Profilepage(name: title.data ?? "Profile"),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
