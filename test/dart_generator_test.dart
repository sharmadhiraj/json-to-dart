import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/generator/dart_generator.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/generator/json_parser.dart';

String gen(
  String json, {
  String name = "Root",
  GeneratorOptions options = const GeneratorOptions(),
}) =>
    DartGenerator.generate(json, name, options: options);

void main() {
  test("generates primitives with required fields", () {
    final String out = gen('{"name":"a","age":1,"score":1.5,"ok":true}');
    expect(out, contains("final String name;"));
    expect(out, contains("final int age;"));
    expect(out, contains("final double score;"));
    expect(out, contains("final bool ok;"));
    expect(out, contains("required this.name,"));
    expect(out, contains("(json[\"score\"] as num).toDouble()"));
  });

  test("null values become optional dynamic", () {
    final String out = gen('{"a":null}');
    expect(out, contains("final dynamic a;"));
    expect(out, contains("    this.a,"));
    expect(out, isNot(contains("required this.a")));
  });

  test("nested objects are generated once, parent first", () {
    final String out = gen('{"user":{"id":1},"owner":{"user":{"id":2}}}');
    expect(
      "class User".allMatches(out).length,
      1,
    );
    expect(out.indexOf("class Root"), lessThan(out.indexOf("class User")));
  });

  test("list of objects merges elements and marks missing keys nullable", () {
    final String out = gen('{"items":[{"a":1,"b":"x"},{"a":2.5}]}');
    expect(out, contains("final List<Item> items;"));
    expect(out, contains("final double a;"));
    expect(out, contains("final String? b;"));
    expect(out, contains("Item.parseList(json[\"items\"])"));
  });

  test("root array merges all elements", () {
    final String out = gen('[{"a":1},{"a":2,"b":true}]');
    expect(out, contains("final int a;"));
    expect(out, contains("final bool? b;"));
  });

  test("mixed types fall back to dynamic", () {
    final String out = gen('{"a":[1,"x"]}');
    expect(out, contains("final List<dynamic> a;"));
  });

  test("nested lists", () {
    final String out = gen('{"m":[[1,2],[3]]}');
    expect(out, contains("final List<List<int>> m;"));
    expect(out, contains("(e) => (e as List)"));
  });

  test("escapes keys and avoids reserved field names", () {
    final String out = gen(r'{"class":1,"a\"b":2,"$x":3}');
    expect(out, contains("final int classValue;"));
    expect(out, contains(r'json["a\"b"]'));
    expect(out, contains(r'json["\$x"]'));
  });

  test("duplicate sanitized names are deduplicated", () {
    final String out = gen('{"user_id":1,"userId":2}');
    expect(out, contains("final int userId;"));
    expect(out, contains("final int userId2;"));
  });

  test("options toggle methods", () {
    final String out = gen(
      '{"a":1}',
      options: const GeneratorOptions(fromJson: false, toJson: false),
    );
    expect(out, isNot(contains("fromJson")));
    expect(out, isNot(contains("toJson")));
    expect(out, isNot(contains("parseList")));
  });

  test("empty object", () {
    expect(gen("{}"), contains("const Root();"));
  });

  test("whole-number doubles stay double", () {
    final String out = gen('{"price":10.0,"qty":10}');
    expect(out, contains("final double price;"));
    expect(out, contains("final int qty;"));
  });

  test("nested key matching the root name does not merge into the root", () {
    final String out = gen('{"id":1,"data":{"x":1}}', name: "Data");
    expect(out, contains("class Data {"));
    expect(out, contains("class DataModel {"));
    expect(out, contains("final DataModel data;"));
  });

  test("invalid JSON throws a parse exception with position", () {
    expect(() => gen("{"), throwsA(isA<JsonParseException>()));
  });

  test("unsupported roots throw", () {
    expect(() => gen("[]"), throwsA(isA<GeneratorException>()));
    expect(() => gen("[1,2]"), throwsA(isA<GeneratorException>()));
    expect(() => gen("5"), throwsA(isA<GeneratorException>()));
  });

  group("extra options", () {
    test("detectDates maps ISO strings to DateTime", () {
      final String out = gen(
        '{"at":"2024-01-02T10:00:00Z","day":"2024-01-02","name":"x","list":["2024-01-02"]}',
        options: const GeneratorOptions(detectDates: true),
      );
      expect(out, contains("final DateTime at;"));
      expect(out, contains("final DateTime day;"));
      expect(out, contains("final String name;"));
      expect(out, contains('at: DateTime.parse(json["at"] as String)'));
      expect(out, contains('"at": at.toIso8601String()'));
      expect(out, contains("list.map((e) => e.toIso8601String()).toList()"));
    });

    test("dates stay strings when detection is off", () {
      expect(gen('{"at":"2024-01-02"}'), contains("final String at;"));
    });

    test("dates mixed with other strings fall back to String", () {
      final String out = gen(
        '{"l":["2024-01-02","soon"]}',
        options: const GeneratorOptions(detectDates: true),
      );
      expect(out, contains("final List<String> l;"));
    });

    test("allNullable makes every field optional", () {
      final String out = gen(
        '{"a":1,"o":{"b":"x"}}',
        options: const GeneratorOptions(allNullable: true),
      );
      expect(out, contains("final int? a;"));
      expect(out, contains("final O? o;"));
      expect(out, isNot(contains("required")));
      expect(out, contains('o: json["o"] == null ? null : O.fromJson('));
    });

    test("copyWith", () {
      final String out = gen(
        '{"a":1,"b":null}',
        options: const GeneratorOptions(copyWithMethod: true),
      );
      expect(out, contains("Root copyWith({"));
      expect(out, contains("int? a,"));
      expect(out, contains("dynamic b,"));
      expect(out, contains("a: a ?? this.a,"));
    });

    test("equality uses deep equality only when lists exist", () {
      const GeneratorOptions options = GeneratorOptions(equality: true);
      final String plain = gen('{"a":1}', options: options);
      expect(plain, contains("other is Root && other.a == a"));
      expect(plain, contains("Object.hashAll([a])"));
      expect(plain, isNot(contains("package:collection")));
      final String withList = gen('{"a":[1]}', options: options);
      expect(
        withList,
        contains("import 'package:collection/collection.dart';"),
      );
      expect(withList, contains("const DeepCollectionEquality().equals("));
    });

    test("json_serializable delegates to generated code", () {
      final String out = gen(
        '{"user_name":"a","id":1}',
        name: "Account",
        options: const GeneratorOptions(
          jsonSerializable: true,
          fromJson: false,
          toJson: false,
        ),
      );
      expect(
        out,
        contains("import 'package:json_annotation/json_annotation.dart';"),
      );
      expect(out, contains('part "account.g.dart";'));
      expect(out, contains("@JsonSerializable(explicitToJson: true)"));
      expect(out, contains('@JsonKey(name: "user_name")'));
      expect(out, contains(r"_$AccountFromJson(json)"));
      expect(out, contains(r"_$AccountToJson(this)"));
    });
  });
}
