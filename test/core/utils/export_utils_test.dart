import 'dart:io';
import 'dart:convert'; // Added for jsonDecode
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/export_utils.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('ExportUtils', () {
    late List<Expense> testExpenses;
    late Directory tempDir;

    setUp(() {
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
          description: '',
          amount: 200.0,
          category: 'Transport',
          date: DateTime(2024, 1, 2),
          type: ExpenseType.income,
          createdAt: DateTime(2024, 1, 2, 10, 0, 0),
          updatedAt: DateTime(2024, 1, 2, 10, 0, 0),
        ),
      ];

      tempDir = Directory.systemTemp.createTempSync('export_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('exportToCsv', () {
      test('should export expenses to CSV format with headers', () {
        final csv = ExportUtils.exportToCsv(testExpenses);

        expect(csv, isNotEmpty);
        expect(
            csv,
            contains(
                'ID,Title,Description,Amount,Category,Date,Type,Created At,Updated At'));
        expect(
            csv,
            contains(
                '1,Test Expense 1,Test Description 1,100.0,Food,2024-01-01T00:00:00.000,expense,2024-01-01T10:00:00.000,2024-01-01T10:00:00.000'));
        expect(
            csv,
            contains(
                '2,Test Expense 2,,200.0,Transport,2024-01-02T00:00:00.000,income,2024-01-02T10:00:00.000,2024-01-02T10:00:00.000'));
      });

      test('should return empty string for empty expenses list', () {
        final csv = ExportUtils.exportToCsv([]);

        expect(csv, isEmpty);
      });

      test('should handle empty description correctly', () {
        final expenseWithEmptyDescription = [
          Expense(
            id: '1',
            title: 'Test',
            description: '',
            amount: 100.0,
            category: 'Food',
            date: DateTime(2024, 1, 1),
            type: ExpenseType.expense,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];

        final csv = ExportUtils.exportToCsv(expenseWithEmptyDescription);

        expect(
            csv,
            contains(
                '1,Test,,100.0,Food,2024-01-01T00:00:00.000,expense,2024-01-01T00:00:00.000,2024-01-01T00:00:00.000'));
      });
    });

    group('exportToJson', () {
      test('should export expenses to JSON format', () {
        final json = ExportUtils.exportToJson(testExpenses);

        expect(json, isNotEmpty);

        final jsonData = jsonDecode(json) as Map<String, dynamic>;
        expect(jsonData['totalRecords'], 2);
        expect(jsonData['expenses'], isA<List>());

        final expenses = jsonData['expenses'] as List;
        expect(expenses.length, 2);

        final firstExpense = expenses[0] as Map<String, dynamic>;
        expect(firstExpense['id'], '1');
        expect(firstExpense['title'], 'Test Expense 1');
        expect(firstExpense['description'], 'Test Description 1');
        expect(firstExpense['amount'], 100.0);
        expect(firstExpense['category'], 'Food');
        expect(firstExpense['type'], 'expense');
      });

      test('should handle empty description in JSON', () {
        final expenseWithEmptyDescription = [
          Expense(
            id: '1',
            title: 'Test',
            description: '',
            amount: 100.0,
            category: 'Food',
            date: DateTime(2024, 1, 1),
            type: ExpenseType.expense,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];

        final json = ExportUtils.exportToJson(expenseWithEmptyDescription);
        final jsonData = jsonDecode(json) as Map<String, dynamic>;
        final expenses = jsonData['expenses'] as List;
        final firstExpense = expenses[0] as Map<String, dynamic>;

        expect(firstExpense['description'], isEmpty);
      });

      test('should return valid JSON for empty expenses list', () {
        final json = ExportUtils.exportToJson([]);

        expect(json, isNotEmpty);
        final jsonData = jsonDecode(json) as Map<String, dynamic>;
        expect(jsonData['totalRecords'], 0);
        expect(jsonData['expenses'], isEmpty);
      });
    });

    group('generateFileName', () {
      test('should generate correct filename for CSV format', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30, 45);
        final fileName = ExportUtils.generateFileName('csv', timestamp);

        expect(fileName, 'expense_export_20240115_143045.csv');
      });

      test('should generate correct filename for JSON format', () {
        final timestamp = DateTime(2024, 12, 31, 23, 59, 59);
        final fileName = ExportUtils.generateFileName('json', timestamp);

        expect(fileName, 'expense_export_20241231_235959.json');
      });

      test('should handle single digit month and day', () {
        final timestamp = DateTime(2024, 1, 5, 9, 5, 5);
        final fileName = ExportUtils.generateFileName('csv', timestamp);

        expect(fileName, 'expense_export_20240105_090505.csv');
      });
    });

    group('saveToFile', () {
      test('should save data to file successfully', () async {
        const testData = 'test export data';
        const fileName = 'test_export.csv';

        final file = await ExportUtils.saveToFile(testData, fileName, tempDir);

        expect(file.existsSync(), isTrue);
        expect(await file.readAsString(), testData);
      });

      test('should create file with correct path', () async {
        const testData = 'test data';
        const fileName = 'test.csv';

        final file = await ExportUtils.saveToFile(testData, fileName, tempDir);

        expect(file.path, '${tempDir.path}/$fileName');
      });
    });

    group('getFileSize', () {
      test('should return correct file size', () async {
        const testData = 'test data for size calculation';
        const fileName = 'size_test.txt';

        final file = await ExportUtils.saveToFile(testData, fileName, tempDir);
        final fileSize = await ExportUtils.getFileSize(file);

        expect(fileSize, testData.length);
      });
    });

    group('validateExportData', () {
      test('should return true for non-empty expenses list', () {
        final isValid = ExportUtils.validateExportData(testExpenses);

        expect(isValid, isTrue);
      });

      test('should return false for empty expenses list', () {
        final isValid = ExportUtils.validateExportData([]);

        expect(isValid, isFalse);
      });
    });

    group('formatFileSize', () {
      test('should format bytes correctly', () {
        expect(ExportUtils.formatFileSize(500), '500 B');
        expect(ExportUtils.formatFileSize(0), '0 B');
      });

      test('should format kilobytes correctly', () {
        expect(ExportUtils.formatFileSize(1024), '1.0 KB');
        expect(ExportUtils.formatFileSize(1536), '1.5 KB');
        expect(ExportUtils.formatFileSize(2048), '2.0 KB');
      });

      test('should format megabytes correctly', () {
        expect(ExportUtils.formatFileSize(1024 * 1024), '1.0 MB');
        expect(
            ExportUtils.formatFileSize((1024 * 1024 * 2.5).round()), '2.5 MB');
      });

      test('should handle edge cases', () {
        expect(ExportUtils.formatFileSize(1023), '1023 B');
        expect(ExportUtils.formatFileSize(1024 * 1024 - 1), '1024.0 KB');
      });
    });
  });
}
