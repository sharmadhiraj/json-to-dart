import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

abstract final class WebUtils {
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

  static void replaceUrl(String url) =>
      web.window.history.replaceState(null, "", url);

  static void openUrl(String url) {
    web.HTMLAnchorElement()
      ..href = url
      ..target = "_blank"
      ..click();
  }

  /// Resolves to null when the picker is cancelled.
  static Future<String?> pickTextFile() {
    final Completer<String?> completer = Completer();
    final web.HTMLInputElement input = web.HTMLInputElement()
      ..type = "file"
      ..accept = ".json,application/json,text/plain";
    input.onChange.first.then((_) async {
      final web.File? file = input.files?.item(0);
      completer.complete(file == null ? null : await _readText(file));
    });
    const web.EventStreamProvider<web.Event>("cancel")
        .forTarget(input)
        .first
        .then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    input.click();
    return completer.future;
  }

  /// Returns a function that removes the listeners.
  static void Function() onFileDropped(void Function(String text) onText) {
    final StreamSubscription<web.Event> dragOver =
        const web.EventStreamProvider<web.Event>("dragover")
            .forTarget(web.document)
            .listen((event) => event.preventDefault());
    final StreamSubscription<web.DragEvent> drop =
        const web.EventStreamProvider<web.DragEvent>("drop")
            .forTarget(web.document)
            .listen((event) async {
      event.preventDefault();
      final web.File? file = event.dataTransfer?.files.item(0);
      if (file != null) onText(await _readText(file));
    });
    return () {
      dragOver.cancel();
      drop.cancel();
    };
  }

  static Future<String> _readText(web.File file) async =>
      (await file.text().toDart).toDart;
}
