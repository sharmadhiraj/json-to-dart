import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/generator/generator_options.dart';
import 'package:json_to_dart/widgets/option_chip.dart';

class InputPanel extends StatelessWidget {
  const InputPanel({required this.controller, super.key});

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.classNameController,
              decoration: const InputDecoration(
                labelText: "Class Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => controller.onInputChanged(),
            ),
            const SizedBox(height: 8),
            _buildToolbar(),
            const SizedBox(height: 4),
            Expanded(
              child: TextField(
                controller: controller.jsonController,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: "monospace"),
                onChanged: (_) => controller.onInputChanged(),
                decoration: InputDecoration(
                  hintText: "Enter JSON here, or drop a .json file",
                  border: const OutlineInputBorder(),
                  errorText: controller.error,
                  errorMaxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 4,
      children: [
        _ToolbarButton(
          label: "Format",
          icon: Icons.format_align_left,
          onPressed: controller.formatJson,
        ),
        _ToolbarButton(
          label: "Sample",
          icon: Icons.data_object,
          onPressed: () => controller.setJson(Constant.sampleJson),
        ),
        _ToolbarButton(
          label: "Paste",
          icon: Icons.content_paste,
          onPressed: _paste,
        ),
        _ToolbarButton(
          label: "Upload",
          icon: Icons.upload_file,
          onPressed: _upload,
        ),
        _ToolbarButton(
          label: "Clear",
          icon: Icons.clear,
          onPressed: controller.clear,
        ),
      ],
    );
  }

  Widget _buildOptions() {
    final GeneratorOptions o = controller.options;
    void update(GeneratorOptions options) => controller.setOptions(options);
    return Wrap(
      spacing: 8,
      children: [
        OptionChip(
          label: "fromJson",
          selected: o.emitFromJson,
          onChanged: o.jsonSerializable
              ? null
              : (v) => update(o.copyWith(fromJson: v)),
        ),
        OptionChip(
          label: "toJson",
          selected: o.emitToJson,
          onChanged:
              o.jsonSerializable ? null : (v) => update(o.copyWith(toJson: v)),
        ),
        OptionChip(
          label: "parseList",
          selected: o.effectiveParseList,
          onChanged:
              o.emitFromJson ? (v) => update(o.copyWith(parseList: v)) : null,
        ),
        OptionChip(
          label: "copyWith",
          selected: o.copyWithMethod,
          onChanged: (v) => update(o.copyWith(copyWithMethod: v)),
        ),
        OptionChip(
          label: "== and hashCode",
          selected: o.equality,
          onChanged: (v) => update(o.copyWith(equality: v)),
        ),
        OptionChip(
          label: "Detect dates",
          selected: o.detectDates,
          onChanged: (v) => update(o.copyWith(detectDates: v)),
        ),
        OptionChip(
          label: "All fields nullable",
          selected: o.allNullable,
          onChanged: (v) => update(o.copyWith(allNullable: v)),
        ),
        OptionChip(
          label: "json_serializable",
          selected: o.jsonSerializable,
          onChanged: (v) => update(o.copyWith(jsonSerializable: v)),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "$label JSON",
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
