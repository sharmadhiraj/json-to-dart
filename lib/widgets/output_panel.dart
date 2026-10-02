import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/data/share_codec.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/shortcut_labels.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/widgets/panel_card.dart';
import 'package:json_to_dart/widgets/rename_classes_dialog.dart';

class OutputPanel extends StatelessWidget {
  const OutputPanel({required this.controller, super.key});

  static const int _maxPreviewChars = 100000;
  static const TextStyle _codeStyle =
      TextStyle(fontFamily: "monospace", fontSize: 14);

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final String code = controller.dartClass;
        final bool hasOutput = code.isNotEmpty;
        return PanelCard(
          title: "Dart",
          subtitle: hasOutput ? controller.fileName : null,
          actions: [
            if (controller.nestedClasses.isNotEmpty)
              Semantics(
                button: true,
                label: "Rename generated classes",
                child: IconButton(
                  tooltip: "Rename classes",
                  onPressed: () => _renameClasses(context),
                  icon: const Icon(Icons.edit_note),
                ),
              ),
            Semantics(
              button: true,
              label: "Copy share link",
              child: IconButton(
                tooltip: "Copy share link",
                onPressed: () => _shareLink(context),
                icon: const Icon(Icons.link),
              ),
            ),
            _CopyButton(controller: controller),
            Semantics(
              button: true,
              label: "Download ${controller.fileName}",
              child: IconButton(
                tooltip:
                    "Download ${controller.fileName} (${ShortcutLabels.download})",
                onPressed: hasOutput
                    ? () => WebUtils.downloadFile(controller.fileName, code)
                    : null,
                icon: const Icon(Icons.download),
              ),
            ),
          ],
          footer: hasOutput ? _buildStatus(context, code) : null,
          child: hasOutput ? _buildCode(context, code) : _buildEmpty(context),
        );
      },
    );
  }

  Future<void> _renameClasses(BuildContext context) async {
    final Map<String, String>? renames = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => RenameClassesDialog(classes: controller.nestedClasses),
    );
    if (renames != null) controller.setClassRenames(renames);
  }

  Future<void> _shareLink(BuildContext context) async {
    final Uri? url = ShareCodec.buildUrl(Uri.base, controller.currentSettings);
    if (url != null) {
      await Clipboard.setData(ClipboardData(text: url.toString()));
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 320,
        duration: const Duration(seconds: 2),
        content: Text(
          url == null
              ? "Too large to share as a link. Download the file instead."
              : "Share link copied to clipboard",
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, String code) {
    final int lines = "\n".allMatches(code).length + 1;
    final int classes = "\nclass ".allMatches("\n$code").length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        "$classes ${classes == 1 ? "class" : "classes"} · $lines lines",
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasError = controller.error != null;
    final bool isInputEmpty = controller.jsonController.text.trim().isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.code,
              size: 40,
              color: theme.hintColor,
            ),
            const SizedBox(height: 12),
            Text(
              hasError
                  ? "Fix the JSON error to see the generated code."
                  : "Generated Dart code will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            if (isInputEmpty) ...[
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: "Load sample JSON",
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    controller
                      ..setJson(Constant.sampleJson)
                      ..focusInput();
                  },
                  icon: const Icon(Icons.data_object),
                  label: const Text("Try a sample"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCode(BuildContext context, String code) {
    final bool truncated = code.length > _maxPreviewChars;
    final String shown = truncated
        ? "${code.substring(0, _maxPreviewChars)}\n\n// Preview truncated. Copy or download for the full output."
        : code;
    final int lineCount = "\n".allMatches(shown).length + 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              List.generate(lineCount, (i) => "${i + 1}").join("\n"),
              textAlign: TextAlign.right,
              style: _codeStyle.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(shown, style: _codeStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    final bool copied = controller.copied;
    return Semantics(
      button: true,
      liveRegion: true,
      label: copied ? "Copied to clipboard" : "Copy class code to clipboard",
      child: IconButton(
        tooltip:
            copied ? "Copied" : "Copy to clipboard (${ShortcutLabels.copy})",
        onPressed: controller.dartClass.isEmpty ? null : controller.copyOutput,
        icon: Icon(copied ? Icons.check : Icons.copy),
        color: copied ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}
