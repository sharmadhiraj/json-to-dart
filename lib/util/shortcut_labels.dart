import 'package:flutter/foundation.dart';

abstract final class ShortcutLabels {
  static String get primary =>
      defaultTargetPlatform == TargetPlatform.macOS ? "⌘" : "Ctrl+";

  static String get copy => "${primary}Enter";
  static String get download => "${primary}S";
  static String get format => "${primary}Shift+F";
}
