import 'package:flutter/material.dart';
import 'package:medremind/pages/chatpage.dart';
import 'package:medremind/pages/homepage.dart';
import 'package:medremind/pages/refillpage.dart';
import 'package:medremind/pages/historypage.dart';

class Bottomnavbar extends StatefulWidget {
  @override
  State<Bottomnavbar> createState() => _BottomnavbarState();
}

class _BottomnavbarState extends State<Bottomnavbar> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    Homepage(),
    Chatpage(),
    Historypage(),
    Refillpage()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: Color.fromARGB(255, 93, 255, 101),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 20,
          child: Container(
            height: 70.0,
            width: 70.0,
            child: FloatingActionButton(
              backgroundColor: Color.fromARGB(255, 36, 28, 59),
              onPressed: () {},
              child: const Icon(
                Icons.mic_none_sharp,
                size: 30,
                color: Color.fromARGB(255, 134, 255, 97),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: BottomAppBar(
          color: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          elevation: 10,
          child: Container(
              decoration: BoxDecoration(
                color: Colors.green[900]!.withOpacity(0.8),
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
                      icon: Icons.message_outlined, index: 1, label: "Chat"),
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 6,
                        height: 50,
                        color: Colors.transparent, // optional background placeholder
                      ),
                      Positioned(
                        top: -51, // half of height to make it overlap nicely
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildNavItem(
                      icon: Icons.history_rounded, index: 2, label: "History"),
                  _buildNavItem(
                      icon: Icons.recycling_outlined,
                      index: 3,
                      label: "Refill"),
                ],
              )),
        ),
      ),
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
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: MediaQuery.of(context).size.width / 5.4,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isSelected
                ? Color.fromARGB(255, 165, 255, 123)
                : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
            SizedBox(height: 2),
            Text(
              isSelected ? label : label,
              style: isSelected
                  ? TextStyle(fontSize: 12, color: Colors.black)
                  : TextStyle(
                      fontSize: 12, color: Color.fromARGB(255, 240, 240, 240)),
            ),
          ],
        ),
      ),
    );
  }
}
