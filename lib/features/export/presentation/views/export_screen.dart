import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_providers.dart';
import 'package:expense_tracker/features/export/presentation/widgets/export_format_selector.dart';
import 'package:expense_tracker/features/export/presentation/widgets/export_history_list.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'dart:io'; // Added for File

/// Screen for exporting expense data
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat? selectedFormat;
  String? _lastShownExportId; // Track the last export ID that was shown

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportStateProvider);
    final expensesAsync = ref.watch(expenseNotifierProvider);

    // Handle notification display without causing rebuild loops
    _checkAndShowNotification(exportState);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exportData),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export format selector
            ExportFormatSelector(
              selectedFormat: selectedFormat,
              onFormatSelected: (format) {
                setState(() {
                  selectedFormat = format;
                });
              },
            ),
            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFormat == null || exportState.isExporting
                    ? null
                    : () => _exportData(),
                icon: exportState.isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  exportState.isExporting
                      ? 'Exporting...'
                      : 'Export to ${selectedFormat?.name.toUpperCase() ?? 'Format'}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (exportState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exportState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(exportStateProvider.notifier).clearError();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),

            // Success message with file actions
            if (exportState.lastExport != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Export completed successfully!',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(exportStateProvider.notifier)
                                .clearLastExport();
                          },
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _openExportedFile(exportState.lastExport!),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(AppLocalizations.of(context)!.openFile),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _shareExportedFile(exportState.lastExport!),
                            icon: const Icon(Icons.share, size: 16),
                            label: Text(AppLocalizations.of(context)!.share),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Export history
            const Text(
              'Export History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: ExportHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndShowNotification(ExportState exportState) {
    // Reset notification tracking when export state is cleared
    if (exportState.lastExport == null) {
      _lastShownExportId = null;
      return;
    }

    // Show notification when export completes (only if not already shown for this export)
    if (exportState.lastExport != null &&
        _lastShownExportId != exportState.lastExport!.id) {
      _lastShownExportId =
          exportState.lastExport!.id; // Mark this export as shown

      // Use a microtask to avoid blocking the build
      Future.microtask(() {
        _showExportNotification(exportState.lastExport!);
      });
    }
  }

  void _exportData() {
    if (selectedFormat == null) return;

    final expensesAsync = ref.read(expenseNotifierProvider);
    expensesAsync.whenData((expenses) {
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noExpensesToExport),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      switch (selectedFormat) {
        case ExportFormat.csv:
          ref.read(exportStateProvider.notifier).exportToCsv(expenses);
          break;
        case ExportFormat.json:
          ref.read(exportStateProvider.notifier).exportToJson(expenses);
          break;
        case null:
          break;
      }
    });
  }

  /// Open the exported file using appropriate app
  Future<void> _openExportedFile(ExportHistory exportHistory) async {
    try {
      final notificationService = NotificationService();

      // First check if the file exists
      final fileExists =
          await notificationService.exportFileExists(exportHistory.fileName);
      if (!fileExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.exportFileNotFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final filePath =
          await notificationService.getExportFilePath(exportHistory.fileName);

      // Verify file exists at the resolved path
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.fileNotFoundAt(filePath)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Use the safer file opening method
      await notificationService.safeOpenFile(context, filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOpeningFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share the exported file
  Future<void> _shareExportedFile(ExportHistory exportHistory) async {
    try {
      final notificationService = NotificationService();

      // First check if the file exists
      final fileExists =
          await notificationService.exportFileExists(exportHistory.fileName);
      if (!fileExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.exportFileNotFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final filePath =
          await notificationService.getExportFilePath(exportHistory.fileName);

      // Verify file exists at the resolved path
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.fileNotFoundAt(filePath)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Use the safer file sharing method
      await notificationService.safeShareFile(
          context, filePath, exportHistory.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSharingFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper method to show the notification
  void _showExportNotification(ExportHistory exportHistory) async {
    // Add a small delay to ensure state is fully updated
    await Future.delayed(const Duration(milliseconds: 100));

    final notificationService = NotificationService();
    final filePath =
        await notificationService.getExportFilePath(exportHistory.fileName);

    // Use the export history directly instead of reading from state
    final format = exportHistory.format.name.toUpperCase();

    // Debug: Print format information
    print('DEBUG: Notification format: $format');
    print('DEBUG: File name: ${exportHistory.fileName}');

    if (mounted) {
      notificationService.showFileDownloadMessage(
        context,
        fileName: exportHistory.fileName,
        filePath: filePath,
        format: format,
        recordCount: exportHistory.recordCount,
      );
    }

    // Clear the export state after a delay to avoid build loop
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(exportStateProvider.notifier).clearLastExport();
      }
    });
  }
}
