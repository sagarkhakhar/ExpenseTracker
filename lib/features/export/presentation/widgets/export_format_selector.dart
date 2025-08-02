import 'package:flutter/material.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';

/// Widget for selecting export format
class ExportFormatSelector extends StatelessWidget {
  final ExportFormat? selectedFormat;
  final Function(ExportFormat) onFormatSelected;

  const ExportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Export Format',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FormatCard(
                format: ExportFormat.csv,
                title: 'CSV',
                subtitle: 'Comma-separated values',
                icon: Icons.table_chart,
                isSelected: selectedFormat == ExportFormat.csv,
                onTap: () => onFormatSelected(ExportFormat.csv),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormatCard(
                format: ExportFormat.json,
                title: 'JSON',
                subtitle: 'JavaScript Object Notation',
                icon: Icons.code,
                isSelected: selectedFormat == ExportFormat.json,
                onTap: () => onFormatSelected(ExportFormat.json),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  final ExportFormat format;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.8)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
