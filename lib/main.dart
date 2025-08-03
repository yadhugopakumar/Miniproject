import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:medremind/pages/auth/pinlogin.dart';
import 'package:medremind/pages/auth/register.dart';
import 'package:medremind/services/hive_services.dart';

import 'Hivemodel/history_entry.dart';
import 'Hivemodel/medicine.dart';
import 'Hivemodel/user_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(MedicineAdapter());
  Hive.registerAdapter(HistoryEntryAdapter());


  await Hive.openBox<UserSettings>('settingsBox');
  await Hive.openBox<Medicine>('medicinesBox');
  await Hive.openBox<HistoryEntry>('historyBox');
  await Hive.openBox('session');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
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
      home: isRegistered ? const LockScreen() : const RegisterScreen(),
    );
  }
}
