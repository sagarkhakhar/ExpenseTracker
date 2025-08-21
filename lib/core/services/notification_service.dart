import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';

/// Lightweight service for handling file operations and user feedback
class NotificationService {
  /// Show success message using SnackBar
  void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show file download completion message
  void showFileDownloadMessage(
    BuildContext context, {
    required String fileName,
    required String filePath,
    required String format,
    required int recordCount,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$recordCount expenses exported to $format',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'File: $fileName',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => _openFile(context, filePath),
        ),
      ),
    );
  }

  /// Open file using appropriate app
  Future<void> _openFile(BuildContext context, String filePath) async {
    // Use the enhanced safeOpenFile method instead
    await safeOpenFile(context, filePath);
  }

  /// Share file using system share
  Future<void> shareFile(
      BuildContext context, String filePath, String fileName) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: 'Expense Export - $fileName');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSharingFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get the downloads directory path
  Future<String> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Try to use the app's external files directory first
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir.path;
        }

        // Fallback to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${appDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir.path;
      } catch (e) {
        // Final fallback to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${appDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir.path;
      }
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir.path;
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Copy file to downloads directory and return new path
  Future<String> copyToDownloads(String sourcePath, String fileName) async {
    final downloadsDir = await getDownloadsDirectory();
    final destinationPath = '$downloadsDir/$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  /// Get the full file path for an export file
  Future<String> getExportFilePath(String fileName) async {
    try {
      final downloadsPath = await getDownloadsDirectory();
      return '$downloadsPath/exports/$fileName';
    } catch (e) {
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/Downloads/exports/$fileName';
    }
  }

  /// Check if an export file exists
  Future<bool> exportFileExists(String fileName) async {
    try {
      final filePath = await getExportFilePath(fileName);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Verify file content before opening
  Future<Map<String, dynamic>> verifyFileContent(String filePath) async {
    final result = <String, dynamic>{};

    try {
      final file = File(filePath);
      result['exists'] = await file.exists();

      if (await file.exists()) {
        result['size'] = await file.length();
        final content = await file.readAsString();
        result['contentLength'] = content.length;
        result['hasContent'] = content.isNotEmpty;
        result['contentPreview'] =
            content.length > 100 ? '${content.substring(0, 100)}...' : content;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Safely open a file with platform-specific handling
  Future<void> safeOpenFile(BuildContext context, String filePath) async {
    try {
      // First verify the file has content
      final fileInfo = await verifyFileContent(filePath);

      if (!fileInfo['exists']) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.fileDoesNotExist),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!fileInfo['hasContent']) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.fileAppearsEmpty),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (Platform.isAndroid) {
        // On Android, try multiple approaches to avoid SELinux issues

        // First, try to open with specific MIME type
        try {
          final result = await OpenFile.open(
            filePath,
            type: _getMimeType(filePath),
          );

          if (result.type == ResultType.done) {
            return; // Success
          }
        } catch (e) {
          // Continue to next approach
        }

        // If that fails, try without MIME type
        try {
          final result = await OpenFile.open(filePath);
          if (result.type == ResultType.done) {
            return; // Success
          }
        } catch (e) {
          // Continue to next approach
        }

        // If both fail, try to copy to a more accessible location first
        try {
          final tempDir = await getTemporaryDirectory();
          final fileName = filePath.split('/').last;
          final tempPath = '${tempDir.path}/$fileName';

          final sourceFile = File(filePath);
          final tempFile = await sourceFile.copy(tempPath);

          final result = await OpenFile.open(tempFile.path);
          if (result.type == ResultType.done) {
            return; // Success
          }
        } catch (e) {
          // Continue to final approach
        }

        // Try alternative Android viewer approach
        try {
          await _openWithAndroidViewer(context, filePath);
          return; // Success
        } catch (e) {
          // Continue to final fallback
        }

        // Final fallback: show error with file path
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenFile(filePath)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy Path',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: filePath));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.filePathCopied),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );

          // Also show a dialog with options
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.fileOpeningFailed),
              content: const Text(
                'The file could not be opened with an external app. You can view the contents here or copy the file path.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showFileContentsDialog(context, filePath);
                  },
                  child: Text(AppLocalizations.of(context)!.viewContents),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: filePath));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.filePathCopied),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.copyPath),
                ),
              ],
            ),
          );
        }
      } else {
        // On iOS, use standard open
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorOpeningFile(result.message)),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOpeningFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get MIME type for file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Alternative method to open file using Android's built-in viewer
  Future<void> _openWithAndroidViewer(
      BuildContext context, String filePath) async {
    try {
      // Try to open with Android's built-in text viewer
      final result = await OpenFile.open(
        filePath,
        type: 'text/plain', // Force text viewer
      );

      if (result.type == ResultType.done) {
        return;
      }
    } catch (e) {
      // Continue to next approach
    }

    // If that fails, try with generic viewer
    try {
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        return;
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Show file contents in a dialog as last resort
  Future<void> _showFileContentsDialog(
      BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final fileName = filePath.split('/').last;

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.fileContents(fileName)),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: SelectableText(
                    contents,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: contents));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.fileContentsCopied),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.copyAll),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorReadingFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Safely share a file with platform-specific handling
  Future<void> safeShareFile(
      BuildContext context, String filePath, String fileName) async {
    try {
      final file = XFile(filePath);

      if (Platform.isAndroid) {
        // On Android, specify the MIME type for better compatibility
        await Share.shareXFiles(
          [file],
          text: 'Expense Export - $fileName',
          subject: 'Expense Export',
        );
      } else {
        // On iOS, use standard share
        await Share.shareXFiles(
          [file],
          text: 'Expense Export - $fileName',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSharingFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
