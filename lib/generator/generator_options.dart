class GeneratorOptions {
  const GeneratorOptions({
    this.fromJson = true,
    this.toJson = true,
    this.parseList = true,
  });

  final bool fromJson;
  final bool toJson;
  final bool parseList;

  bool get effectiveParseList => fromJson && parseList;

  GeneratorOptions copyWith({bool? fromJson, bool? toJson, bool? parseList}) {
    return GeneratorOptions(
      fromJson: fromJson ?? this.fromJson,
      toJson: toJson ?? this.toJson,
      parseList: parseList ?? this.parseList,
    );
  }
}
