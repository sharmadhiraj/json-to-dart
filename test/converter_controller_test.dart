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

  @override
  Future<AppSettings> load() async => initial;

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
}
