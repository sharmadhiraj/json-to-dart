import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/shortcut_labels.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/widgets/panel_card.dart';

class InputPanel extends StatelessWidget {
  const InputPanel({required this.controller, super.key});

  static const double _compactBelowWidth = 560;

  final ConverterController controller;

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) controller.setJson(data!.text!);
  }

  Future<void> _upload() async {
    final String? text = await WebUtils.pickTextFile();
    if (text != null) controller.setJson(text);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < _compactBelowWidth;
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => PanelCard(
            title: "JSON",
            actions: _buildActions(compact),
            footer: controller.error == null
                ? null
                : _ErrorBanner(message: controller.error!),
            child: TextField(
              controller: controller.jsonController,
              focusNode: controller.jsonFocusNode,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: "monospace"),
              onChanged: (_) => controller.onInputChanged(),
              decoration: const InputDecoration(
                hintText: "Enter JSON here, or drop a .json file",
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActions(bool compact) {
    Widget action(
      String label,
      IconData icon,
      VoidCallback onPressed, {
      String? shortcut,
    }) {
      return _ToolbarButton(
        label: label,
        shortcut: shortcut,
        icon: icon,
        compact: compact,
        onPressed: () {
          onPressed();
          controller.focusInput();
        },
      );
    }

    return [
      action(
        "Format",
        Icons.format_align_left,
        controller.formatJson,
        shortcut: ShortcutLabels.format,
      ),
      action(
        "Sample",
        Icons.data_object,
        () => controller.setJson(Constant.sampleJson),
      ),
      action("Paste", Icons.content_paste, _paste),
      action("Upload", Icons.upload_file, _upload),
      action("Clear", Icons.clear, controller.clear),
    ];
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: "JSON error: $message",
      child: Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: colors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.compact,
    required this.onPressed,
    this.shortcut,
  });

  final String label;
  final String? shortcut;
  final IconData icon;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "$label JSON",
      child: compact
          ? IconButton(
              tooltip: shortcut == null ? label : "$label ($shortcut)",
              visualDensity: VisualDensity.compact,
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
            )
          : Tooltip(
              message: shortcut == null ? label : "$label ($shortcut)",
              child: TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              ),
            ),
    );
  }
}
