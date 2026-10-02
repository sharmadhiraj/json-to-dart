import 'package:json_to_dart/generator/class_emitter.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/json_parser.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/generator/schema.dart';
import 'package:json_to_dart/generator/schema_inferrer.dart';

class GeneratorException implements Exception {
  const GeneratorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeneratedClass {
  const GeneratedClass({required this.original, required this.name});

  final String original;
  final String name;
}

class GenerationResult {
  const GenerationResult(this.code, this.nestedClasses);

  final String code;

  /// Every generated class except the root, in output order.
  final List<GeneratedClass> nestedClasses;
}

abstract final class DartGenerator {
  /// Throws [JsonParseException] or [GeneratorException] on bad input.
  static String generate(
    String jsonText,
    String className, {
    GeneratorOptions options = const GeneratorOptions(),
  }) =>
      generateResult(jsonText, className, options: options).code;

  static GenerationResult generateResult(
    String jsonText,
    String className, {
    GeneratorOptions options = const GeneratorOptions(),
  }) {
    final Schema schema = SchemaInferrer.infer(
      Naming.className(className),
      _rootObjects(JsonParser.parse(jsonText)),
      options,
    );
    final ClassEmitter emitter = ClassEmitter(options);
    final List<String> names = schema.orderedClassNames;
    final String classes = names
        .map((name) => emitter.emit(name, schema.classes[name]!))
        .join("\n\n");
    final String header = _header(schema, options);
    return GenerationResult(
      header.isEmpty ? classes : "$header\n\n$classes",
      [
        for (final String name in names)
          if (name != schema.rootName)
            GeneratedClass(
              original: schema.originalNames[name] ?? name,
              name: name,
            ),
      ],
    );
  }

  static String _header(Schema schema, GeneratorOptions options) {
    final bool usesDeepEquality = options.equality &&
        schema.classes.values.any(
          (fields) => fields.values.any((t) => t.isCollection),
        );
    return usesDeepEquality
        ? "import 'package:collection/collection.dart';"
        : "";
  }

  static List<Map<String, Object?>> _rootObjects(Object? json) {
    if (json is Map<String, Object?>) return [json];
    if (json is! List<Object?>) {
      throw const GeneratorException(
        "The JSON root must be an object or array.",
      );
    }
    if (json.isEmpty) {
      throw const GeneratorException("The JSON array is empty.");
    }
    if (json.any((item) => item is! Map<String, Object?>)) {
      throw const GeneratorException(
        "The JSON array must contain only objects.",
      );
    }
    return json.cast<Map<String, Object?>>();
  }
}
