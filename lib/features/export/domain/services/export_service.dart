import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_tracker/core/utils/export_utils.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';

/// Service class for handling export operations
class ExportService {
  final Uuid _uuid = const Uuid();

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

  /// Exports expenses to CSV format and saves to device storage
  ///
  /// [expenses] - List of expenses to export
  /// Returns ExportHistory with export details
  Future<ExportHistory> exportToCsv(List<Expense> expenses) async {
    try {
      // Validate export data
      if (!ExportUtils.validateExportData(expenses)) {
        throw Exception('No expenses to export');
      }

      // Generate export data
      final csvData = ExportUtils.exportToCsv(expenses);
      final timestamp = DateTime.now();
      final fileName = ExportUtils.generateFileName('csv', timestamp);

      // Save file to downloads directory
      final downloadsPath = await getDownloadsDirectory();
      final exportDir = Directory('$downloadsPath/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Save file
      final file = await ExportUtils.saveToFile(csvData, fileName, exportDir);
      final fileSize = await ExportUtils.getFileSize(file);
      final filePath = file.path;

      // Debug: Verify file content was saved correctly
      try {
        final savedContent = await file.readAsString();
        print('DEBUG: File saved successfully');
        print('DEBUG: File path: $filePath');
        print('DEBUG: File size: $fileSize bytes');
        print('DEBUG: Content length: ${savedContent.length} characters');
        print(
            'DEBUG: Content preview: ${savedContent.substring(0, savedContent.length > 100 ? 100 : savedContent.length)}');
      } catch (e) {
        print('DEBUG: Error reading saved file: $e');
      }

      // Note: Notification will be shown from the UI layer
      // to avoid requiring BuildContext in domain layer

      // Create export history record
      final exportHistory = ExportHistory(
        id: _uuid.v4(),
        timestamp: timestamp,
        format: ExportFormat.csv,
        fileName: fileName,
        fileSize: fileSize,
        recordCount: expenses.length,
        status: ExportStatus.success,
      );

      print(
          'DEBUG: Created CSV export history with format: ${exportHistory.format.name}');

      return exportHistory;
    } catch (e) {
      // Create failed export history record
      return ExportHistory(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        format: ExportFormat.csv,
        fileName: '',
        fileSize: 0,
        recordCount: 0,
        status: ExportStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Exports expenses to JSON format and saves to device storage
  ///
  /// [expenses] - List of expenses to export
  /// Returns ExportHistory with export details
  Future<ExportHistory> exportToJson(List<Expense> expenses) async {
    try {
      // Validate export data
      if (!ExportUtils.validateExportData(expenses)) {
        throw Exception('No expenses to export');
      }

      // Generate export data
      final jsonData = ExportUtils.exportToJson(expenses);
      final timestamp = DateTime.now();
      final fileName = ExportUtils.generateFileName('json', timestamp);

      // Save file to downloads directory
      final downloadsPath = await getDownloadsDirectory();
      final exportDir = Directory('$downloadsPath/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Save file
      final file = await ExportUtils.saveToFile(jsonData, fileName, exportDir);
      final fileSize = await ExportUtils.getFileSize(file);
      final filePath = file.path;

      // Debug: Verify file content was saved correctly
      try {
        final savedContent = await file.readAsString();
        print('DEBUG: File saved successfully');
        print('DEBUG: File path: $filePath');
        print('DEBUG: File size: $fileSize bytes');
        print('DEBUG: Content length: ${savedContent.length} characters');
        print(
            'DEBUG: Content preview: ${savedContent.substring(0, savedContent.length > 100 ? 100 : savedContent.length)}');
      } catch (e) {
        print('DEBUG: Error reading saved file: $e');
      }

      // Note: Notification will be shown from the UI layer
      // to avoid requiring BuildContext in domain layer

      // Create export history record
      final exportHistory = ExportHistory(
        id: _uuid.v4(),
        timestamp: timestamp,
        format: ExportFormat.json,
        fileName: fileName,
        fileSize: fileSize,
        recordCount: expenses.length,
        status: ExportStatus.success,
      );

      print(
          'DEBUG: Created JSON export history with format: ${exportHistory.format.name}');

      return exportHistory;
    } catch (e) {
      // Create failed export history record
      return ExportHistory(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        format: ExportFormat.json,
        fileName: '',
        fileSize: 0,
        recordCount: 0,
        status: ExportStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
}
