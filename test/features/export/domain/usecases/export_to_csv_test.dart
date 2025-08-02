import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/repositories/export_repository.dart';
import 'package:expense_tracker/features/export/domain/services/export_service.dart';
import 'package:expense_tracker/features/export/domain/usecases/export_to_csv.dart';

class MockExportService extends Mock implements ExportService {}

class MockExportRepository extends Mock implements ExportRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ExportHistory(
      id: 'fallback-id',
      timestamp: DateTime(2024, 1, 1),
      format: ExportFormat.csv,
      fileName: 'fallback.csv',
      fileSize: 0,
      recordCount: 0,
      status: ExportStatus.success,
    ));
  });
  group('ExportToCsv', () {
    late ExportToCsv useCase;
    late MockExportService mockExportService;
    late MockExportRepository mockExportRepository;

    setUp(() {
      mockExportService = MockExportService();
      mockExportRepository = MockExportRepository();
      useCase = ExportToCsv(
        exportService: mockExportService,
        exportRepository: mockExportRepository,
      );
    });

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

    test('should export expenses to CSV successfully', () async {
      // Arrange
      when(() => mockExportService.exportToCsv(testExpenses))
          .thenAnswer((_) async => testExportHistory);
      when(() => mockExportRepository.saveExportHistory(testExportHistory))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testExpenses);

      // Assert
      expect(result.isRight(), isTrue);
      final exportHistory = result.fold((l) => null, (r) => r);
      expect(exportHistory, equals(testExportHistory));
      verify(() => mockExportService.exportToCsv(testExpenses)).called(1);
      verify(() => mockExportRepository.saveExportHistory(testExportHistory))
          .called(1);
    });

    test('should return failure when repository save fails', () async {
      // Arrange
      when(() => mockExportService.exportToCsv(testExpenses))
          .thenAnswer((_) async => testExportHistory);
      when(() => mockExportRepository.saveExportHistory(testExportHistory))
          .thenAnswer((_) async => const Left(DatabaseFailure('Save failed')));

      // Act
      final result = await useCase(testExpenses);

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<DatabaseFailure>());
      verify(() => mockExportService.exportToCsv(testExpenses)).called(1);
      verify(() => mockExportRepository.saveExportHistory(testExportHistory))
          .called(1);
    });

    test('should return failure when service throws exception', () async {
      // Arrange
      when(() => mockExportService.exportToCsv(testExpenses))
          .thenThrow(Exception('Service error'));

      // Act
      final result = await useCase(testExpenses);

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<DatabaseFailure>());
      verify(() => mockExportService.exportToCsv(testExpenses)).called(1);
      verifyNever(() => mockExportRepository.saveExportHistory(any()));
    });
  });
}
