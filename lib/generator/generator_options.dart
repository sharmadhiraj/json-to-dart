class GeneratorOptions {
  const GeneratorOptions({
    this.fromJson = true,
    this.toJson = true,
    this.parseList = true,
    this.copyWithMethod = false,
    this.equality = false,
    this.detectDates = false,
    this.jsonSerializable = false,
    this.allNullable = false,
  });

  factory GeneratorOptions.fromMap(Map<String, dynamic> json) {
    return GeneratorOptions(
      fromJson: json["fromJson"] as bool? ?? true,
      toJson: json["toJson"] as bool? ?? true,
      parseList: json["parseList"] as bool? ?? true,
      copyWithMethod: json["copyWithMethod"] as bool? ?? false,
      equality: json["equality"] as bool? ?? false,
      detectDates: json["detectDates"] as bool? ?? false,
      jsonSerializable: json["jsonSerializable"] as bool? ?? false,
      allNullable: json["allNullable"] as bool? ?? false,
    );
  }

  final bool fromJson;
  final bool toJson;
  final bool parseList;
  final bool copyWithMethod;
  final bool equality;
  final bool detectDates;
  final bool jsonSerializable;
  final bool allNullable;

  /// json_serializable always delegates to generated fromJson/toJson.
  bool get emitFromJson => fromJson || jsonSerializable;
  bool get emitToJson => toJson || jsonSerializable;
  bool get effectiveParseList => emitFromJson && parseList;

  GeneratorOptions copyWith({
    bool? fromJson,
    bool? toJson,
    bool? parseList,
    bool? copyWithMethod,
    bool? equality,
    bool? detectDates,
    bool? jsonSerializable,
    bool? allNullable,
  }) {
    return GeneratorOptions(
      fromJson: fromJson ?? this.fromJson,
      toJson: toJson ?? this.toJson,
      parseList: parseList ?? this.parseList,
      copyWithMethod: copyWithMethod ?? this.copyWithMethod,
      equality: equality ?? this.equality,
      detectDates: detectDates ?? this.detectDates,
      jsonSerializable: jsonSerializable ?? this.jsonSerializable,
      allNullable: allNullable ?? this.allNullable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "fromJson": fromJson,
      "toJson": toJson,
      "parseList": parseList,
      "copyWithMethod": copyWithMethod,
      "equality": equality,
      "detectDates": detectDates,
      "jsonSerializable": jsonSerializable,
      "allNullable": allNullable,
    };
  }
}
