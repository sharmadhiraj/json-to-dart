import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_to_dart/data/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  const SettingsService();

  static const String _key = "jsonToDartSettings";
  static const String _themeKey = "jsonToDartThemeMode";
  static const String _historyKey = "jsonToDartHistory";

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

  Future<ThemeMode> loadThemeMode() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_themeKey);
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }

  Future<List<AppSettings>> loadHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_historyKey);
      if (stored == null) return [];
      return [
        for (final Object? item in jsonDecode(stored) as List<Object?>)
          AppSettings.fromJson(item! as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<AppSettings> history) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        jsonEncode([for (final AppSettings h in history) h.toJson()]),
      );
    } catch (_) {}
  }
}
