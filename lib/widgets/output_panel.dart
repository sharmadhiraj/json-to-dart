import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/web_utils.dart';

class OutputPanel extends StatelessWidget {
  const OutputPanel({required this.controller, super.key});

  static const int _maxPreviewChars = 100000;

  final ConverterController controller;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: controller.dartClass));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActions(context),
            Expanded(child: _buildCode(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool hasOutput = controller.dartClass.isNotEmpty;
    final String fileName = controller.fileName;
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: "Download $fileName",
            child: IconButton(
              tooltip: "Download $fileName file",
              onPressed: hasOutput
                  ? () => WebUtils.downloadFile(fileName, controller.dartClass)
                  : null,
              icon: const Icon(Icons.download),
            ),
          ),
          Semantics(
            button: true,
            label: "Copy class code to clipboard",
            child: IconButton(
              tooltip: "Copy Class Code to Clipboard",
              onPressed: hasOutput ? () => _copy(context) : null,
              icon: const Icon(Icons.copy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCode(BuildContext context) {
    final String code = controller.dartClass;
    if (code.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Generated Dart code will appear here.",
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }
    final bool truncated = code.length > _maxPreviewChars;
    final String shown = truncated
        ? "${code.substring(0, _maxPreviewChars)}\n\n// Preview truncated. Copy or download for the full output."
        : code;
    const TextStyle style = TextStyle(fontFamily: "monospace", fontSize: 14);
    final int lineCount = "\n".allMatches(shown).length + 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              List.generate(lineCount, (i) => "${i + 1}").join("\n"),
              textAlign: TextAlign.right,
              style: style.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(shown, style: style),
            ),
          ),
        ],
      ),
    );
  }
}
