import 'package:json_to_dart/generator/json_parser.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/generator/schema.dart';

class SchemaInferrer {
  SchemaInferrer._(this._rootName, this._detectDates);

  static final RegExp _isoDate = RegExp(
    r"^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$",
  );

  final String _rootName;
  final bool _detectDates;
  final Map<String, Map<String, FieldType>> _classes = {};

  static Schema infer(
    String rootName,
    List<Map<String, Object?>> roots, {
    bool detectDates = false,
  }) {
    final SchemaInferrer inferrer = SchemaInferrer._(rootName, detectDates);
    for (final Map<String, Object?> root in roots) {
      inferrer._registerClass(rootName, inferrer._inferFields(root));
    }
    return Schema(rootName, inferrer._classes);
  }

  FieldType _infer(Object? value, String key, {bool inList = false}) {
    switch (value) {
      case null:
        return FieldType.nullValue;
      case final String text:
        return FieldType(
          _detectDates && _isoDate.hasMatch(text)
              ? JsonKind.dateTime
              : JsonKind.string,
        );
      case bool():
        return const FieldType(JsonKind.boolean);
      case final JsonNumber number:
        return FieldType(
          number.isInteger ? JsonKind.integer : JsonKind.decimal,
        );
      case final Map<String, Object?> map:
        final String className = _nestedClassName(key, singular: inList);
        _registerClass(className, _inferFields(map));
        return FieldType(JsonKind.object, className: className);
      case final List<Object?> list:
        FieldType element = FieldType.unknown;
        for (final Object? item in list) {
          element = element.mergeWith(_infer(item, key, inList: true));
        }
        return FieldType(JsonKind.list, element: element);
      default:
        return FieldType.dynamicType;
    }
  }

  Map<String, FieldType> _inferFields(Map<String, Object?> json) => {
        for (final MapEntry<String, Object?> e in json.entries)
          e.key: _infer(e.value, e.key),
      };

  String _nestedClassName(String key, {required bool singular}) {
    final String name = Naming.className(singular ? Naming.singular(key) : key);
    return name == _rootName ? "${name}Model" : name;
  }

  void _registerClass(String name, Map<String, FieldType> fields) {
    final Map<String, FieldType>? existing = _classes[name];
    if (existing == null) {
      _classes[name] = fields;
      return;
    }
    final Map<String, FieldType> merged = {
      for (final MapEntry<String, FieldType> e in existing.entries)
        e.key: fields.containsKey(e.key)
            ? e.value.mergeWith(fields[e.key]!)
            : e.value.asNullable(),
    };
    for (final MapEntry<String, FieldType> e in fields.entries) {
      merged.putIfAbsent(e.key, e.value.asNullable);
    }
    _classes[name] = merged;
  }
}
