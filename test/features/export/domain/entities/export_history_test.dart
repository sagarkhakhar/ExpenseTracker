import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';

void main() {
  group('ExportFormat', () {
    test('should have correct values', () {
      expect(ExportFormat.csv.index, 0);
      expect(ExportFormat.json.index, 1);
    });

    test('should have correct string representations', () {
      expect(ExportFormat.csv.toString(), 'ExportFormat.csv');
      expect(ExportFormat.json.toString(), 'ExportFormat.json');
    });
  });

  group('ExportStatus', () {
    test('should have correct values', () {
      expect(ExportStatus.inProgress.index, 0);
      expect(ExportStatus.success.index, 1);
      expect(ExportStatus.failed.index, 2);
    });

    test('should have correct string representations', () {
      expect(ExportStatus.inProgress.toString(), 'ExportStatus.inProgress');
      expect(ExportStatus.success.toString(), 'ExportStatus.success');
      expect(ExportStatus.failed.toString(), 'ExportStatus.failed');
    });
  });

  group('ExportHistory', () {
    const testId = 'test-id';
    final testTimestamp = DateTime(2024, 1, 1, 12, 0, 0);
    const testFormat = ExportFormat.csv;
    const testFileName = 'test_export.csv';
    const testFileSize = 1024;
    const testRecordCount = 50;
    const testStatus = ExportStatus.success;
    const testErrorMessage = 'Test error message';

    final exportHistory = ExportHistory(
      id: testId,
      timestamp: testTimestamp,
      format: testFormat,
      fileName: testFileName,
      fileSize: testFileSize,
      recordCount: testRecordCount,
      status: testStatus,
    );

    final exportHistoryWithError = ExportHistory(
      id: testId,
      timestamp: testTimestamp,
      format: testFormat,
      fileName: testFileName,
      fileSize: testFileSize,
      recordCount: testRecordCount,
      status: ExportStatus.failed,
      errorMessage: testErrorMessage,
    );

    test('should create ExportHistory with required fields', () {
      expect(exportHistory.id, testId);
      expect(exportHistory.timestamp, testTimestamp);
      expect(exportHistory.format, testFormat);
      expect(exportHistory.fileName, testFileName);
      expect(exportHistory.fileSize, testFileSize);
      expect(exportHistory.recordCount, testRecordCount);
      expect(exportHistory.status, testStatus);
      expect(exportHistory.errorMessage, isNull);
    });

    test('should create ExportHistory with optional error message', () {
      expect(exportHistoryWithError.errorMessage, testErrorMessage);
    });

    test('should be equal when all properties are the same', () {
      final exportHistory2 = ExportHistory(
        id: testId,
        timestamp: testTimestamp,
        format: testFormat,
        fileName: testFileName,
        fileSize: testFileSize,
        recordCount: testRecordCount,
        status: testStatus,
      );

      expect(exportHistory, equals(exportHistory2));
    });

    test('should not be equal when properties are different', () {
      final exportHistory2 = ExportHistory(
        id: 'different-id',
        timestamp: testTimestamp,
        format: testFormat,
        fileName: testFileName,
        fileSize: testFileSize,
        recordCount: testRecordCount,
        status: testStatus,
      );

      expect(exportHistory, isNot(equals(exportHistory2)));
    });

    test('should copy with new values', () {
      const newId = 'new-id';
      final newTimestamp = DateTime(2024, 2, 1, 12, 0, 0);
      const newFormat = ExportFormat.json;
      const newFileName = 'new_export.json';
      const newFileSize = 2048;
      const newRecordCount = 100;
      const newStatus = ExportStatus.failed;
      const newErrorMessage = 'New error message';

      final copied = exportHistory.copyWith(
        id: newId,
        timestamp: newTimestamp,
        format: newFormat,
        fileName: newFileName,
        fileSize: newFileSize,
        recordCount: newRecordCount,
        status: newStatus,
        errorMessage: newErrorMessage,
      );

      expect(copied.id, newId);
      expect(copied.timestamp, newTimestamp);
      expect(copied.format, newFormat);
      expect(copied.fileName, newFileName);
      expect(copied.fileSize, newFileSize);
      expect(copied.recordCount, newRecordCount);
      expect(copied.status, newStatus);
      expect(copied.errorMessage, newErrorMessage);
    });

    test('should copy with partial values', () {
      const newFileName = 'partial_export.csv';
      const newStatus = ExportStatus.inProgress;

      final copied = exportHistory.copyWith(
        fileName: newFileName,
        status: newStatus,
      );

      expect(copied.id, testId);
      expect(copied.timestamp, testTimestamp);
      expect(copied.format, testFormat);
      expect(copied.fileName, newFileName);
      expect(copied.fileSize, testFileSize);
      expect(copied.recordCount, testRecordCount);
      expect(copied.status, newStatus);
      expect(copied.errorMessage, isNull);
    });

    test('should have correct props for Equatable', () {
      final props = exportHistory.props;
      expect(props, contains(testId));
      expect(props, contains(testTimestamp));
      expect(props, contains(testFormat));
      expect(props, contains(testFileName));
      expect(props, contains(testFileSize));
      expect(props, contains(testRecordCount));
      expect(props, contains(testStatus));
      expect(props, contains(null)); // errorMessage
    });
  });
}
