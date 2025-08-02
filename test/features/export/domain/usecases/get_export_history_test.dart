import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/repositories/export_repository.dart';
import 'package:expense_tracker/features/export/domain/usecases/get_export_history.dart';

class MockExportRepository extends Mock implements ExportRepository {}

void main() {
  group('GetExportHistory', () {
    late GetExportHistory useCase;
    late MockExportRepository mockExportRepository;

    setUp(() {
      mockExportRepository = MockExportRepository();
      useCase = GetExportHistory(
        exportRepository: mockExportRepository,
      );
    });

    final testExportHistory = [
      ExportHistory(
        id: 'test-id-1',
        timestamp: DateTime(2024, 1, 1),
        format: ExportFormat.csv,
        fileName: 'test1.csv',
        fileSize: 1024,
        recordCount: 10,
        status: ExportStatus.success,
      ),
      ExportHistory(
        id: 'test-id-2',
        timestamp: DateTime(2024, 1, 2),
        format: ExportFormat.json,
        fileName: 'test2.json',
        fileSize: 2048,
        recordCount: 20,
        status: ExportStatus.success,
      ),
    ];

    test('should get export history successfully', () async {
      // Arrange
      when(() => mockExportRepository.getExportHistory())
          .thenAnswer((_) async => Right(testExportHistory));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      final exportHistory = result.fold((l) => [], (r) => r);
      expect(exportHistory, equals(testExportHistory));
      expect(exportHistory.length, 2);
      verify(() => mockExportRepository.getExportHistory()).called(1);
    });

    test('should return empty list when no export history exists', () async {
      // Arrange
      when(() => mockExportRepository.getExportHistory())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      final exportHistory = result.fold((l) => [], (r) => r);
      expect(exportHistory, isEmpty);
      verify(() => mockExportRepository.getExportHistory()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      when(() => mockExportRepository.getExportHistory())
          .thenAnswer((_) async => const Left(DatabaseFailure('Repository error')));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<DatabaseFailure>());
      verify(() => mockExportRepository.getExportHistory()).called(1);
    });

    test('should return failure when repository throws exception', () async {
      // Arrange
      when(() => mockExportRepository.getExportHistory())
          .thenThrow(Exception('Repository error'));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<DatabaseFailure>());
      verify(() => mockExportRepository.getExportHistory()).called(1);
    });
  });
}
