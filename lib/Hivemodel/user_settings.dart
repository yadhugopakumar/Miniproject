import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 3) // Make sure this typeId is unique across all models
class UserSettings extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String pin;
  
  @HiveField(2)
  String ? phone;

  @HiveField(3)
  String ? parentEmail;

  @HiveField(4)
  String alarmSound;

  @HiveField(5)
  String securityQuestion;

  @HiveField(6)
  String securityAnswer;

  @HiveField(7)
  String childId;
  
  UserSettings({
    required this.childId,
    required this.username,
    required this.pin,
    required this.securityQuestion,
    required this.securityAnswer,
     this.phone,
     this.parentEmail,
    String? alarmSound,
  }) : alarmSound = alarmSound ?? 'default_alarm.mp3';
}
