class GeneratorOptions {
  const GeneratorOptions({
    this.fromJson = true,
    this.toJson = true,
    this.parseList = true,
    this.copyWithMethod = false,
    this.equality = false,
    this.detectDates = false,
    this.allNullable = false,
    this.detectMaps = true,
    this.numericStrings = false,
    this.snakeCaseFields = false,
    this.mutableFields = false,
    this.classRenames = const {},
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
      detectMaps: json["detectMaps"] as bool? ?? true,
      numericStrings: json["numericStrings"] as bool? ?? false,
      snakeCaseFields: json["snakeCaseFields"] as bool? ?? false,
      mutableFields: json["mutableFields"] as bool? ?? false,
      classRenames: _parseRenames(json["classRenames"]),
    );
  }

  final bool fromJson;
  final bool toJson;
  final bool parseList;
  final bool copyWithMethod;
  final bool equality;
  final bool detectDates;
  final bool allNullable;
  final bool detectMaps;
  final bool numericStrings;
  final bool snakeCaseFields;
  final bool mutableFields;

  /// Maps a generated nested class name to the name the user chose.
  final Map<String, String> classRenames;

  bool get effectiveParseList => fromJson && parseList;

  GeneratorOptions copyWith({
    bool? fromJson,
    bool? toJson,
    bool? parseList,
    bool? copyWithMethod,
    bool? equality,
    bool? detectDates,
    bool? allNullable,
    bool? detectMaps,
    bool? numericStrings,
    bool? snakeCaseFields,
    bool? mutableFields,
    Map<String, String>? classRenames,
  }) {
    return GeneratorOptions(
      fromJson: fromJson ?? this.fromJson,
      toJson: toJson ?? this.toJson,
      parseList: parseList ?? this.parseList,
      copyWithMethod: copyWithMethod ?? this.copyWithMethod,
      equality: equality ?? this.equality,
      detectDates: detectDates ?? this.detectDates,
      allNullable: allNullable ?? this.allNullable,
      detectMaps: detectMaps ?? this.detectMaps,
      numericStrings: numericStrings ?? this.numericStrings,
      snakeCaseFields: snakeCaseFields ?? this.snakeCaseFields,
      mutableFields: mutableFields ?? this.mutableFields,
      classRenames: classRenames ?? this.classRenames,
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
      "detectMaps": detectMaps,
      "numericStrings": numericStrings,
      "snakeCaseFields": snakeCaseFields,
      "mutableFields": mutableFields,
      "classRenames": classRenames,
    };
  }

  static Map<String, String> _parseRenames(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final MapEntry<Object?, Object?> e in value.entries)
        if (e.key is String && e.value is String)
          e.key! as String: e.value! as String,
    };
  }
}
