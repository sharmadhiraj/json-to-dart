import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/generator/json_formatter.dart';
import 'package:json_to_dart/generator/json_parser.dart';

JsonParseException parseError(String text) {
  try {
    JsonParser.parse(text);
  } on JsonParseException catch (e) {
    return e;
  }
  fail("Expected a JsonParseException for: $text");
}

void main() {
  group("JsonParser", () {
    test("keeps number literals as written", () {
      final Map<String, Object?> map =
          JsonParser.parse('{"a":10,"b":10.0,"c":1e3,"d":-0.5}')!
              as Map<String, Object?>;
      expect((map["a"]! as JsonNumber).isInteger, isTrue);
      expect((map["b"]! as JsonNumber).isInteger, isFalse);
      expect((map["c"]! as JsonNumber).isInteger, isFalse);
      expect((map["d"]! as JsonNumber).isInteger, isFalse);
      expect((map["b"]! as JsonNumber).text, "10.0");
    });

    test("parses nested values and escapes", () {
      final Object? value = JsonParser.parse(
        r'{"s":"a\n\"A","l":[true,false,null],"o":{}}',
      );
      final Map<String, Object?> map = value! as Map<String, Object?>;
      expect(map["s"], 'a\n"A');
      expect(map["l"], [true, false, null]);
      expect(map["o"], isEmpty);
    });

    test("reports line and column", () {
      final JsonParseException e = parseError('{\n  "a": 1,\n  "b": x\n}');
      expect(e.line, 3);
      expect(e.column, 8);
      expect(e.toString(), contains("line 3, column 8"));
    });

    test("rejects malformed input", () {
      for (final String bad in [
        "",
        "{",
        '{"a":}',
        '{"a" 1}',
        "[1,]",
        '{"a":1,}',
        "01",
        '"abc',
        "tru",
        '{"a":1} x',
        r'"\q"',
      ]) {
        expect(
          () => JsonParser.parse(bad),
          throwsA(isA<JsonParseException>()),
          reason: bad,
        );
      }
    });

    test("limits nesting depth", () {
      final String deep = "[" * 1000 + "]" * 1000;
      expect(parseError(deep).message, contains("too deep"));
    });
  });

  group("JsonFormatter", () {
    test("prettifies and preserves number literals", () {
      expect(
        JsonFormatter.prettify('{"a":[1,2.0],"b":{},"c":[]}'),
        '{\n  "a": [\n    1,\n    2.0\n  ],\n  "b": {},\n  "c": []\n}',
      );
    });
  });
}
