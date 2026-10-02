import 'package:json_to_dart/generator/generator_options.dart';

class AppSettings {
  const AppSettings({
    this.className = "",
    this.jsonCode = "",
    this.options = const GeneratorOptions(),
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      className:
          json["className"] as String? ?? json["dartClass"] as String? ?? "",
      jsonCode: json["jsonCode"] as String? ?? "",
      options: GeneratorOptions(
        fromJson: json["fromJson"] as bool? ?? true,
        toJson: json["toJson"] as bool? ?? true,
        parseList: json["parseList"] as bool? ?? true,
      ),
    );
  }

  final String className;
  final String jsonCode;
  final GeneratorOptions options;

  Map<String, dynamic> toJson() {
    return {
      "className": className,
      "jsonCode": jsonCode,
      "fromJson": options.fromJson,
      "toJson": options.toJson,
      "parseList": options.parseList,
    };
  }
}
