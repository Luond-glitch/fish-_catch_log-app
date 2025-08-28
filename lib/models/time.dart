import 'package:flutter/material.dart';
class Time {
  final int hour;
  final int minute;

  const Time({
    required this.hour,
    required this.minute,
  });

  /// Format to "HH:mm"
  String format() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Convert from Dart's TimeOfDay if needed
  factory Time.fromTimeOfDay(TimeOfDay tod) {
    return Time(hour: tod.hour, minute: tod.minute);
  }

  /// Convert to Dart's TimeOfDay
  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
}