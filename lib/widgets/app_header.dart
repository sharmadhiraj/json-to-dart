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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                Text(
                  Constant.appName,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  Constant.appDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
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
