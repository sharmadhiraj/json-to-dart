import 'package:json_to_dart/generator/naming.dart';

enum JsonKind {
  string,
  integer,
  decimal,
  boolean,
  nullValue,
  unknown,
  object,
  list,
  dynamic,
}

class FieldType {
  const FieldType(
    this.kind, {
    this.nullable = false,
    this.className,
    this.element,
  });

  final JsonKind kind;
  final bool nullable;
  final String? className;
  final FieldType? element;

  bool get isDynamic =>
      kind == JsonKind.dynamic ||
      kind == JsonKind.nullValue ||
      kind == JsonKind.unknown;

  bool get isOptional => nullable || isDynamic;

  FieldType asNullable() => FieldType(
        kind,
        nullable: true,
        className: className,
        element: element,
      );
}

class SchemaInferrer {
  final Map<String, Map<String, FieldType>> classes = {};

  FieldType infer(Object? value, String name) {
    if (value == null) return const FieldType(JsonKind.nullValue, nullable: true);
    if (value is String) return const FieldType(JsonKind.string);
    if (value is int) return const FieldType(JsonKind.integer);
    if (value is double) return const FieldType(JsonKind.decimal);
    if (value is bool) return const FieldType(JsonKind.boolean);
    if (value is Map) {
      final String className = Naming.className(name);
      _registerClass(className, _inferFields(value));
      return FieldType(JsonKind.object, className: className);
    }
    if (value is List) {
      FieldType element = const FieldType(JsonKind.unknown);
      for (final Object? item in value) {
        element = _merge(element, infer(item, name));
      }
      return FieldType(JsonKind.list, element: element);
    }
    return const FieldType(JsonKind.dynamic, nullable: true);
  }

  void registerRoot(String className, Map<Object?, Object?> json) {
    _registerClass(className, _inferFields(json));
  }

  Map<String, FieldType> _inferFields(Map<Object?, Object?> json) => {
        for (final MapEntry<Object?, Object?> e in json.entries)
          e.key.toString(): infer(e.value, e.key.toString()),
      };

  void _registerClass(String name, Map<String, FieldType> fields) {
    final Map<String, FieldType>? existing = classes[name];
    if (existing == null) {
      classes[name] = fields;
      return;
    }
    final Map<String, FieldType> merged = {};
    for (final MapEntry<String, FieldType> e in existing.entries) {
      final FieldType? other = fields[e.key];
      merged[e.key] = other == null ? e.value.asNullable() : _merge(e.value, other);
    }
    for (final MapEntry<String, FieldType> e in fields.entries) {
      merged.putIfAbsent(e.key, e.value.asNullable);
    }
    classes[name] = merged;
  }

  FieldType _merge(FieldType a, FieldType b) {
    if (a.kind == JsonKind.unknown) return b;
    if (b.kind == JsonKind.unknown) return a;
    if (a.kind == JsonKind.nullValue) return b.asNullable();
    if (b.kind == JsonKind.nullValue) return a.asNullable();
    final bool nullable = a.nullable || b.nullable;
    if (a.kind == b.kind) {
      if (a.kind == JsonKind.list) {
        return FieldType(
          JsonKind.list,
          nullable: nullable,
          element: _merge(a.element!, b.element!),
        );
      }
      if (a.kind == JsonKind.object && a.className != b.className) {
        return const FieldType(JsonKind.dynamic, nullable: true);
      }
      return FieldType(
        a.kind,
        nullable: nullable,
        className: a.className,
      );
    }
    final Set<JsonKind> kinds = {a.kind, b.kind};
    if (kinds.length == 2 &&
        kinds.contains(JsonKind.integer) &&
        kinds.contains(JsonKind.decimal)) {
      return FieldType(JsonKind.decimal, nullable: nullable);
    }
    return const FieldType(JsonKind.dynamic, nullable: true);
  }
}
