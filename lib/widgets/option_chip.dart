import 'package:flutter/material.dart';

class OptionChip extends StatelessWidget {
  const OptionChip({
    required this.label,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
    );
  }
}
