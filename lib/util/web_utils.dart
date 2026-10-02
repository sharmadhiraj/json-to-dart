import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebUtils {
  const WebUtils._();

  static void downloadFile(String fileName, String content) {
    final web.Blob blob = web.Blob(
      <JSAny>[content.toJS].toJS,
      web.BlobPropertyBag(type: "text/plain;charset=utf-8"),
    );
    final String url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();
    web.URL.revokeObjectURL(url);
  }

  static void openUrl(String url) {
    web.HTMLAnchorElement()
      ..href = url
      ..target = "_blank"
      ..click();
  }
}
