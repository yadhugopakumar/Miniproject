// import 'package:flutter/material.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:medremind/constants/constants.dart';
// import 'package:medremind/pages/auth/loginpage.dart';
// import 'package:medremind/pages/auth/pinlogin.dart';
// // import 'package:path_provider/path_provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'Hivemodel/chat_message.dart';
// import 'Hivemodel/health_report.dart';
// import 'Hivemodel/history_entry.dart';
// import 'Hivemodel/medicine.dart';
// import 'Hivemodel/user_settings.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Hive.initFlutter();
//   // final dir = await getApplicationDocumentsDirectory();
//   // print("Hive files location: ${dir.path}");
//   Hive.registerAdapter(UserSettingsAdapter());
//   Hive.registerAdapter(MedicineAdapter());
//   Hive.registerAdapter(HistoryEntryAdapter());
//   Hive.registerAdapter(HealthReportAdapter());
//   Hive.registerAdapter(ChatMessageAdapter());

//   await Hive.openBox<HealthReport>('healthReportsBox');
//   await Hive.openBox<UserSettings>('settingsBox');
//   await Hive.openBox<Medicine>('medicinesBox');
//   await Hive.openBox<HistoryEntry>('historyBox');
//   await Hive.openBox<ChatMessage>('chatMessages');
//   await Hive.openBox('session');

// // Initialize Supabase
//   await Supabase.initialize(
//     url: Appconstants.supabase_url,
//     anonKey: Appconstants.supabase_anon_key,
//   );
//   // await dotenv.load(
//   //     fileName: "/media/yadhu/hdisk/flutter_projects/medremind/.env");

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     const String settingsBox = 'settingsBox';
//     final Box<UserSettings> userBox = Hive.box<UserSettings>(settingsBox);

//     final bool isRegistered = userBox.isNotEmpty;

//     return MaterialApp(
//       title: 'Medemind',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         iconTheme: const IconThemeData(
//           color: Colors.black,
//         ),
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: isRegistered ? const LockScreen() : const LoginPage(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medremind/constants/constants.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:medremind/pages/auth/pinlogin.dart';
import 'package:medremind/reminder/alarmscreen.dart';
import 'package:medremind/reminder/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Hivemodel/chat_message.dart';
import 'Hivemodel/health_report.dart';
import 'Hivemodel/history_entry.dart';
import 'Hivemodel/medicine.dart';
import 'Hivemodel/user_settings.dart';
import 'Hivemodel/alarm_model.dart';
import 'reminder/services/alarm_service.dart';
import 'package:alarm/alarm.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  // Initialize Alarm package and AlarmService
  await Alarm.init();
  await AlarmService.init();
  await NotificationService.init(); // ✅ initialize here

  // Register adapters only if not already registered
  if (!Hive.isAdapterRegistered(UserSettingsAdapter().typeId)) {
    Hive.registerAdapter(UserSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(MedicineAdapter().typeId)) {
    Hive.registerAdapter(MedicineAdapter());
  }
  if (!Hive.isAdapterRegistered(HistoryEntryAdapter().typeId)) {
    Hive.registerAdapter(HistoryEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(HealthReportAdapter().typeId)) {
    Hive.registerAdapter(HealthReportAdapter());
  }
  if (!Hive.isAdapterRegistered(ChatMessageAdapter().typeId)) {
    Hive.registerAdapter(ChatMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(AlarmModelAdapter().typeId)) {
    Hive.registerAdapter(AlarmModelAdapter());
  }

  // Open boxes
  await Hive.openBox<HealthReport>('healthReportsBox');
  await Hive.openBox<UserSettings>('settingsBox');
  await Hive.openBox<Medicine>('medicinesBox');
  await Hive.openBox<HistoryEntry>('historyBox');
  await Hive.openBox<ChatMessage>('chatMessages');
  await Hive.openBox<AlarmModel>('alarms');
  await Hive.openBox('session');

  // Initialize Supabase
  await Supabase.initialize(
    url: Appconstants.supabase_url,
    anonKey: Appconstants.supabase_anon_key,
  );

// listen for alarm trigger
  Alarm.ringStream.stream.listen((alarmSettings) {
    final alarm = AlarmService.getAlarmById(alarmSettings.id);
    if (alarm != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(alarm: alarm),
        ),
      );
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<UserSettings> userBox = Hive.box<UserSettings>('settingsBox');
    final bool isRegistered = userBox.isNotEmpty;

    return MaterialApp(
      title: 'MedRemind',
      theme: ThemeData(
        primarySwatch: Colors.green,
        iconTheme: const IconThemeData(color: Colors.black),
        scaffoldBackgroundColor: Colors.white,
      ),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isRegistered ? const LockScreen() : const LoginPage(),
    );
  }
}
