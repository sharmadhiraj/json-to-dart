// ignore_for_file: cascade_invocations

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/data/app_settings.dart';
import 'package:json_to_dart/data/settings_service.dart';
import 'package:json_to_dart/generator/generator_options.dart';

class FakeSettingsService extends SettingsService {
  FakeSettingsService([this.initial = const AppSettings()]);

  final AppSettings initial;
  final List<AppSettings> saved = [];
  List<AppSettings> history = [];

  @override
  Future<AppSettings> load() async => initial;

  @override
  Future<List<AppSettings>> loadHistory() async => history;

  @override
  Future<void> saveHistory(List<AppSettings> entries) async {
    history = List.of(entries);
  }

  @override
  Future<bool> save(AppSettings settings) async {
    saved.add(settings);
    return true;
  }
}

Future<Object?>? _ignoreCalls(MethodCall call) async => null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, _ignoreCalls);
  });

  const Duration debounce = Duration(milliseconds: 10);

  ConverterController create(FakeSettingsService service) =>
      ConverterController(settingsService: service, debounceDuration: debounce);

  test("load restores settings and generates", () async {
    final FakeSettingsService service = FakeSettingsService(
      const AppSettings(
        className: "User",
        jsonCode: '{"id":1}',
        options: GeneratorOptions(toJson: false),
      ),
    );
    final ConverterController c = create(service);
    await c.load();
    expect(c.dartClass, contains("class User {"));
    expect(c.dartClass, isNot(contains("toJson")));
    expect(c.error, isNull);
    c.dispose();
  });

  test("input changes are debounced", () async {
    final FakeSettingsService service = FakeSettingsService();
    final ConverterController c = create(service);
    await c.load();
    service.saved.clear();
    c.jsonController.text = '{"a":1}';
    c.onInputChanged();
    c.jsonController.text = '{"a":1,"b":2}';
    c.onInputChanged();
    expect(c.dartClass, isEmpty);
    await Future<void>.delayed(debounce * 4);
    expect(c.dartClass, contains("final int b;"));
    expect(service.saved, hasLength(1));
    c.dispose();
  });

  test("invalid JSON sets an error with position and still persists", () async {
    final FakeSettingsService service = FakeSettingsService();
    final ConverterController c = create(service);
    await c.load();
    c.setJson("{");
    expect(c.error, contains("line 1"));
    expect(c.dartClass, isEmpty);
    expect(service.saved.last.jsonCode, "{");
    c.dispose();
  });

  test("regenerating unchanged input does not save again", () async {
    final FakeSettingsService service = FakeSettingsService();
    final ConverterController c = create(service);
    await c.load();
    c.setJson('{"a":1}');
    final int saves = service.saved.length;
    c.setJson('{"a":1}');
    expect(service.saved, hasLength(saves));
    c.dispose();
  });

  test("format and clear", () async {
    final ConverterController c = create(FakeSettingsService());
    await c.load();
    c
      ..setJson('{"a":1}')
      ..formatJson();
    expect(c.jsonController.text, '{\n  "a": 1\n}');
    c.clear();
    expect(c.jsonController.text, isEmpty);
    expect(c.dartClass, isEmpty);
    c.dispose();
  });

  test("file name follows class name", () async {
    final ConverterController c = create(FakeSettingsService());
    await c.load();
    c.classNameController.text = "MyUser";
    expect(c.fileName, "my_user.dart");
    c.dispose();
  });

  test("load prefers the provided initial settings", () async {
    final FakeSettingsService service = FakeSettingsService(
      const AppSettings(jsonCode: '{"stored":1}'),
    );
    final ConverterController c = create(service);
    await c.load(initial: const AppSettings(jsonCode: '{"shared":1}'));
    expect(c.dartClass, contains("shared"));
    expect(c.dartClass, isNot(contains("stored")));
    c.dispose();
  });

  test("class renames apply, then reset when new JSON is loaded", () async {
    final ConverterController c = create(FakeSettingsService());
    await c.load();
    c.setJson('{"user":{"id":1}}');
    expect(c.nestedClasses.single.name, "User");
    c.setClassRenames({"User": "Account"});
    expect(c.dartClass, contains("class Account {"));
    expect(c.nestedClasses.single.original, "User");
    c.formatJson();
    expect(c.dartClass, contains("class Account {"));
    c.setJson('{"user":{"id":2}}');
    expect(c.dartClass, contains("class User {"));
    c.dispose();
  });

  test("copyOutput flags copied, then resets", () async {
    final ConverterController c = create(FakeSettingsService());
    await c.load();
    await c.copyOutput();
    expect(c.copied, isFalse);
    c.setJson('{"a":1}');
    await c.copyOutput();
    expect(c.copied, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    expect(c.copied, isFalse);
    c.dispose();
  });

  test("currentSettings reflects the editor state", () async {
    final ConverterController c = create(FakeSettingsService());
    await c.load();
    c.classNameController.text = "Thing";
    c.setJson('{"a":1}');
    expect(c.currentSettings.className, "Thing");
    expect(c.currentSettings.jsonCode, '{"a":1}');
    c.dispose();
  });

  group("recent inputs", () {
    test("replacing content remembers the previous input", () async {
      final FakeSettingsService service = FakeSettingsService();
      final ConverterController c = create(service);
      await c.load();
      c.setJson('{"a":1}');
      expect(c.history, isEmpty);
      c.setJson('{"b":1}');
      expect(c.history.map((h) => h.jsonCode), ['{"a":1}']);
      expect(service.history.map((h) => h.jsonCode), ['{"a":1}']);
      c.dispose();
    });

    test("formatting in place does not add history", () async {
      final ConverterController c = create(FakeSettingsService());
      await c.load();
      c.setJson('{"a":1}');
      c.formatJson();
      expect(c.history, isEmpty);
      c.dispose();
    });

    test("restore swaps the current input into history", () async {
      final ConverterController c = create(FakeSettingsService());
      await c.load();
      c.classNameController.text = "One";
      c.setJson('{"a":1}');
      c.setJson('{"b":1}');
      expect(c.history.single.className, "One");
      c.classNameController.text = "Two";
      c.restore(0);
      expect(c.classNameController.text, "One");
      expect(c.dartClass, contains("final int a;"));
      expect(c.history.single.jsonCode, '{"b":1}');
      c.dispose();
    });

    test("duplicates collapse, order is newest first, size is capped",
        () async {
      final ConverterController c = create(FakeSettingsService());
      await c.load();
      for (int i = 0; i < 15; i++) {
        c.setJson('{"k$i":1}');
      }
      expect(c.history.length, ConverterController.maxHistoryEntries);
      expect(c.history.first.jsonCode, '{"k13":1}');
      c.setJson('{"k5":1}');
      c.setJson('{"k5":1}');
      c.setJson('{"z":1}');
      expect(
        c.history.where((h) => h.jsonCode == '{"k5":1}'),
        hasLength(1),
      );
      c.dispose();
    });

    test("empty and oversized inputs are not remembered", () async {
      final ConverterController c = create(FakeSettingsService());
      await c.load();
      c.setJson("");
      c.setJson("x" * (ConverterController.maxHistoryChars + 1));
      c.setJson('{"a":1}');
      expect(c.history, isEmpty);
      c.dispose();
    });

    test("clearHistory empties it", () async {
      final FakeSettingsService service = FakeSettingsService();
      final ConverterController c = create(service);
      await c.load();
      c.setJson('{"a":1}');
      c.setJson('{"b":1}');
      c.clearHistory();
      expect(c.history, isEmpty);
      expect(service.history, isEmpty);
      c.dispose();
    });
  });

  group("large input", () {
    test("flags large text and never persists oversized JSON", () async {
      final FakeSettingsService service = FakeSettingsService();
      final ConverterController c = create(service);
      await c.load();
      c.setJson('{"a":1}');
      expect(c.isLargeInput, isFalse);
      c.setJson('{"a":[${List.filled(80000, '"abcdef"').join(",")}]}');
      expect(c.isLargeInput, isTrue);
      expect(c.dartClass, contains("List<String> a"));
      c.setJson(
        '{"a":[${List.filled(ConverterController.maxPersistedChars ~/ 8, '"abcdef"').join(",")}]}',
      );
      expect(service.saved.last.jsonCode, isEmpty);
      c.dispose();
    });
  });
}
