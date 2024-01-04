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
            _buildClassNameTextField(),
            const SizedBox(height: 12),
            _buildJsonStringTextField(),
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
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Text(
                _dartClass,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final String fileName =
        "${Util.convertToValidFileName(Util.getClassName(_classNameController.text))}.dart";
    return Positioned(
      right: 0,
      child: Row(
        children: [
          IconButton(
            tooltip: "Download $fileName",
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
      );
    });
  }
}
