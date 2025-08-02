import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/usecases/export_to_csv.dart';
import 'package:expense_tracker/features/export/domain/usecases/export_to_json.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_providers.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class MockExportToCsv extends Mock implements ExportToCsv {}

class MockExportToJson extends Mock implements ExportToJson {}

void main() {
  setUpAll(() {
    registerFallbackValue([]);
  });

  group('ExportState', () {
    test('should create initial state correctly', () {
      const state = ExportState();

      expect(state.isExporting, false);
      expect(state.error, isNull);
      expect(state.lastExport, isNull);
    });

    test('should create state with custom values', () {
      const error = 'Test error';
      final lastExport = ExportHistory(
        id: 'test-id',
        timestamp: DateTime(2024, 1, 1),
        format: ExportFormat.csv,
        fileName: 'test.csv',
        fileSize: 1024,
        recordCount: 10,
        status: ExportStatus.success,
      );

      final state = ExportState(
        isExporting: true,
        error: error,
        lastExport: lastExport,
      );

      expect(state.isExporting, true);
      expect(state.error, error);
      expect(state.lastExport, lastExport);
    });

    test('should copy with new values', () {
      const initialState = ExportState();
      const newError = 'New error';
      final newExport = ExportHistory(
        id: 'new-id',
        timestamp: DateTime(2024, 1, 2),
        format: ExportFormat.json,
        fileName: 'new.json',
        fileSize: 2048,
        recordCount: 20,
        status: ExportStatus.success,
      );

      final newState = initialState.copyWith(
        isExporting: true,
        error: newError,
        lastExport: newExport,
      );

      expect(newState.isExporting, true);
      expect(newState.error, newError);
      expect(newState.lastExport, newExport);
    });

    test('should copy with partial values', () {
      final initialState = ExportState(
        isExporting: true,
        error: 'Old error',
        lastExport: ExportHistory(
          id: 'old-id',
          timestamp: DateTime(2024, 1, 1),
          format: ExportFormat.csv,
          fileName: 'old.csv',
          fileSize: 1024,
          recordCount: 10,
          status: ExportStatus.success,
        ),
      );

      final newState = initialState.copyWith(isExporting: false);

      expect(newState.isExporting, false);
      expect(newState.error, 'Old error');
      expect(newState.lastExport, isNotNull);
    });
  });

  group('ExportStateNotifier', () {
    late ExportStateNotifier notifier;
    late MockExportToCsv mockExportToCsv;
    late MockExportToJson mockExportToJson;

    setUp(() {
      mockExportToCsv = MockExportToCsv();
      mockExportToJson = MockExportToJson();
      notifier = ExportStateNotifier(
        exportToCsv: mockExportToCsv,
        exportToJson: mockExportToJson,
      );
    });

    test('should have initial state', () {
      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.lastExport, isNull);
    });

    test('should export to CSV successfully', () async {
      final testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense',
          description: 'Test Description',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      final testExportHistory = ExportHistory(
        id: 'test-id',
        timestamp: DateTime(2024, 1, 1),
        format: ExportFormat.csv,
        fileName: 'test.csv',
        fileSize: 1024,
        recordCount: 1,
        status: ExportStatus.success,
      );

      when(() => mockExportToCsv(testExpenses))
          .thenAnswer((_) async => Right(testExportHistory));

      await notifier.exportToCsv(testExpenses);

      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.lastExport, equals(testExportHistory));
      verify(() => mockExportToCsv(testExpenses)).called(1);
    });

    test('should export to JSON successfully', () async {
      final testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense',
          description: 'Test Description',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      final testExportHistory = ExportHistory(
        id: 'test-id',
        timestamp: DateTime(2024, 1, 1),
        format: ExportFormat.json,
        fileName: 'test.json',
        fileSize: 1024,
        recordCount: 1,
        status: ExportStatus.success,
      );

      when(() => mockExportToJson(testExpenses))
          .thenAnswer((_) async => Right(testExportHistory));

      await notifier.exportToJson(testExpenses);

      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.lastExport, equals(testExportHistory));
      verify(() => mockExportToJson(testExpenses)).called(1);
    });

    test('should handle CSV export failure', () async {
      final testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense',
          description: 'Test Description',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockExportToCsv(testExpenses))
          .thenAnswer((_) async => const Left(DatabaseFailure('Export failed')));

      await notifier.exportToCsv(testExpenses);

      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, 'Export failed');
      expect(notifier.state.lastExport, isNull);
      verify(() => mockExportToCsv(testExpenses)).called(1);
    });

    test('should handle JSON export failure', () async {
      final testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense',
          description: 'Test Description',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockExportToJson(testExpenses))
          .thenAnswer((_) async => const Left(DatabaseFailure('Export failed')));

      await notifier.exportToJson(testExpenses);

      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, 'Export failed');
      expect(notifier.state.lastExport, isNull);
      verify(() => mockExportToJson(testExpenses)).called(1);
    });

    test('should handle export exception', () async {
      final testExpenses = [
        Expense(
          id: '1',
          title: 'Test Expense',
          description: 'Test Description',
          amount: 100.0,
          category: 'Food',
          date: DateTime(2024, 1, 1),
          type: ExpenseType.expense,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(() => mockExportToCsv(testExpenses))
          .thenThrow(Exception('Unexpected error'));

      await notifier.exportToCsv(testExpenses);

      expect(notifier.state.isExporting, false);
      expect(notifier.state.error, 'Exception: Unexpected error');
      expect(notifier.state.lastExport, isNull);
      verify(() => mockExportToCsv(testExpenses)).called(1);
    });

    test('should have clear error method', () {
      expect(notifier.clearError, isA<Function>());
    });

    test('should have clear last export method', () {
      expect(notifier.clearLastExport, isA<Function>());
    });
  });
}
