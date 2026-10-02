@TestOn("vm")
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/generator/dart_generator.dart';
import 'package:json_to_dart/generator/generator_options.dart';

const Map<String, GeneratorOptions> _variants = {
  "default": GeneratorOptions(),
  "style": GeneratorOptions(
    snakeCaseFields: true,
    mutableFields: true,
    numericStrings: true,
  ),
  "full": GeneratorOptions(
    copyWithMethod: true,
    equality: true,
    detectDates: true,
    allNullable: true,
  ),
};

const String _pubspec = """
name: generated_check
environment:
  sdk: ">=3.2.3 <4.0.0"
dependencies:
  collection: any
""";

void main() {
  final bool update = Platform.environment["UPDATE_GOLDENS"] == "1";
  final List<File> inputs = Directory("test/golden")
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith(".json"))
      .toList();

  for (final File input in inputs) {
    final String name = input.uri.pathSegments.last.replaceAll(".json", "");
    for (final MapEntry<String, GeneratorOptions> variant
        in _variants.entries) {
      final String label = "$name (${variant.key})";

      test("golden: $label", () {
        final String actual =
            "${DartGenerator.generate(input.readAsStringSync(), "Root", options: variant.value)}\n";
        final File golden = File("test/golden/$name.${variant.key}.dart.txt");
        if (update) golden.writeAsStringSync(actual);
        expect(actual, golden.readAsStringSync());
      });

      test("generated code analyzes cleanly: $label", () async {
        final Directory temp = Directory.systemTemp.createTempSync("j2d");
        addTearDown(() => temp.deleteSync(recursive: true));
        File("${temp.path}/pubspec.yaml").writeAsStringSync(_pubspec);
        Directory("${temp.path}/lib").createSync();
        File("${temp.path}/lib/generated.dart").writeAsStringSync(
          DartGenerator.generate(
            input.readAsStringSync(),
            "Root",
            options: variant.value,
          ),
        );
        final ProcessResult pub = await Process.run(
          "dart",
          ["pub", "get", "--offline"],
          workingDirectory: temp.path,
        );
        expect(pub.exitCode, 0, reason: "${pub.stdout}${pub.stderr}");
        final ProcessResult result = await Process.run(
          "dart",
          ["analyze", "--fatal-infos"],
          workingDirectory: temp.path,
        );
        expect(result.exitCode, 0, reason: "${result.stdout}${result.stderr}");
      });
    }
  }
}
