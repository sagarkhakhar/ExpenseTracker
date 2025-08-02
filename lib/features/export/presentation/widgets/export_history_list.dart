import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_providers.dart';

/// Widget for displaying export history
class ExportHistoryList extends ConsumerWidget {
  const ExportHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportHistoryAsync = ref.watch(exportHistoryProvider);

    return exportHistoryAsync.when(
      data: (exportHistory) {
        if (exportHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No export history yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Export your data to see it here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: exportHistory.length,
          itemBuilder: (context, index) {
            final history = exportHistory[index];
            return _ExportHistoryCard(exportHistory: history);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading export history',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportHistoryCard extends StatelessWidget {
  final ExportHistory exportHistory;

  const _ExportHistoryCard({
    required this.exportHistory,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final fileSize = _formatFileSize(exportHistory.fileSize);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getStatusIcon(),
        title: Text(
          exportHistory.fileName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${exportHistory.format.name.toUpperCase()} • $fileSize • ${exportHistory.recordCount} records',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(exportHistory.timestamp),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            if (exportHistory.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${exportHistory.errorMessage}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: _getFormatIcon(),
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (exportHistory.status) {
      case ExportStatus.success:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
        );
      case ExportStatus.failed:
        return const Icon(
          Icons.error,
          color: Colors.red,
        );
      case ExportStatus.inProgress:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }

  Widget _getFormatIcon() {
    switch (exportHistory.format) {
      case ExportFormat.csv:
        return const Icon(Icons.table_chart);
      case ExportFormat.json:
        return const Icon(Icons.code);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
