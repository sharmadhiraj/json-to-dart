import 'package:flutter/material.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/web_utils.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Semantics(
        button: true,
        label: "Open developer profile",
        child: InkWell(
          onTap: () => WebUtils.openUrl(Constant.developerUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              "Made by ${Constant.developerName}",
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
