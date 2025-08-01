import 'package:flutter/material.dart';

class FilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final VoidCallback? onSelected;
  final VoidCallback? onDeleted;

  const FilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      label: label,
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 18) : null,
      backgroundColor: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontSize: 12,
      ),
    );
  }
}
