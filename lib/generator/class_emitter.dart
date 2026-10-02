import 'package:json_to_dart/generator/expression_builder.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/naming.dart';
import 'package:json_to_dart/generator/schema.dart';

class ClassEmitter {
  ClassEmitter(this.options) : _expressions = ExpressionBuilder(options);

  final GeneratorOptions options;
  final ExpressionBuilder _expressions;

  String emit(String className, Map<String, FieldType> parsedFields) {
    final Map<String, FieldType> fields = options.allNullable
        ? {for (final e in parsedFields.entries) e.key: e.value.asNullable()}
        : parsedFields;
    final Map<String, String> names = _fieldNames(fields.keys);
    final String finalKeyword = options.mutableFields ? "" : "final ";
    final StringBuffer out = StringBuffer()..writeln("class $className {");
    for (final MapEntry<String, FieldType> f in fields.entries) {
      out.writeln("  $finalKeyword${f.value.dartType} ${names[f.key]};");
    }
    out.writeln();
    _writeConstructor(out, className, fields, names);
    if (options.fromJson) _writeFromJson(out, className, fields, names);
    if (options.toJson) _writeToJson(out, fields, names);
    if (options.effectiveParseList) _writeParseList(out, className);
    if (options.copyWithMethod && fields.isNotEmpty) {
      _writeCopyWith(out, className, fields, names);
    }
    if (options.equality) _writeEquality(out, className, fields, names);
    out.write("}");
    return out.toString();
  }

  void _writeConstructor(
    StringBuffer out,
    String className,
    Map<String, FieldType> fields,
    Map<String, String> names,
  ) {
    final String constKeyword = options.mutableFields ? "" : "const ";
    if (fields.isEmpty) {
      out.writeln("  $constKeyword$className();");
      return;
    }
    out.writeln("  $constKeyword$className({");
    for (final MapEntry<String, FieldType> f in fields.entries) {
      final String prefix = f.value.isOptional ? "" : "required ";
      out.writeln("    ${prefix}this.${names[f.key]},");
    }
    out.writeln("  });");
  }

  void _writeFromJson(
    StringBuffer out,
    String className,
    Map<String, FieldType> fields,
    Map<String, String> names,
  ) {
    out
      ..writeln()
      ..writeln("  factory $className.fromJson(Map<String, dynamic> json) {")
      ..writeln("    return $className(");
    for (final MapEntry<String, FieldType> f in fields.entries) {
      final String source = "json[${ExpressionBuilder.quote(f.key)}]";
      out.writeln(
        "      ${names[f.key]}: ${_expressions.fromJson(f.value, source)},",
      );
    }
    out
      ..writeln("    );")
      ..writeln("  }");
  }

  void _writeToJson(
    StringBuffer out,
    Map<String, FieldType> fields,
    Map<String, String> names,
  ) {
    out
      ..writeln()
      ..writeln("  Map<String, dynamic> toJson() {")
      ..writeln("    return {");
    for (final MapEntry<String, FieldType> f in fields.entries) {
      out.writeln(
        "      ${ExpressionBuilder.quote(f.key)}: ${_expressions.toJson(f.value, names[f.key]!)},",
      );
    }
    out
      ..writeln("    };")
      ..writeln("  }");
  }

  void _writeParseList(StringBuffer out, String className) {
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

  void _writeCopyWith(
    StringBuffer out,
    String className,
    Map<String, FieldType> fields,
    Map<String, String> names,
  ) {
    out
      ..writeln()
      ..writeln("  $className copyWith({");
    for (final MapEntry<String, FieldType> f in fields.entries) {
      final String type = f.value.dartType;
      final String optional =
          type.endsWith("?") || f.value.isDynamic ? type : "$type?";
      out.writeln("    $optional ${names[f.key]},");
    }
    out
      ..writeln("  }) {")
      ..writeln("    return $className(");
    for (final String name in names.values) {
      out.writeln("      $name: $name ?? this.$name,");
    }
    out
      ..writeln("    );")
      ..writeln("  }");
  }

  void _writeEquality(
    StringBuffer out,
    String className,
    Map<String, FieldType> fields,
    Map<String, String> names,
  ) {
    const String deepEquality = "const DeepCollectionEquality()";
    final List<String> comparisons = [];
    final List<String> hashes = [];
    for (final MapEntry<String, FieldType> f in fields.entries) {
      final String name = names[f.key]!;
      if (f.value.isCollection) {
        comparisons.add("$deepEquality.equals(other.$name, $name)");
        hashes.add("$deepEquality.hash($name)");
      } else {
        comparisons.add("other.$name == $name");
        hashes.add(name);
      }
    }
    out
      ..writeln()
      ..writeln("  @override")
      ..writeln("  bool operator ==(Object other) {")
      ..writeln("    if (identical(this, other)) return true;")
      ..writeln(
        "    return other is $className${comparisons.map((c) => " && $c").join()};",
      )
      ..writeln("  }")
      ..writeln()
      ..writeln("  @override")
      ..writeln(
        hashes.isEmpty
            ? "  int get hashCode => runtimeType.hashCode;"
            : "  int get hashCode => Object.hashAll([${hashes.join(", ")}]);",
      );
  }

  Map<String, String> _fieldNames(Iterable<String> keys) {
    final Map<String, String> names = {};
    final Set<String> used = {};
    for (final String key in keys) {
      final String base =
          Naming.fieldName(key, snakeCase: options.snakeCaseFields);
      String name = base;
      int suffix = 2;
      while (!used.add(name)) {
        name = "$base${suffix++}";
      }
      names[key] = name;
    }
    return names;
  }
}
