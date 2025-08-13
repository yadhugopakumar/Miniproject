import 'package:hive/hive.dart';
import '../Hivemodel/history_entry.dart';
import '../Hivemodel/medicine.dart';
import '../Hivemodel/user_settings.dart';

// Box names
const String medicinesBox = 'medicinesBox';
const String historyBox = 'historyBox';
const String settingsBox = 'settingsBox';

class HiveService {
  final medicines = Hive.box<Medicine>(medicinesBox);
  final history = Hive.box<HistoryEntry>(historyBox);
  final settings = Hive.box<UserSettings>(settingsBox);

  void addMedicine(Medicine med) => medicines.add(med);

  void markHistory(HistoryEntry entry) => history.add(entry);

  // void saveUserSettings(UserSettings settings) {
  //   final box = Hive.box<UserSettings>(settingsBox);
  //   box.clear(); // only one user supported
  //   box.add(settings);

  //   final session = Hive.box('session');
  //   session.put('loggedIn', true);
  //   session.put('username', settings.username);
  // }

  void saveUserSettings(UserSettings settings) {
    final box = Hive.box<UserSettings>('settingsBox');

    // Check for duplicate username
    final exists = box.values.any((u) => u.username == settings.username);
    if (!exists) {
      box.add(settings);
    }

    // Save session
    final session = Hive.box('session');
    session.put('loggedIn', true);
    session.put('username', settings.username);
    session.put('isRegistered', true);
  }

  // bool validateLogin(String username, String pin) {
  //   final box = Hive.box<UserSettings>(settingsBox);
  //   try {
  //     final user = box.values.firstWhere(
  //       (u) => u.username == username && u.pin == pin,
  //     );
  //     final session = Hive.box('session');
  //     session.put('loggedIn', true);
  //     session.put('username', user.username);
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }
bool validateLogin(String username, String pin) {
  final box = Hive.box<UserSettings>('settingsBox');
  final user = box.values.firstWhere(
    (u) => u.username == username && u.pin == pin,
    orElse: () => UserSettings(
      childId: '',
      username: '',
      pin: '',
      securityQuestion: '',
      securityAnswer: '',
      phone: '',
      parentEmail: '',
    ),
  );

  if (user.username.isNotEmpty) {
    final session = Hive.box('session');
    session.put('loggedIn', true);
    session.put('username', user.username);
    session.put('childId', user.childId);
    session.put('isRegistered', true);
    return true;
  }
  return false;
}


bool usernameExists(String username) {
  final box = Hive.box<UserSettings>('settingsBox');
  return box.values.any((u) => u.username == username);
}


  void logout() {
    Hive.box('session').clear();
  }

  bool isLoggedIn() {
    return Hive.box('session').get('loggedIn', defaultValue: false);
  }

  String? getLoggedUsername() {
    return Hive.box('session').get('username');
  }

  UserSettings? getUser() => settings.isNotEmpty ? settings.getAt(0) : null;

  bool isTaken(String medicineName, String time, DateTime date) {
    return history.values.any((entry) =>
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day &&
        entry.medicineName == "$medicineName@$time" &&
        entry.status == 'taken');
  }
}
