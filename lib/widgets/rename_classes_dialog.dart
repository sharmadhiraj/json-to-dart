import 'package:flutter/material.dart';
import 'package:json_to_dart/generator/dart_generator.dart';
import 'package:json_to_dart/generator/naming.dart';

class RenameClassesDialog extends StatefulWidget {
  const RenameClassesDialog({required this.classes, super.key});

  final List<GeneratedClass> classes;

  @override
  State<RenameClassesDialog> createState() => _RenameClassesDialogState();
}

class _RenameClassesDialogState extends State<RenameClassesDialog> {
  late final List<TextEditingController> _controllers = [
    for (final GeneratedClass c in widget.classes)
      TextEditingController(text: c.name),
  ];

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collect() {
    final Map<String, String> renames = {};
    for (int i = 0; i < widget.classes.length; i++) {
      final String text = _controllers[i].text.trim();
      if (text.isEmpty) continue;
      final String name = Naming.className(text);
      if (name != widget.classes[i].original) {
        renames[widget.classes[i].original] = name;
      }
    }
    return renames;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rename classes"),
      content: SizedBox(
        width: 420,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.classes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => TextField(
            controller: _controllers[i],
            autofocus: i == 0,
            decoration: InputDecoration(
              labelText: "Generated as ${widget.classes[i].original}",
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.pop(context, _collect()),
          ),
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: "Reset class names",
          child: TextButton(
            onPressed: () => Navigator.pop(context, <String, String>{}),
            child: const Text("Reset"),
          ),
        ),
        Semantics(
          button: true,
          label: "Cancel renaming",
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ),
        Semantics(
          button: true,
          label: "Apply class names",
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _collect()),
            child: const Text("Apply"),
          ),
        ),
      ],
    );
  }
}
