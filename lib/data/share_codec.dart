import 'dart:convert';

import 'package:json_to_dart/data/app_settings.dart';

abstract final class ShareCodec {
  static const String queryKey = "s";
  static const int maxEncodedLength = 8000;

  /// Returns null when the state is too large to fit in a link.
  static String? encode(AppSettings settings) {
    final String encoded = base64Url
        .encode(utf8.encode(jsonEncode(settings.toJson())))
        .replaceAll("=", "");
    return encoded.length > maxEncodedLength ? null : encoded;
  }

  static AppSettings? decode(String encoded) {
    try {
      final Object? json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
      );
      return json is Map<String, dynamic> ? AppSettings.fromJson(json) : null;
    } catch (_) {
      return null;
    }
  }

  static Uri? buildUrl(Uri base, AppSettings settings) {
    final String? encoded = encode(settings);
    if (encoded == null) return null;
    return base.replace(
      queryParameters: {...base.queryParameters, queryKey: encoded},
    );
  }

  static AppSettings? fromUri(Uri uri) {
    final String? encoded = uri.queryParameters[queryKey];
    return encoded == null ? null : decode(encoded);
  }

  static Uri withoutShare(Uri uri) {
    final Map<String, String> params = {...uri.queryParameters}
      ..remove(queryKey);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters: params.isEmpty ? null : params,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    );
  }
}
