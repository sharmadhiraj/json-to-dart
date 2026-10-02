import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/data/app_settings.dart';
import 'package:json_to_dart/data/share_codec.dart';
import 'package:json_to_dart/generator/generator_options.dart';

void main() {
  const AppSettings settings = AppSettings(
    className: "User",
    jsonCode: '{"name":"Zoë","tags":["a"]}',
    options: GeneratorOptions(
      toJson: false,
      equality: true,
      classRenames: {"Tag": "Label"},
    ),
  );

  test("round trips settings including unicode and options", () {
    final AppSettings decoded =
        ShareCodec.decode(ShareCodec.encode(settings)!)!;
    expect(decoded.className, "User");
    expect(decoded.jsonCode, settings.jsonCode);
    expect(decoded.options.toJson, isFalse);
    expect(decoded.options.equality, isTrue);
    expect(decoded.options.classRenames, {"Tag": "Label"});
  });

  test("encoded form is URL safe", () {
    expect(ShareCodec.encode(settings), matches(RegExp(r"^[A-Za-z0-9_-]+$")));
  });

  test("returns null when too large to share", () {
    final AppSettings big = AppSettings(jsonCode: "x" * 20000);
    expect(ShareCodec.encode(big), isNull);
    expect(ShareCodec.buildUrl(Uri.parse("https://a.dev/"), big), isNull);
  });

  test("rejects garbage", () {
    expect(ShareCodec.decode("!!!"), isNull);
    expect(ShareCodec.decode("e30"), isA<AppSettings>());
    expect(ShareCodec.decode("W10"), isNull);
  });

  test("builds and parses URLs, keeping other parameters", () {
    final Uri base = Uri.parse("https://a.dev/app/?x=1#/");
    final Uri url = ShareCodec.buildUrl(base, settings)!;
    expect(url.queryParameters["x"], "1");
    expect(ShareCodec.fromUri(url)!.className, "User");
    final Uri cleaned = ShareCodec.withoutShare(url);
    expect(cleaned.queryParameters, {"x": "1"});
    expect(cleaned.path, "/app/");
    expect(cleaned.fragment, "/");
    expect(ShareCodec.fromUri(cleaned), isNull);
  });
}
