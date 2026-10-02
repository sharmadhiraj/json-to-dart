import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/generator/schema.dart';

class GeneratorException implements Exception {
  const GeneratorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DartGenerator {
  const DartGenerator._();

  static String generate(
    Object? json,
    String className, {
    GeneratorOptions options = const GeneratorOptions(),
  }) {
    final String rootName = Naming.className(className);
    final SchemaInferrer inferrer = SchemaInferrer();
    for (final Map<Object?, Object?> item in _rootObjects(json)) {
      inferrer.registerRoot(rootName, item);
    }
    return _orderedClassNames(rootName, inferrer.classes)
        .map((name) => _generateClass(name, inferrer.classes[name]!, options))
        .join("\n\n");
  }

  static List<Map<Object?, Object?>> _rootObjects(Object? json) {
    if (json is Map) return [json];
    if (json is List) {
      if (json.isEmpty) {
        throw const GeneratorException("The JSON array is empty.");
      }
      if (json.any((item) => item is! Map)) {
        throw const GeneratorException(
          "The JSON array must contain only objects.",
        );
      }
      return json.cast<Map<Object?, Object?>>();
    }
    throw const GeneratorException("The JSON root must be an object or array.");
  }

  static List<String> _orderedClassNames(
    String root,
    Map<String, Map<String, FieldType>> classes,
  ) {
    final List<String> ordered = [];
    void visit(String name) {
      if (ordered.contains(name) || !classes.containsKey(name)) return;
      ordered.add(name);
      for (final FieldType type in classes[name]!.values) {
        FieldType? current = type;
        while (current != null && current.kind == JsonKind.list) {
          current = current.element;
        }
        if (current != null && current.kind == JsonKind.object) {
          visit(current.className!);
        }
      }
    }

    visit(root);
    return ordered;
  }

  static String _generateClass(
    String className,
    Map<String, FieldType> fields,
    GeneratorOptions options,
  ) {
    final Map<String, String> names = _fieldNames(fields.keys);
    final StringBuffer out = StringBuffer()..writeln("class $className {");

    for (final MapEntry<String, FieldType> f in fields.entries) {
      out.writeln("  final ${_dartType(f.value)} ${names[f.key]};");
    }

    out.writeln();
    if (fields.isEmpty) {
      out.writeln("  const $className();");
    } else {
      out.writeln("  const $className({");
      for (final MapEntry<String, FieldType> f in fields.entries) {
        final String prefix = f.value.isOptional ? "" : "required ";
        out.writeln("    ${prefix}this.${names[f.key]},");
      }
      out.writeln("  });");
    }

    if (options.fromJson) {
      out
        ..writeln()
        ..writeln("  factory $className.fromJson(Map<String, dynamic> json) {")
        ..writeln("    return $className(");
      for (final MapEntry<String, FieldType> f in fields.entries) {
        final String source = "json[${_quote(f.key)}]";
        out.writeln(
          "      ${names[f.key]}: ${_fromJsonExpr(f.value, source, options)},",
        );
      }
      out
        ..writeln("    );")
        ..writeln("  }");
    }

    if (options.toJson) {
      out
        ..writeln()
        ..writeln("  Map<String, dynamic> toJson() {")
        ..writeln("    return {");
      for (final MapEntry<String, FieldType> f in fields.entries) {
        out.writeln(
          "      ${_quote(f.key)}: ${_toJsonExpr(f.value, names[f.key]!)},",
        );
      }
      out
        ..writeln("    };")
        ..writeln("  }");
    }

    if (options.effectiveParseList) {
      out
        ..writeln()
        ..writeln("  static List<$className> parseList(dynamic list) {")
        ..writeln("    if (list is! List) {")
        ..writeln("      return [];")
        ..writeln("    }")
        ..writeln(
          "    return list.map((e) => $className.fromJson(e as Map<String, dynamic>)).toList();",
        )
        ..writeln("  }");
    }

    out.write("}");
    return out.toString();
  }

  static Map<String, String> _fieldNames(Iterable<String> keys) {
    final Map<String, String> names = {};
    final Set<String> used = {};
    for (final String key in keys) {
      final String base = Naming.fieldName(key);
      String name = base;
      int suffix = 2;
      while (!used.add(name)) {
        name = "$base${suffix++}";
      }
      names[key] = name;
    }
    return names;
  }

  static String _dartType(FieldType type) {
    final String base = switch (type.kind) {
      JsonKind.string => "String",
      JsonKind.integer => "int",
      JsonKind.decimal => "double",
      JsonKind.boolean => "bool",
      JsonKind.object => type.className!,
      JsonKind.list => "List<${_dartType(type.element!)}>",
      _ => "dynamic",
    };
    return type.nullable && !type.isDynamic ? "$base?" : base;
  }

  static String _fromJsonExpr(
    FieldType type,
    String source,
    GeneratorOptions options, [
    int depth = 0,
  ]) {
    final String q = type.nullable ? "?" : "";
    switch (type.kind) {
      case JsonKind.string:
        return "$source as String$q";
      case JsonKind.integer:
        return "$source as int$q";
      case JsonKind.boolean:
        return "$source as bool$q";
      case JsonKind.decimal:
        return type.nullable
            ? "($source as num?)?.toDouble()"
            : "($source as num).toDouble()";
      case JsonKind.object:
        return _nullGuard(
          type,
          source,
          "${type.className}.fromJson($source as Map<String, dynamic>)",
        );
      case JsonKind.list:
        return _nullGuard(
          type,
          source,
          _listFromJson(type.element!, source, options, depth),
        );
      default:
        return source;
    }
  }

  static String _listFromJson(
    FieldType element,
    String source,
    GeneratorOptions options,
    int depth,
  ) {
    if (element.isDynamic) return "List<dynamic>.from($source as List)";
    if (element.kind == JsonKind.object &&
        !element.nullable &&
        options.effectiveParseList) {
      return "${element.className}.parseList($source)";
    }
    final String item = depth == 0 ? "e" : "e${depth + 1}";
    final String mapped = _fromJsonExpr(element, item, options, depth + 1);
    return "($source as List).map(($item) => $mapped).toList()";
  }

  static String _nullGuard(FieldType type, String source, String expr) =>
      type.nullable ? "$source == null ? null : $expr" : expr;

  static bool _needsToJson(FieldType type) =>
      type.kind == JsonKind.object ||
      (type.kind == JsonKind.list && _needsToJson(type.element!));

  static String _toJsonExpr(FieldType type, String source, [int depth = 0]) {
    final String q = type.nullable ? "?" : "";
    if (type.kind == JsonKind.object) return "$source$q.toJson()";
    if (type.kind == JsonKind.list && _needsToJson(type.element!)) {
      final String item = depth == 0 ? "e" : "e${depth + 1}";
      final String mapped = _toJsonExpr(type.element!, item, depth + 1);
      return "$source$q.map(($item) => $mapped).toList()";
    }
    return source;
  }

  static String _quote(String value) {
    final String escaped = value
        .replaceAll(r"\", r"\\")
        .replaceAll('"', r'\"')
        .replaceAll(r"$", r"\$")
        .replaceAll("\n", r"\n")
        .replaceAll("\r", r"\r");
    return '"$escaped"';
  }
}
