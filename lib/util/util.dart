import 'dart:convert';

import 'package:web/web.dart' as web;
// import 'dart:html' as html;

class Util {
  static bool checkIfValidJsonString(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String generateDartClass(String jsonString, String className) {
    try {
      dynamic jsonData = jsonDecode(jsonString);
      if (jsonData is Map<String, dynamic>) {
        final Map<String, Map<String, dynamic>> nestedMaps =
            _extractNestedMapFromMap(className, jsonData);
        return nestedMaps.entries
            .map((entry) => _generateClassFromMap(entry.value, entry.key))
            .join("\n\n");
      } else if (jsonData is List) {
        if (jsonData.isNotEmpty) {
          return generateDartClass(jsonEncode(jsonData[0]), className);
        }
      }
    } catch (_) {}
    return "";
  }

  static Map<String, Map<String, dynamic>> _extractNestedMapFromMap(
    String className,
    Map<String, dynamic> map,
  ) {
    final Map<String, Map<String, dynamic>> nestedMaps = {};
    nestedMaps[_convertToValidClassName(className)] = map;
    map.forEach(
      (key, value) {
        if (value is Map<String, dynamic>) {
          nestedMaps.addAll(
            _extractNestedMapFromMap(key, value),
          );
        } else if (value is List &&
            value.isNotEmpty &&
            value.first is Map<String, dynamic>) {
          nestedMaps.addAll(
            _extractNestedMapFromMap(key, value.first),
          );
        }
      },
    );
    return nestedMaps;
  }

  static String _generateClassFromMap(
    Map<String, dynamic> jsonMap,
    String className,
  ) {
    StringBuffer classBuffer = StringBuffer();
    className = getClassName(className);

    classBuffer.writeln("class $className {");
    jsonMap.forEach((key, value) => classBuffer.writeln(
        " final ${_getDartType(key, value)} ${_convertToValidVariableName(key)};"));
    classBuffer.writeln("");

    classBuffer.writeln("const $className({");
    jsonMap.forEach((key, value) => classBuffer
        .writeln("   required this.${_convertToValidVariableName(key)},"));
    classBuffer.writeln(" });");
    classBuffer.writeln("");

    classBuffer
        .writeln(" factory $className.fromJson(Map<String, dynamic> json) {");
    classBuffer.writeln("   return $className(");
    jsonMap.forEach((key, value) {
      classBuffer.writeln(
          "     ${_convertToValidVariableName(key)}: ${_convertFromJsonMapper(key, value)},");
    });
    classBuffer.writeln("   );");
    classBuffer.writeln(" }");
    classBuffer.writeln("");

    classBuffer.writeln(" Map<String, dynamic> toJson() {");
    classBuffer.writeln("   return {");
    jsonMap.forEach((key, value) {
      classBuffer
          .writeln("     \"$key\": ${_convertToJsonMapper(key, value)},");
    });
    classBuffer.writeln("   };");
    classBuffer.writeln(" }");
    classBuffer.writeln();

    classBuffer
        .writeln(" static List<$className> parseList(dynamic jsonList) {");
    classBuffer.writeln(
        "   if (jsonList == null || jsonList is! List || jsonList.isEmpty) {");
    classBuffer.writeln("     return [];");
    classBuffer.writeln("   }");
    classBuffer.writeln(
        "   return jsonList.map((json) => $className.fromJson(json)).toList();");
    classBuffer.writeln(" }");

    classBuffer.writeln("}");
    return classBuffer.toString();
  }

  static String _convertFromJsonMapper(String key, dynamic value) {
    if (value is Map) {
      return "${_convertToValidClassName(key)}.fromJson(json[\"$key\"])";
    } else if (value is List) {
      if (value.isEmpty) {
        return "List<dynamic>.from(json[\"$key\"])";
      } else {
        return _convertFromJsonListMapper(key, value[0]);
      }
    } else {
      return "json[\"$key\"]";
    }
  }

  static String _convertToJsonMapper(String key, dynamic value) {
    if (value is Map) {
      return "${_convertToValidVariableName(key)}.toJson()";
    } else if (value is List) {
      if (value.isEmpty) {
        return _convertToValidVariableName(key);
      } else {
        return _convertToJsonListMapper(key, value[0]);
      }
    } else {
      return _convertToValidVariableName(key);
    }
  }

  static String _convertFromJsonListMapper(String key, dynamic value) {
    if (value is Map) {
      return "${_convertToValidClassName(key)}.parseList(json[\"$key\"])";
    } else {
      return "List<${_getDartType(key, value)}>.from(json[\"$key\"])";
    }
  }

  static String _convertToJsonListMapper(String key, dynamic value) {
    if (value is Map) {
      return "${_convertToValidVariableName(key)}.map((e) => e.toJson()).toList()";
    } else {
      return _convertToValidVariableName(key);
    }
  }

  static String _getDartType(String key, dynamic value) {
    if (value is String) {
      return "String";
    } else if (value is int) {
      return "int";
    } else if (value is double) {
      return "double";
    } else if (value is bool) {
      return "bool";
    } else if (value is Map) {
      return _convertToValidClassName(key);
    } else if (value is List) {
      return "List<${value.isEmpty ? "dynamic" : _getDartType(key, value[0])}>";
    } else {
      return "dynamic";
    }
  }

  static String _convertToValidClassName(String input) {
    input = input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)!.toLowerCase()}',
        )
        .replaceAllMapped(
          RegExp(r'[0-9]'),
          (match) => '${match.group(0)} ',
        )
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')
        .trim();
    if (input.isEmpty) return input;
    input = input
        .split(" ")
        .map((e) => e.length < 2
            ? e.toLowerCase()
            : ("${e[0].toUpperCase()}${e.substring(1).toLowerCase()}"))
        .join();
    if (RegExp(r'^[0-9]').hasMatch(input)) {
      input = "A$input";
    }
    return input;
  }

  static String _convertToValidVariableName(String input) {
    input = _convertToValidClassName(input);
    return input.length < 2
        ? input.toLowerCase()
        : ("${input[0].toLowerCase()}${input.substring(1)}");
  }

  static String convertToValidFileName(String input) {
    input = _convertToValidVariableName(input);
    return input.replaceAllMapped(
      RegExp(r'[A-Z0-9]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  static String getClassName(String className) {
    return className.trim().isEmpty ? "AutoGenerated" : className;
  }

  static void initiateDownload(String fileName, String content) {
    final encodedContent = Uri.encodeComponent(content);
    web.HTMLAnchorElement()
      ..href = 'data:text/plain;charset=utf-8,$encodedContent'
      ..target = '_blank'
      ..download = fileName
      ..click();
  }

  static void navigateToDeveloperPage() {
    web.HTMLAnchorElement()
      ..href = 'https://sharmadhiraj.com/profile/'
      ..target = '_blank'
      ..click();
  }
}
