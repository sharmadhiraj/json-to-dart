class GeneratorOptions {
  const GeneratorOptions({
    this.fromJson = true,
    this.toJson = true,
    this.parseList = true,
    this.copyWithMethod = false,
    this.equality = false,
    this.detectDates = false,
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
      allNullable: json["allNullable"] as bool? ?? false,
    );
  }

  final bool fromJson;
  final bool toJson;
  final bool parseList;
  final bool copyWithMethod;
  final bool equality;
  final bool detectDates;
  final bool allNullable;

  bool get effectiveParseList => fromJson && parseList;

  GeneratorOptions copyWith({
    bool? fromJson,
    bool? toJson,
    bool? parseList,
    bool? copyWithMethod,
    bool? equality,
    bool? detectDates,
    bool? allNullable,
  }) {
    return GeneratorOptions(
      fromJson: fromJson ?? this.fromJson,
      toJson: toJson ?? this.toJson,
      parseList: parseList ?? this.parseList,
      copyWithMethod: copyWithMethod ?? this.copyWithMethod,
      equality: equality ?? this.equality,
      detectDates: detectDates ?? this.detectDates,
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
      "allNullable": allNullable,
    };
  }
}
