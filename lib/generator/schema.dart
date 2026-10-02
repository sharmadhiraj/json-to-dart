enum JsonKind {
  string,
  integer,
  decimal,
  boolean,
  dateTime,
  object,
  list,
  dynamic,
  // Inference-only kinds, rendered as `dynamic`.
  nullValue,
  unknown,
}

class FieldType {
  const FieldType(
    this.kind, {
    this.nullable = false,
    this.className,
    this.element,
  });

  static const FieldType unknown = FieldType(JsonKind.unknown);
  static const FieldType nullValue =
      FieldType(JsonKind.nullValue, nullable: true);
  static const FieldType dynamicType =
      FieldType(JsonKind.dynamic, nullable: true);

  final JsonKind kind;
  final bool nullable;
  final String? className;
  final FieldType? element;

  bool get isDynamic =>
      kind == JsonKind.dynamic ||
      kind == JsonKind.nullValue ||
      kind == JsonKind.unknown;

  bool get isOptional => nullable || isDynamic;

  FieldType get innermost {
    FieldType current = this;
    while (current.kind == JsonKind.list) {
      current = current.element!;
    }
    return current;
  }

  String get dartType {
    final String base = switch (kind) {
      JsonKind.string => "String",
      JsonKind.integer => "int",
      JsonKind.decimal => "double",
      JsonKind.boolean => "bool",
      JsonKind.dateTime => "DateTime",
      JsonKind.object => className!,
      JsonKind.list => "List<${element!.dartType}>",
      _ => "dynamic",
    };
    return nullable && !isDynamic ? "$base?" : base;
  }

  FieldType asNullable() => FieldType(
        kind,
        nullable: true,
        className: className,
        element: element,
      );

  FieldType mergeWith(FieldType other) {
    if (kind == JsonKind.unknown) return other;
    if (other.kind == JsonKind.unknown) return this;
    if (kind == JsonKind.nullValue) return other.asNullable();
    if (other.kind == JsonKind.nullValue) return asNullable();
    final bool eitherNullable = nullable || other.nullable;
    if (kind == other.kind) {
      if (kind == JsonKind.object && className != other.className) {
        return dynamicType;
      }
      return FieldType(
        kind,
        nullable: eitherNullable,
        className: className,
        element:
            kind == JsonKind.list ? element!.mergeWith(other.element!) : null,
      );
    }
    final Set<JsonKind> kinds = {kind, other.kind};
    if (kinds.containsAll({JsonKind.integer, JsonKind.decimal})) {
      return FieldType(JsonKind.decimal, nullable: eitherNullable);
    }
    if (kinds.containsAll({JsonKind.string, JsonKind.dateTime})) {
      return FieldType(JsonKind.string, nullable: eitherNullable);
    }
    return dynamicType;
  }
}

class Schema {
  const Schema(this.rootName, this.classes);

  final String rootName;
  final Map<String, Map<String, FieldType>> classes;

  /// Classes in depth-first order from the root, each listed once.
  List<String> get orderedClassNames {
    final Set<String> ordered = {};
    void visit(String name) {
      final Map<String, FieldType>? fields = classes[name];
      if (fields == null || !ordered.add(name)) return;
      for (final FieldType type in fields.values) {
        final FieldType leaf = type.innermost;
        if (leaf.kind == JsonKind.object) visit(leaf.className!);
      }
    }

    visit(rootName);
    return ordered.toList();
  }
}
