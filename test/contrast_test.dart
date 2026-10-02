import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/util/app_theme.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final Brightness brightness in Brightness.values) {
    group("WCAG AA contrast (${brightness.name})", () {
      final ColorScheme c = AppTheme.build(brightness).colorScheme;
      final Map<String, (Color, Color)> pairs = {
        "body text on page": (c.onSurface, c.surface),
        "code text on panel": (c.onSurface, c.surfaceContainerLow),
        "secondary text on panel": (c.onSurfaceVariant, c.surfaceContainerLow),
        "secondary text on panel header": (
          c.onSurfaceVariant,
          c.surfaceContainerHighest
        ),
        "title on panel header": (c.onSurface, c.surfaceContainerHighest),
        "toolbar icons on panel header": (
          c.onSurfaceVariant,
          c.surfaceContainerHighest
        ),
        "error banner text": (c.onErrorContainer, c.errorContainer),
        "primary accent on panel": (c.primary, c.surfaceContainerLow),
        "selected chip label": (c.onSecondaryContainer, c.secondaryContainer),
        "chip label": (c.onSurfaceVariant, c.surface),
      };
      for (final MapEntry<String, (Color, Color)> pair in pairs.entries) {
        test(pair.key, () {
          expect(
            _contrast(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: pair.key,
          );
        });
      }
    });
  }
}
