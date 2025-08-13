import 'package:hive/hive.dart';

import '../Hivemodel/user_settings.dart';
import 'hive_services.dart';

class AuthService {
  final HiveService _hive = HiveService();

  bool isRegistered() => _hive.getUser() != null;

  bool validatePin(String pin) {
    final user = _hive.getUser();
    return user != null && user.pin == pin;
  }

void register(
  String childId,
  String name,
  String pin,
  String sound,
  String selectedQuestion,
  String answer,
  String parentPhone,
  String parentEmail,
) {
  _hive.saveUserSettings(UserSettings(
    childId: childId,
    username: name,
    pin: pin,
    alarmSound: sound,
    securityQuestion: selectedQuestion,
    securityAnswer: answer,
    phone: parentPhone,
    parentEmail: parentEmail,
  ));
}

void logout() {
  final session = Hive.box('session');
  session.put('loggedIn', false);
  session.delete('email');
}


}
