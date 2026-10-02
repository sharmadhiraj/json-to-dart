abstract final class Constant {
  static const String appName = "JSON to Dart";
  static const String appDescription =
      "Convert JSON to Dart with ease! Supports nested classes and includes fromJson, toJson, and parseList methods.";
  static const String appTagline = "Paste JSON, get Dart classes";
  static const String developerName = "Dhiraj Sharma";
  static const String developerUrl = "https://sharmadhiraj.com/profile/";
  static const String sampleJson = """{
  "id": 1,
  "name": "Jane Doe",
  "rating": 4.5,
  "active": true,
  "address": {"city": "Sydney", "postcode": "2000"},
  "tags": ["admin", "beta"],
  "orders": [
    {"id": 10, "total": 25.0, "note": null},
    {"id": 11, "total": 40.5}
  ]
}""";
}
