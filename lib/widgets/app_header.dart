import 'package:flutter/material.dart';
import 'package:json_to_dart/util/constants.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({required this.onToggleTheme, super.key});

  final ValueChanged<Brightness> onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Text(
            Constant.appName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Constant.appTagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Semantics(
            button: true,
            label: isDark ? "Switch to light theme" : "Switch to dark theme",
            child: IconButton(
              tooltip: isDark ? "Light theme" : "Dark theme",
              onPressed: () => onToggleTheme(theme.brightness),
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            ),
          ),
        ],
      ),
    );
  }
}
