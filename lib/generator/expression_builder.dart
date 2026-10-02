import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/schema.dart';

class ExpressionBuilder {
  const ExpressionBuilder(this.options);

  final GeneratorOptions options;

  static String _suffixed(String name, int depth) =>
      depth == 0 ? name : "$name${depth + 1}";

  static String _itemVariable(int depth) => _suffixed("e", depth);

  static String quote(String value) {
    final String escaped = value
        .replaceAll(r"\", r"\\")
        .replaceAll('"', r'\"')
        .replaceAll(r"$", r"\$")
        .replaceAll("\n", r"\n")
        .replaceAll("\r", r"\r");
    return '"$escaped"';
  }

  String fromJson(FieldType type, String source, [int depth = 0]) {
    final String q = type.nullable ? "?" : "";
    switch (type.kind) {
      case JsonKind.string:
        return "$source as String$q";
      case JsonKind.integer:
        return "$source as int$q";
      case JsonKind.boolean:
        return "$source as bool$q";
      case JsonKind.dateTime:
        return _nullGuard(type, source, "DateTime.parse($source as String)");
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
          _listFromJson(type.element!, source, depth),
        );
      case JsonKind.map:
        return _nullGuard(
          type,
          source,
          _mapFromJson(type.element!, source, depth),
        );
      default:
        return source;
    }
  }

  String _listFromJson(FieldType element, String source, int depth) {
    if (element.isDynamic) return "List<dynamic>.from($source as List)";
    if (element.kind == JsonKind.object &&
        !element.nullable &&
        options.effectiveParseList) {
      return "${element.className}.parseList($source)";
    }
    final String item = _itemVariable(depth);
    final String mapped = fromJson(element, item, depth + 1);
    return "($source as List).map(($item) => $mapped).toList()";
  }

  String _mapFromJson(FieldType element, String source, int depth) {
    if (element.isDynamic) return "Map<String, dynamic>.from($source as Map)";
    final String key = _suffixed("k", depth);
    final String value = _suffixed("v", depth);
    final String mapped = fromJson(element, value, depth + 1);
    return "($source as Map<String, dynamic>).map(($key, $value) => MapEntry($key, $mapped))";
  }

  String toJson(FieldType type, String source, [int depth = 0]) {
    final String q = type.nullable ? "?" : "";
    if (type.kind == JsonKind.object) return "$source$q.toJson()";
    if (type.kind == JsonKind.dateTime) return "$source$q.toIso8601String()";
    if (type.kind == JsonKind.map && _needsConversion(type.innermost)) {
      final String key = _suffixed("k", depth);
      final String value = _suffixed("v", depth);
      final String mapped = toJson(type.element!, value, depth + 1);
      return "$source$q.map(($key, $value) => MapEntry($key, $mapped))";
    }
    if (type.kind == JsonKind.list && _needsConversion(type.innermost)) {
      final String item = _itemVariable(depth);
      final String mapped = toJson(type.element!, item, depth + 1);
      return "$source$q.map(($item) => $mapped).toList()";
    }
    return source;
  }

  static bool _needsConversion(FieldType leaf) =>
      leaf.kind == JsonKind.object || leaf.kind == JsonKind.dateTime;

  static String _nullGuard(FieldType type, String source, String expr) =>
      type.nullable ? "$source == null ? null : $expr" : expr;
}
