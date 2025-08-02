import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/export/domain/services/export_service.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ExportService', () {
    late ExportService exportService;
    late List<Expense> testExpenses;
    late Directory tempDir;

    setUp(() {
      exportService = ExportService();
      testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense 1',
          description: 'Test Description 1',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1, 10, 0, 0),
          updatedAt: DateTime(2024, 1, 1, 10, 0, 0),
        ),
        Expense(
          id: '2',
          title: 'Test Expense 2',
          description: 'Test Description 2',
          amount: 200.0,
          category: 'Transport',
          date: DateTime(2024, 1, 2),
          type: ExpenseType.income,
          createdAt: DateTime(2024, 1, 2, 10, 0, 0),
          updatedAt: DateTime(2024, 1, 2, 10, 0, 0),
        ),
      ];

      tempDir = Directory.systemTemp.createTempSync('export_service_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('exportToCsv', () {
      test('should return failed status for empty expenses list', () async {
        final result = await exportService.exportToCsv([]);

        expect(result.status, ExportStatus.failed);
        expect(result.format, ExportFormat.csv);
        expect(result.recordCount, 0);
        expect(result.fileSize, 0);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('No expenses to export'));
      });
    });

    group('exportToJson', () {
      test('should return failed status for empty expenses list', () async {
        final result = await exportService.exportToJson([]);

        expect(result.status, ExportStatus.failed);
        expect(result.format, ExportFormat.json);
        expect(result.recordCount, 0);
        expect(result.fileSize, 0);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('No expenses to export'));
      });
    });

    group('ExportHistory creation', () {
      test('should create ExportHistory with correct properties', () {
        final history = ExportHistory(
          id: 'test-id',
          timestamp: DateTime(2024, 1, 1),
          format: ExportFormat.csv,
          fileName: 'test.csv',
          fileSize: 1024,
          recordCount: 10,
          status: ExportStatus.success,
        );

        expect(history.id, 'test-id');
        expect(history.format, ExportFormat.csv);
        expect(history.fileName, 'test.csv');
        expect(history.fileSize, 1024);
        expect(history.recordCount, 10);
        expect(history.status, ExportStatus.success);
        expect(history.errorMessage, isNull);
      });

      test('should create ExportHistory with error message', () {
        final history = ExportHistory(
          id: 'test-id',
          timestamp: DateTime(2024, 1, 1),
          format: ExportFormat.json,
          fileName: '',
          fileSize: 0,
          recordCount: 0,
          status: ExportStatus.failed,
          errorMessage: 'Test error',
        );

        expect(history.status, ExportStatus.failed);
        expect(history.errorMessage, 'Test error');
      });
    });
  });
}
