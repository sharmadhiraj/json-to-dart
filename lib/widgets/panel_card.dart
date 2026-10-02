import 'package:flutter/material.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerHighest,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontFamily: "monospace",
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                ...actions,
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(child: child),
          if (footer != null) ...[
            Divider(height: 1, color: colors.outlineVariant),
            footer!,
          ],
        ],
      ),
    );
  }
}
