import 'package:flutter/material.dart';
import 'package:json_to_dart/screens/home.dart';
import 'package:json_to_dart/util/constants.dart';

void main() {
  runApp(const JsonToDartApp());
}

class JsonToDartApp extends StatelessWidget {
  const JsonToDartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Constant.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: false,
      ),
      home: const HomeScreen(),
    );
  }
}
