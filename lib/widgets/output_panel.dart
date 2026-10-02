import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/widgets/panel_card.dart';

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
            _CopyButton(text: code, enabled: hasOutput),
            Semantics(
              button: true,
              label: "Download ${controller.fileName}",
              child: IconButton(
                tooltip: "Download ${controller.fileName}",
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

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      liveRegion: true,
      label: _copied ? "Copied to clipboard" : "Copy class code to clipboard",
      child: IconButton(
        tooltip: _copied ? "Copied" : "Copy to clipboard",
        onPressed: widget.enabled ? _copy : null,
        icon: Icon(_copied ? Icons.check : Icons.copy),
        color: _copied ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}
