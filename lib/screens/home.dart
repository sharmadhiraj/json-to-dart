import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_to_dart/util/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _jsonInputController = TextEditingController();
  bool _isValidJson = true;
  String _dartClass = "";
  String _className = "";

  @override
  void initState() {
    super.initState();
    _jsonInputController.addListener(() {
      _onTextChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(Constant.appName),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJsonInputSection(),
            _buildDartClassOutputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonInputSection() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: "Class Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() => _className = text);
                _generateDartClass();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                autofocus: true,
                controller: _jsonInputController,
                keyboardType: TextInputType.multiline,
                maxLines: 100,
                decoration: InputDecoration(
                  hintText: "Enter JSON here",
                  border: const OutlineInputBorder(),
                  errorText: _isValidJson ? null : "Invalid JSON",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDartClassOutputSection() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        height: double.maxFinite,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Text(
            _dartClass,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _onTextChange() {
    setState(() {
      _isValidJson = _checkIfValidJson();
      _generateDartClass();
    });
  }

  bool _checkIfValidJson() {
    try {
      jsonDecode(_jsonInputController.text);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _generateDartClass() {
    if (!_checkIfValidJson()) {
      return;
    }
    dynamic jsonData = jsonDecode(_jsonInputController.text);
    String data = "";
    if (jsonData is Map<String, dynamic>) {
      data = _generateClassFromMap(jsonData);
    } else if (jsonData is List) {
      if (jsonData.isNotEmpty) {
        data = _generateClassFromMap(jsonData[0]);
      }
    }
    setState(() {
      _dartClass = data;
    });
  }

  String _generateClassFromMap(Map<String, dynamic> jsonMap) {
    StringBuffer classBuffer = StringBuffer();
    classBuffer.writeln(
        'class ${_className.trim().isEmpty ? "AutoGenerated" : _className} {');
    jsonMap.forEach((key, value) {
      classBuffer.writeln('  ${_getDartType(value)} $key;');
    });
    classBuffer.writeln('}');
    return classBuffer.toString();
  }

  String _getDartType(dynamic value) {
    if (value is String) {
      return 'String';
    } else if (value is int) {
      return 'int';
    } else if (value is double) {
      return 'double';
    } else if (value is bool) {
      return 'bool';
    } else if (value is List) {
      return 'List<dynamic>';
    } else if (value is Map) {
      return 'Map<String, dynamic>';
    } else {
      return 'dynamic';
    }
  }
}
