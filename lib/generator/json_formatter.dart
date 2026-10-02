import 'dart:convert';

import 'package:json_to_dart/generator/json_parser.dart';

abstract final class JsonFormatter {
  static String prettify(String text, {String indent = "  "}) {
    final StringBuffer out = StringBuffer();
    _write(JsonParser.parse(text), out, indent, 0);
    return out.toString();
  }

  static void _write(
    Object? value,
    StringBuffer out,
    String indent,
    int level,
  ) {
    final String inner = indent * (level + 1);
    final String outer = indent * level;
    switch (value) {
      case final Map<String, Object?> map when map.isEmpty:
        out.write("{}");
      case final Map<String, Object?> map:
        out.writeln("{");
        int i = 0;
        for (final MapEntry<String, Object?> e in map.entries) {
          out.write("$inner${jsonEncode(e.key)}: ");
          _write(e.value, out, indent, level + 1);
          out.writeln(++i < map.length ? "," : "");
        }
        out.write("$outer}");
      case final List<Object?> list when list.isEmpty:
        out.write("[]");
      case final List<Object?> list:
        out.writeln("[");
        for (int i = 0; i < list.length; i++) {
          out.write(inner);
          _write(list[i], out, indent, level + 1);
          out.writeln(i < list.length - 1 ? "," : "");
        }
        out.write("$outer]");
      case final JsonNumber number:
        out.write(number.text);
      default:
        out.write(jsonEncode(value));
    }
  }
}
