import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/generator/dart_generator.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/models/app_settings.dart';
import 'package:json_to_dart/services/settings_service.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/web_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideLayoutMinWidth = 800;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  Timer? _debounce;
  String _dartClass = "";
  String? _error;
  GeneratorOptions _options = const GeneratorOptions();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jsonController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final AppSettings settings = await SettingsService.load();
    if (!mounted) return;
    _jsonController.text = settings.jsonCode;
    _classNameController.text = settings.className;
    _options = settings.options;
    _regenerate();
  }

  void _scheduleUpdate() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _regenerate);
  }

  void _setOptions(GeneratorOptions options) {
    _options = options;
    _regenerate();
  }

  void _regenerate() {
    _debounce?.cancel();
    final String jsonText = _jsonController.text;
    String dartClass = "";
    String? error;
    if (jsonText.trim().isNotEmpty) {
      try {
        dartClass = DartGenerator.generate(
          jsonDecode(jsonText),
          _classNameController.text,
          options: _options,
        );
      } on FormatException {
        error = "Invalid JSON";
      } on GeneratorException catch (e) {
        error = e.message;
      }
    }
    setState(() {
      _dartClass = dartClass;
      _error = error;
    });
    if (error == null) {
      unawaited(
        SettingsService.save(
          AppSettings(
            className: _classNameController.text,
            jsonCode: jsonText,
            options: _options,
          ),
        ),
      );
    }
  }

  String get _fileName => "${Naming.fileName(_classNameController.text)}.dart";

  void _copy() {
    Clipboard.setData(ClipboardData(text: _dartClass));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          const Divider(),
          _buildMainSection(),
          const Divider(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Column(
        children: [
          Text(
            Constant.appName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          ),
          Text(
            Constant.appDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Semantics(
      button: true,
      label: "Open developer profile",
      child: InkWell(
        onTap: () => WebUtils.openUrl(Constant.developerUrl),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            "Developed & maintained by ${Constant.developerName}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMainSection() {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<Widget> panels = [
                Expanded(child: _buildInputSection()),
                Expanded(child: _buildOutputSection()),
              ];
              return constraints.maxWidth >= _wideLayoutMinWidth
                  ? Row(children: panels)
                  : Column(children: panels);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _classNameController,
            decoration: const InputDecoration(
              labelText: "Class Name",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _scheduleUpdate(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _jsonController,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: "monospace"),
              onChanged: (_) => _scheduleUpdate(),
              decoration: InputDecoration(
                hintText: "Enter JSON here",
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            "Generate fromJson method",
            _options.fromJson,
            (v) => _setOptions(_options.copyWith(fromJson: v)),
          ),
          _buildOptionTile(
            "Generate toJson method",
            _options.toJson,
            (v) => _setOptions(_options.copyWith(toJson: v)),
          ),
          _buildOptionTile(
            "Generate parseList method",
            _options.parseList,
            _options.fromJson
                ? (v) => _setOptions(_options.copyWith(parseList: v))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Semantics(
      label: title,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged:
            onChanged == null ? null : (v) => onChanged(v ?? value),
      ),
    );
  }

  Widget _buildOutputSection() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool hasOutput = _dartClass.isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  button: true,
                  label: "Download $_fileName",
                  child: IconButton(
                    tooltip: "Download $_fileName file",
                    onPressed: hasOutput
                        ? () => WebUtils.downloadFile(_fileName, _dartClass)
                        : null,
                    icon: const Icon(Icons.download),
                  ),
                ),
                Semantics(
                  button: true,
                  label: "Copy class code to clipboard",
                  child: IconButton(
                    tooltip: "Copy Class Code to Clipboard",
                    onPressed: hasOutput ? _copy : null,
                    icon: const Icon(Icons.copy),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: SelectableText(
                  _dartClass,
                  style: const TextStyle(fontFamily: "monospace", fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
