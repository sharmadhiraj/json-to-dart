import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/json_parser.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/generator/schema.dart';

class SchemaInferrer {
  SchemaInferrer._(this._rootName, this._options);

  static final RegExp _isoDate = RegExp(
    r"^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$",
  );

  static final RegExp _dynamicKey = RegExp(
    r"^(\d+|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\d{4}[-/]\d{2}([-/]\d{2})?([T ].*)?|[0-9a-fA-F]{12,}|[A-Za-z]{1,4}[-_]?\d+)$",
  );

  final String _rootName;
  final GeneratorOptions _options;
  final Map<String, Map<String, FieldType>> _classes = {};
  final Map<String, String> _originalNames = {};

  static Schema infer(
    String rootName,
    List<Map<String, Object?>> roots,
    GeneratorOptions options,
  ) {
    final SchemaInferrer inferrer = SchemaInferrer._(rootName, options);
    for (final Map<String, Object?> root in roots) {
      inferrer._registerClass(rootName, inferrer._inferFields(root));
    }
    return Schema(rootName, inferrer._classes, inferrer._originalNames);
  }

  FieldType _infer(Object? value, String key, {bool inList = false}) {
    switch (value) {
      case null:
        return FieldType.nullValue;
      case final String text:
        return FieldType(
          _options.detectDates && _isoDate.hasMatch(text)
              ? JsonKind.dateTime
              : JsonKind.string,
        );
      case bool():
        return const FieldType(JsonKind.boolean);
      case final JsonNumber number:
        return FieldType(
          number.isInteger ? JsonKind.integer : JsonKind.decimal,
        );
      case final Map<String, Object?> map when map.isEmpty:
        return const FieldType(JsonKind.map, element: FieldType.unknown);
      case final Map<String, Object?> map
          when _options.detectMaps && _hasDynamicKeys(map):
        FieldType element = FieldType.unknown;
        for (final Object? item in map.values) {
          element = element.mergeWith(_infer(item, key, inList: true));
        }
        return FieldType(JsonKind.map, element: element);
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

  bool _hasDynamicKeys(Map<String, Object?> map) =>
      map.length >= 2 && map.keys.every(_dynamicKey.hasMatch);

  String _nestedClassName(String key, {required bool singular}) {
    final String generated =
        Naming.className(singular ? Naming.singular(key) : key);
    final String original =
        generated == _rootName ? "${generated}Model" : generated;
    final String? custom = _options.classRenames[original];
    final String name = custom == null ? original : Naming.className(custom);
    _originalNames.putIfAbsent(name, () => original);
    return name;
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
