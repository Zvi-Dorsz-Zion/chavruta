import 'package:flutter/services.dart';

/// הגשר לצד ה-Kotlin (`CompanionEngine.kt`): תיקיית הנתונים, שם המכשיר,
/// ושירות החזית שמחזיק את המתאם חי כשאוצריא בחזית.
class Native {
  static const _channel = MethodChannel('chavruta/native');

  static Future<String> filesDir() async =>
      (await _channel.invokeMethod<String>('filesDir'))!;

  static Future<String> deviceName() async {
    final name = await _channel.invokeMethod<String>('deviceName');
    return (name == null || name.trim().isEmpty) ? 'Android' : name.trim();
  }

  static Future<void> startService() async {
    await _channel.invokeMethod<Object?>('startService');
  }

  static Future<void> stopService() async {
    await _channel.invokeMethod<Object?>('stopService');
  }
}
