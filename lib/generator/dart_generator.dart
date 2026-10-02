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

abstract final class DartGenerator {
  /// Throws [JsonParseException] or [GeneratorException] on bad input.
  static String generate(
    String jsonText,
    String className, {
    GeneratorOptions options = const GeneratorOptions(),
  }) {
    final Schema schema = SchemaInferrer.infer(
      Naming.className(className),
      _rootObjects(JsonParser.parse(jsonText)),
      detectDates: options.detectDates,
    );
    final ClassEmitter emitter = ClassEmitter(options);
    final String classes = schema.orderedClassNames
        .map((name) => emitter.emit(name, schema.classes[name]!))
        .join("\n\n");
    final String header = _header(schema, options);
    return header.isEmpty ? classes : "$header\n\n$classes";
  }

  static String _header(Schema schema, GeneratorOptions options) {
    final bool usesDeepEquality = options.equality &&
        schema.classes.values.any(
          (fields) => fields.values.any((t) => t.kind == JsonKind.list),
        );
    return [
      if (options.jsonSerializable)
        "import 'package:json_annotation/json_annotation.dart';",
      if (usesDeepEquality) "import 'package:collection/collection.dart';",
      if (options.jsonSerializable)
        '\npart "${Naming.fileName(schema.rootName)}.g.dart";',
    ].join("\n");
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
