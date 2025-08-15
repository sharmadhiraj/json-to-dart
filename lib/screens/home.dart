import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _jsonStringController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  String _dartClass = "";
  bool _isValidJsonString = true;
  bool _fromJson = true;
  bool _toJson = true;
  bool _parseList = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Constant.appName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          ),
          Text(
            "Convert JSON to Dart with ease! Supports nested classes and includes fromJson, toJson, and parseList methods.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return InkWell(
      onTap: () => Util.navigateToDeveloperPage(),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(
          "Developed & maintained by Dhiraj Sharma",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        const Divider(),
        _buildMainSection(),
        const Divider(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMainSection() {
    return Expanded(
      child: Center(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassNameTextField(),
            const SizedBox(height: 12),
            _buildJsonStringTextField(),
            const SizedBox(height: 12),
            _buildChooseOutputOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassNameTextField() {
    return TextField(
      controller: _classNameController,
      maxLines: 1,
      decoration: const InputDecoration(
        labelText: "Class Name",
        border: OutlineInputBorder(),
      ),
      onChanged: (text) => _update(),
    );
  }

  Widget _buildJsonStringTextField() {
    return Expanded(
      child: TextField(
        controller: _jsonStringController,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        maxLines: 100,
        onChanged: (text) => _update(),
        decoration: InputDecoration(
          hintText: "Enter JSON here",
          border: const OutlineInputBorder(),
          errorText: _isValidJsonString ? null : "Invalid JSON",
        ),
      ),
    );
  }

  Widget _buildChooseOutputOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.all(0),
          title: const Text('Generate fromJson method'),
          value: _fromJson,
          onChanged: (value) {
            setState(() => _fromJson = value ?? _fromJson);
            _update();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.all(0),
          title: const Text('Generate toJson method'),
          value: _toJson,
          onChanged: (value) {
            setState(() => _toJson = value ?? _toJson);
            _update();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.all(0),
          title: const Text('Generate parseList method'),
          value: _parseList,
          onChanged: (value) {
            setState(() => _parseList = value ?? _parseList);
            _update();
          },
        ),
      ],
    );
  }

  Widget _buildDartClassOutputSection() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: double.maxFinite,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildButtons(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  width: double.maxFinite,
                  child: Text(
                    _dartClass,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final String fileName =
        "${Util.convertToValidFileName(Util.getClassName(_classNameController.text))}.dart";
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: "Download $fileName file",
            onPressed: () => Util.initiateDownload(fileName, _dartClass),
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: "Copy Class Code to Clipboard",
            onPressed: () => Clipboard.setData(ClipboardData(text: _dartClass)),
            icon: const Icon(Icons.copy),
          )
        ],
      ),
    );
  }

  void _update() {
    String jsonString = _jsonStringController.text;
    if (jsonString.isEmpty) jsonString = "{}";
    setState(
        () => _isValidJsonString = Util.checkIfValidJsonString(jsonString));
    if (!_isValidJsonString) return;
    setState(() {
      _dartClass = Util.generateDartClass(
        jsonString,
        _classNameController.text,
        _fromJson,
        _toJson,
        _parseList,
      );
    });
  }
}
