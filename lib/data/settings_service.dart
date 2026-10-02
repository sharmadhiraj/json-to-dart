import 'dart:convert';

import 'package:json_to_dart/data/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  const SettingsService();

  static const String _key = "jsonToDartSettings";

  Future<AppSettings> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_key);
      if (stored == null) return const AppSettings();
      return AppSettings.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  /// Returns false when storage is unavailable or full.
  Future<bool> save(AppSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_key, jsonEncode(settings.toJson()));
    } catch (_) {
      return false;
    }
  }
}
