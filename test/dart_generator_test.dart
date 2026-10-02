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
  });

  group("maps", () {
    test("dynamic-looking keys become Map<String, T> with merged values", () {
      final String out = gen(
        '{"scores":{"2024-01":{"v":1},"2024-02":{"v":2,"w":"x"}}}',
      );
      expect(out, contains("final Map<String, Score> scores;"));
      expect(out, contains("class Score {"));
      expect(out, contains("final String? w;"));
      expect(out, contains("(json[\"scores\"] as Map<String, dynamic>)"));
      expect(out, contains(".map((k, v) => MapEntry(k, Score.fromJson("));
      expect(out, contains("scores.map((k, v) => MapEntry(k, v.toJson()))"));
    });

    test("numeric and uuid keys are detected", () {
      expect(gen('{"a":{"1":1,"2":2}}'), contains("Map<String, int> a;"));
      expect(
        gen('{"a":{"123e4567-e89b-12d3-a456-426614174000":"x","123e4567-e89b-12d3-a456-426614174001":"y"}}'),
        contains("Map<String, String> a;"),
      );
    });

    test("regular keys and single keys stay classes", () {
      expect(gen('{"a":{"name":1,"city":2}}'), contains("class A {"));
      expect(gen('{"a":{"1":1}}'), contains("class A {"));
    });

    test("detection can be disabled", () {
      final String out = gen(
        '{"a":{"1":1,"2":2}}',
        options: const GeneratorOptions(detectMaps: false),
      );
      expect(out, contains("class A {"));
    });

    test("primitive map values need no conversion", () {
      final String out = gen('{"a":{"u1":[1],"u2":[2]}}');
      expect(out, contains("final Map<String, List<int>> a;"));
      expect(out, contains('"a": a,'));
    });

    test("empty object becomes Map<String, dynamic>", () {
      final String out = gen('{"meta":{}}');
      expect(out, contains("final Map<String, dynamic> meta;"));
      expect(out, contains('Map<String, dynamic>.from(json["meta"] as Map)'));
      expect(out, isNot(contains("class Meta")));
    });

    test("empty object merges into a populated sibling", () {
      final String out = gen('{"l":[{"m":{}},{"m":{"x":1}}]}');
      expect(out, contains("final M m;"));
      expect(out, contains("class M {"));
    });

    test("map field equality uses deep equality", () {
      final String out = gen(
        '{"a":{"1":1,"2":2}}',
        options: const GeneratorOptions(equality: true),
      );
      expect(out, contains("DeepCollectionEquality().equals"));
      expect(out, contains("package:collection"));
    });
  });

  group("class renames", () {
    test("rename applies to the class and every reference", () {
      final String out = gen(
        '{"user":{"id":1},"owner":{"user":{"id":2}}}',
        options: const GeneratorOptions(classRenames: {"User": "Account"}),
      );
      expect(out, contains("class Account {"));
      expect(out, contains("final Account user;"));
      expect(out, isNot(contains("class User")));
    });

    test("result lists nested classes with original names", () {
      final GenerationResult result = DartGenerator.generateResult(
        '{"user":{"id":1},"items":[{"a":1}]}',
        "Root",
        options: const GeneratorOptions(classRenames: {"Item": "Entry"}),
      );
      expect(
        result.nestedClasses.map((c) => "${c.original}>${c.name}"),
        ["User>User", "Item>Entry"],
      );
    });

    test("renames are sanitized into valid class names", () {
      final String out = gen(
        '{"user":{"id":1}}',
        options: const GeneratorOptions(classRenames: {"User": "my account"}),
      );
      expect(out, contains("class MyAccount {"));
    });
  });

  group("numeric strings", () {
    const GeneratorOptions on = GeneratorOptions(numericStrings: true);

    test("quoted numbers become int and double", () {
      final String out =
          gen('{"qty":"42","price":"12.50","name":"x"}', options: on);
      expect(out, contains("final int qty;"));
      expect(out, contains("final double price;"));
      expect(out, contains("final String name;"));
      expect(out, contains('qty: int.parse(json["qty"].toString())'));
      expect(out, contains('price: double.parse(json["price"].toString())'));
      expect(out, contains('"qty": qty.toString()'));
      expect(out, contains('"price": price.toString()'));
    });

    test("is off by default", () {
      expect(gen('{"qty":"42"}'), contains("final String qty;"));
    });

    test("leading zeros and long digit runs stay strings", () {
      final String out = gen(
        '{"zip":"02134","phone":"0412345678","big":"12345678901234567890"}',
        options: on,
      );
      expect(out, contains("final String zip;"));
      expect(out, contains("final String phone;"));
      expect(out, contains("final String big;"));
    });

    test("numeric strings mixed with real numbers or text fall back", () {
      expect(gen('{"l":["1",2]}', options: on), contains("List<dynamic> l;"));
      expect(gen('{"l":["1","a"]}', options: on), contains("List<dynamic> l;"));
    });

    test("ints and decimals as strings merge to double", () {
      expect(
        gen('{"l":["1","2.5"]}', options: on),
        contains("List<double> l;"),
      );
    });

    test("nullable and list forms", () {
      final String out = gen('{"a":[{"n":"1"},{}],"l":["1","2"]}', options: on);
      expect(out, contains("final int? n;"));
      expect(
        out,
        contains(
          'n: json["n"] == null ? null : int.parse(json["n"].toString())',
        ),
      );
      expect(out, contains("l.map((e) => e.toString()).toList()"));
    });

    test("dates win over numeric detection", () {
      final String out = gen(
        '{"d":"2024-01-02"}',
        options:
            const GeneratorOptions(numericStrings: true, detectDates: true),
      );
      expect(out, contains("final DateTime d;"));
    });
  });

  group("field style", () {
    test("snake_case keeps readable snake names", () {
      final String out = gen(
        '{"user_name":"a","userID":1,"2fa":true,"class":1}',
        options: const GeneratorOptions(snakeCaseFields: true),
      );
      expect(out, contains("final String user_name;"));
      expect(out, contains("final int user_id;"));
      expect(out, contains("final bool a_2_fa;"));
      expect(out, contains("final int class_value;"));
      expect(out, contains('user_name: json["user_name"] as String'));
    });

    test("mutable fields drop final and const", () {
      final String out = gen(
        '{"a":1,"o":{"b":2}}',
        options: const GeneratorOptions(mutableFields: true),
      );
      expect(out, contains("  int a;"));
      expect(out, isNot(contains("final")));
      expect(out, contains("  Root({"));
      expect(out, isNot(contains("const ")));
      expect(
        gen("{}", options: const GeneratorOptions(mutableFields: true)),
        contains("Root();"),
      );
    });
  });

  group("merging", () {
    test("maps inside lists merge their values", () {
      final String out =
          gen('{"l":[{"x":{"1":1,"2":2}},{"x":{"3":"a","4":"b"}}]}');
      expect(out, contains("final Map<String, dynamic> x;"));
      final String same =
          gen('{"l":[{"x":{"1":1,"2":2}},{"x":{"3":3,"4":4}}]}');
      expect(same, contains("final Map<String, int> x;"));
    });

    test("an empty object among objects makes all fields optional", () {
      final String out = gen('{"l":[{"a":1},{}]}');
      expect(out, contains("final int? a;"));
      expect(out, contains("final List<L> l;"));
    });
  });
}
