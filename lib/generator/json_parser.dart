class JsonNumber {
  const JsonNumber(this.text, {required this.isInteger});

  final String text;
  final bool isInteger;
}

class JsonParseException implements Exception {
  const JsonParseException(
    this.message, {
    required this.line,
    required this.column,
  });

  final String message;
  final int line;
  final int column;

  @override
  String toString() => "$message at line $line, column $column";
}

/// Parses JSON keeping number literals as written, because compiled-to-JS Dart
/// cannot tell `10` from `10.0` after `jsonDecode`.
class JsonParser {
  JsonParser._(this._text);

  static const int _maxDepth = 256;
  static final RegExp _numberPattern =
      RegExp(r"-?(?:0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?");

  final String _text;
  int _pos = 0;

  static Object? parse(String text) {
    final JsonParser parser = JsonParser._(text).._skipWhitespace();
    final Object? value = parser._parseValue(0);
    parser._skipWhitespace();
    if (parser._pos < text.length) {
      throw parser._error("Unexpected character '${text[parser._pos]}'");
    }
    return value;
  }

  JsonParseException _error(String message) {
    final int offset = _pos.clamp(0, _text.length);
    int line = 1;
    int lineStart = 0;
    for (int i = 0; i < offset; i++) {
      if (_text.codeUnitAt(i) == 0x0A) {
        line++;
        lineStart = i + 1;
      }
    }
    return JsonParseException(
      message,
      line: line,
      column: offset - lineStart + 1,
    );
  }

  JsonParseException _unexpected() => _pos >= _text.length
      ? _error("Unexpected end of input")
      : _error("Unexpected character '${_text[_pos]}'");

  void _skipWhitespace() {
    while (_pos < _text.length) {
      final int c = _text.codeUnitAt(_pos);
      if (c != 0x20 && c != 0x0A && c != 0x0D && c != 0x09) break;
      _pos++;
    }
  }

  void _expect(String char) {
    if (_pos >= _text.length || _text[_pos] != char) throw _unexpected();
    _pos++;
  }

  Object? _parseValue(int depth) {
    if (depth > _maxDepth) throw _error("Nesting is too deep");
    if (_pos >= _text.length) throw _unexpected();
    final String c = _text[_pos];
    switch (c) {
      case "{":
        return _parseObject(depth);
      case "[":
        return _parseArray(depth);
      case '"':
        return _parseString();
      case "t":
        return _parseLiteral("true", true);
      case "f":
        return _parseLiteral("false", false);
      case "n":
        return _parseLiteral("null", null);
      default:
        if (c == "-" || (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39)) {
          return _parseNumber();
        }
        throw _unexpected();
    }
  }

  Object? _parseLiteral(String literal, Object? value) {
    if (!_text.startsWith(literal, _pos)) throw _unexpected();
    _pos += literal.length;
    return value;
  }

  JsonNumber _parseNumber() {
    final Match? match = _numberPattern.matchAsPrefix(_text, _pos);
    if (match == null) throw _error("Invalid number");
    _pos = match.end;
    return JsonNumber(
      match.group(0)!,
      isInteger: match.group(1) == null && match.group(2) == null,
    );
  }

  Map<String, Object?> _parseObject(int depth) {
    final Map<String, Object?> map = {};
    _pos++;
    _skipWhitespace();
    if (_pos < _text.length && _text[_pos] == "}") {
      _pos++;
      return map;
    }
    while (true) {
      _skipWhitespace();
      if (_pos >= _text.length || _text[_pos] != '"') {
        throw _pos >= _text.length ? _unexpected() : _error("Expected a key");
      }
      final String key = _parseString();
      _skipWhitespace();
      _expect(":");
      _skipWhitespace();
      map[key] = _parseValue(depth + 1);
      _skipWhitespace();
      if (_pos < _text.length && _text[_pos] == ",") {
        _pos++;
        continue;
      }
      _expect("}");
      return map;
    }
  }

  List<Object?> _parseArray(int depth) {
    final List<Object?> list = [];
    _pos++;
    _skipWhitespace();
    if (_pos < _text.length && _text[_pos] == "]") {
      _pos++;
      return list;
    }
    while (true) {
      _skipWhitespace();
      list.add(_parseValue(depth + 1));
      _skipWhitespace();
      if (_pos < _text.length && _text[_pos] == ",") {
        _pos++;
        continue;
      }
      _expect("]");
      return list;
    }
  }

  String _parseString() {
    _pos++;
    final StringBuffer buffer = StringBuffer();
    while (true) {
      if (_pos >= _text.length) throw _error("Unterminated string");
      final int c = _text.codeUnitAt(_pos);
      if (c == 0x22) {
        _pos++;
        return buffer.toString();
      }
      if (c < 0x20) throw _error("Invalid control character in string");
      if (c == 0x5C) {
        _parseEscape(buffer);
      } else {
        buffer.writeCharCode(c);
        _pos++;
      }
    }
  }

  void _parseEscape(StringBuffer buffer) {
    _pos++;
    if (_pos >= _text.length) throw _error("Unterminated string");
    final String e = _text[_pos];
    const Map<String, String> simple = {
      '"': '"',
      r"\": r"\",
      "/": "/",
      "b": "\b",
      "f": "\f",
      "n": "\n",
      "r": "\r",
      "t": "\t",
    };
    if (simple.containsKey(e)) {
      buffer.write(simple[e]);
      _pos++;
    } else if (e == "u") {
      final String? hex =
          _pos + 5 <= _text.length ? _text.substring(_pos + 1, _pos + 5) : null;
      final int? code = hex == null ? null : int.tryParse(hex, radix: 16);
      if (code == null) throw _error("Invalid unicode escape");
      buffer.writeCharCode(code);
      _pos += 5;
    } else {
      throw _error("Invalid escape '\\$e'");
    }
  }
}
