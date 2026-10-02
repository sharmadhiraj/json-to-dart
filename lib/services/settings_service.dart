import 'dart:convert';

import 'package:json_to_dart/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  const SettingsService._();

  static const String _key = "jsonToDartSettings";

  static Future<AppSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_key);
      if (stored == null) return const AppSettings();
      return AppSettings.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  static Future<void> save(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
