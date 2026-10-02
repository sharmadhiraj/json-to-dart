import 'package:flutter/material.dart';
import 'package:json_to_dart/data/settings_service.dart';
import 'package:json_to_dart/screens/home.dart';
import 'package:json_to_dart/util/app_theme.dart';
import 'package:json_to_dart/util/constants.dart';

void main() {
  runApp(const JsonToDartApp());
}

class JsonToDartApp extends StatefulWidget {
  const JsonToDartApp({super.key});

  @override
  State<JsonToDartApp> createState() => _JsonToDartAppState();
}

class _JsonToDartAppState extends State<JsonToDartApp> {
  final SettingsService _settings = const SettingsService();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _settings.loadThemeMode().then((mode) {
      if (mounted) setState(() => _themeMode = mode);
    });
  }

  void _toggleTheme(Brightness current) {
    final ThemeMode mode =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = mode);
    _settings.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Constant.appName,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(onToggleTheme: _toggleTheme),
    );
  }
}
