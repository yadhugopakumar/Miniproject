import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init(); // Initialize alarm package
  await AlarmService.init(); // Initialize Hive
  runApp(const MedRemindApp());
}

class MedRemindApp extends StatelessWidget {
  const MedRemindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedRemind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const HomePage(),
    );
  }
}

