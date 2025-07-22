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
        padding: const EdgeInsets.only(bottom: 19),
        child: Material(
          color: Color.fromARGB(255, 93, 255, 101),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 10,
          child: Container(
            height: 70.0,
            width: 70.0,
            child: FloatingActionButton(
              backgroundColor: Color.fromARGB(255, 36, 28, 59),
              onPressed: () {},
              child: const Icon(
                Icons.mic_none_sharp,
                size: 30,
                color: Color.fromARGB(255, 233, 63, 63),
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
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              height: kToolbarHeight + 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      icon: Icons.home_outlined, index: 0, label: "Home"),
                  _buildNavItem(
                      icon: Icons.message_outlined, index: 1, label: "Chat"),
                  const SizedBox(width: 45), // For FAB notch
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
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isSelected
                ? Color.fromARGB(255, 141, 233, 98)
                : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black :  Colors.white,
                ),
                SizedBox(height: 4),
                Text(
                  isSelected ? label : "",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
