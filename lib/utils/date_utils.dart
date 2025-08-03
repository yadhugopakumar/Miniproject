import 'package:flutter/material.dart';

String formatTime(String time) {
  final parts = time.split(":");
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
  return "$formattedHour:${minute.toString().padLeft(2, '0')} $suffix";
}
String timeOfDayToString(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
