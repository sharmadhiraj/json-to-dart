import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_to_dart/data/app_settings.dart';
import 'package:json_to_dart/data/settings_service.dart';
import 'package:json_to_dart/generator/dart_generator.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/json_formatter.dart';
import 'package:json_to_dart/generator/json_parser.dart';
import 'package:json_to_dart/generator/naming.dart';

class ConverterController extends ChangeNotifier {
  ConverterController({
    SettingsService settingsService = const SettingsService(),
    Duration debounceDuration = const Duration(milliseconds: 300),
  })  : _settingsService = settingsService,
        _debounceDuration = debounceDuration;

  final SettingsService _settingsService;
  final Duration _debounceDuration;
  final TextEditingController jsonController = TextEditingController();
  final TextEditingController classNameController = TextEditingController();
  final FocusNode jsonFocusNode = FocusNode();

  Timer? _debounce;
  String _dartClass = "";
  String? _error;
  GeneratorOptions _options = const GeneratorOptions();
  String? _generatedJson;
  String? _generatedClassName;
  GeneratorOptions? _generatedOptions;
  bool _disposed = false;

  String get dartClass => _dartClass;
  String? get error => _error;
  GeneratorOptions get options => _options;
  String get fileName => "${Naming.fileName(classNameController.text)}.dart";

  Future<void> load() async {
    final AppSettings settings = await _settingsService.load();
    if (_disposed) return;
    jsonController.text = settings.jsonCode;
    classNameController.text = settings.className;
    _options = settings.options;
    _regenerate();
  }

  void onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _regenerate);
  }

  void setOptions(GeneratorOptions options) {
    _options = options;
    _regenerate();
  }

  void setJson(String text) {
    jsonController.text = text;
    _regenerate();
  }

  void clear() => setJson("");

  void focusInput() => jsonFocusNode.requestFocus();

  void formatJson() {
    try {
      setJson(JsonFormatter.prettify(jsonController.text));
    } on JsonParseException catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _regenerate() {
    _debounce?.cancel();
    final String jsonText = jsonController.text;
    final String className = classNameController.text;
    if (jsonText == _generatedJson &&
        className == _generatedClassName &&
        identical(_options, _generatedOptions)) {
      return;
    }
    _generatedJson = jsonText;
    _generatedClassName = className;
    _generatedOptions = _options;

    String dartClass = "";
    String? error;
    if (jsonText.trim().isNotEmpty) {
      try {
        dartClass =
            DartGenerator.generate(jsonText, className, options: _options);
      } on JsonParseException catch (e) {
        error = e.toString();
      } on GeneratorException catch (e) {
        error = e.message;
      }
    }
    _dartClass = dartClass;
    _error = error;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() {
    return _settingsService.save(
      AppSettings(
        className: classNameController.text,
        jsonCode: jsonController.text,
        options: _options,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    if (_debounce?.isActive ?? false) unawaited(_persist());
    _debounce?.cancel();
    jsonController.dispose();
    classNameController.dispose();
    jsonFocusNode.dispose();
    super.dispose();
  }
}
