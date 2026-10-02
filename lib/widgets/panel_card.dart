import 'package:flutter/material.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({
    required this.title,
    required this.child,
    this.headerContent,
    this.actions = const [],
    this.footer,
    super.key,
  });

  final String title;
  final Widget? headerContent;
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
                if (headerContent != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: headerContent,
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
