import 'package:flutter/material.dart';

class Calendarpage extends StatefulWidget {
  const Calendarpage({super.key});

  @override
  State<Calendarpage> createState() => _CalendarpageState();
}

class _CalendarpageState extends State<Calendarpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.green[800],
        centerTitle: true,
         titleTextStyle:const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: Text(
          'Your calendar will be displayed here',
          style: TextStyle(fontSize: 20, color: Colors.green[900]),
        ),
      ),
    );
  }
}