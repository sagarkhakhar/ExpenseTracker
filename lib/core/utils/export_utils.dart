import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

/// Utility class for exporting expense data to different formats
class ExportUtils {
  /// Exports expenses to CSV format
  ///
  /// [expenses] - List of expenses to export
  /// Returns CSV string with headers and data
  static String exportToCsv(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return '';
    }

    // Define CSV headers
    const headers = [
      'ID',
      'Title',
      'Description',
      'Amount',
      'Category',
      'Date',
      'Type',
      'Created At',
      'Updated At',
    ];

    // Convert expenses to CSV rows
    final rows = expenses
        .map((expense) => [
              expense.id,
              expense.title,
              expense.description ?? '',
              expense.amount.toString(),
              expense.category,
              expense.date.toIso8601String(),
              expense.type.name,
              expense.createdAt.toIso8601String(),
              expense.updatedAt.toIso8601String(),
            ])
        .toList();

    // Combine headers and rows
    final csvData = [headers, ...rows];

    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }

  /// Exports expenses to JSON format
  ///
  /// [expenses] - List of expenses to export
  /// Returns JSON string with expense data
  static String exportToJson(List<Expense> expenses) {
    final jsonData = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalRecords': expenses.length,
      'expenses': expenses
          .map((expense) => {
                'id': expense.id,
                'title': expense.title,
                'description': expense.description,
                'amount': expense.amount,
                'category': expense.category,
                'date': expense.date.toIso8601String(),
                'type': expense.type.name,
                'createdAt': expense.createdAt.toIso8601String(),
                'updatedAt': expense.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    return jsonEncode(jsonData);
  }

  /// Generates a filename for export based on format and timestamp
  ///
  /// [format] - Export format (csv or json)
  /// [timestamp] - Timestamp for the export
  /// Returns formatted filename
  static String generateFileName(String format, DateTime timestamp) {
    final dateStr =
        '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

    return 'expense_export_${dateStr}_$timeStr.$format';
  }

  /// Saves export data to a file
  ///
  /// [data] - Data to save
  /// [fileName] - Name of the file
  /// [directory] - Directory to save the file in
  /// Returns the saved file
  static Future<File> saveToFile(
      String data, String fileName, Directory directory) async {
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
    return file;
  }

  /// Gets the file size in bytes
  ///
  /// [file] - File to get size for
  /// Returns file size in bytes
  static Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Validates that the export data is not empty
  ///
  /// [expenses] - List of expenses to validate
  /// Returns true if valid, false otherwise
  static bool validateExportData(List<Expense> expenses) {
    return expenses.isNotEmpty;
  }

  /// Formats file size for display
  ///
  /// [bytes] - File size in bytes
  /// Returns formatted string (e.g., "1.5 KB", "2.3 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Debug method to check file accessibility
  ///
  /// [filePath] - Path to the file to check
  /// Returns debug information about the file
  static Future<Map<String, dynamic>> debugFileAccess(String filePath) async {
    final file = File(filePath);
    final result = <String, dynamic>{};

    try {
      result['path'] = filePath;
      result['exists'] = await file.exists();

      if (await file.exists()) {
        result['size'] = await file.length();
        result['readable'] =
            await file.stat().then((_) => true).catchError((_) => false);
        result['absolutePath'] = file.absolute.path;
        result['parentExists'] = await file.parent.exists();

        // Try to read file content
        try {
          final content = await file.readAsString();
          result['contentLength'] = content.length;
          result['contentPreview'] = content.length > 200
              ? '${content.substring(0, 200)}...'
              : content;
          result['hasContent'] = content.isNotEmpty;
        } catch (e) {
          result['contentError'] = e.toString();
          result['hasContent'] = false;
        }
      } else {
        result['parentExists'] = await file.parent.exists();
        result['parentPath'] = file.parent.path;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }
}
