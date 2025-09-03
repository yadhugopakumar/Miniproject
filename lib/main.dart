import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:medremind/constants/constants.dart';
import 'package:medremind/pages/auth/loginpage.dart';
import 'package:medremind/pages/auth/pinlogin.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Hivemodel/chat_message.dart';
import 'Hivemodel/health_report.dart';
import 'Hivemodel/history_entry.dart';
import 'Hivemodel/medicine.dart';
import 'Hivemodel/user_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // final dir = await getApplicationDocumentsDirectory();
  // print("Hive files location: ${dir.path}");
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(MedicineAdapter());
  Hive.registerAdapter(HistoryEntryAdapter());
  Hive.registerAdapter(HealthReportAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  await Hive.openBox<HealthReport>('healthReportsBox');
  await Hive.openBox<UserSettings>('settingsBox');
  await Hive.openBox<Medicine>('medicinesBox');
  await Hive.openBox<HistoryEntry>('historyBox');
  await Hive.openBox<ChatMessage>('chatMessages');
  await Hive.openBox('session');

// Initialize Supabase
  await Supabase.initialize(
    url: Appconstants.supabase_url,
    anonKey: Appconstants.supabase_anon_key,
  );
  // await dotenv.load(
  //     fileName: "/media/yadhu/hdisk/flutter_projects/medremind/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    const String settingsBox = 'settingsBox';
    final Box<UserSettings> userBox = Hive.box<UserSettings>(settingsBox);

    final bool isRegistered = userBox.isNotEmpty;

    return MaterialApp(
      title: 'Medemind',
      theme: ThemeData(
        primarySwatch: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: isRegistered ? const LockScreen() : const LoginPage(),
    );
  }
}
