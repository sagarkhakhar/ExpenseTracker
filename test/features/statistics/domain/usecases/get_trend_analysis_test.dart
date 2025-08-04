import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';
import 'package:expense_tracker/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/get_trend_analysis.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  late GetTrendAnalysis useCase;
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    useCase = GetTrendAnalysis(mockRepository);
  });

  final tTrendAnalysis = TrendAnalysis(
    period: 'monthly',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
    totalSpending: 2500.0,
    categoryBreakdown: {
      'Food': 800.0,
      'Transport': 500.0,
      'Entertainment': 1200.0
    },
    trendDirection: TrendDirection.increasing,
    percentageChange: 15.5,
    createdAt: DateTime(2024, 1, 31),
  );

  group('GetTrendAnalysis', () {
    group('callByPeriod', () {
      test('should get trend analysis by period when valid period provided',
          () async {
        // arrange
        when(() => mockRepository.getTrendAnalysisByPeriod('monthly'))
            .thenAnswer((_) async => Right([tTrendAnalysis]));

        // act
        final result = await useCase.callByPeriod('monthly');

        // assert
        expect(result, isA<Right<Failure, List<TrendAnalysis>>>());
        expect(result.fold((l) => null, (r) => r), [tTrendAnalysis]);
        verify(() => mockRepository.getTrendAnalysisByPeriod('monthly'))
            .called(1);
      });

      test('should return ValidationFailure when period is empty', () async {
        // act
        final result = await useCase.callByPeriod('');

        // assert
        expect(result, const Left(ValidationFailure('Period cannot be empty')));
        verifyNever(() => mockRepository.getTrendAnalysisByPeriod(any()));
      });

      test('should return ValidationFailure when period is only whitespace',
          () async {
        // act
        final result = await useCase.callByPeriod('   ');

        // assert
        expect(result, const Left(ValidationFailure('Period cannot be empty')));
        verifyNever(() => mockRepository.getTrendAnalysisByPeriod(any()));
      });

      test('should return ValidationFailure when period is invalid', () async {
        // act
        final result = await useCase.callByPeriod('invalid');

        // assert
        expect(
            result,
            const Left(ValidationFailure(
                'Period must be one of: daily, weekly, monthly, yearly')));
        verifyNever(() => mockRepository.getTrendAnalysisByPeriod(any()));
      });

      test('should accept case-insensitive period values', () async {
        // arrange
        when(() => mockRepository.getTrendAnalysisByPeriod('weekly'))
            .thenAnswer((_) async => Right([tTrendAnalysis]));

        // act
        final result = await useCase.callByPeriod('WEEKLY');

        // assert
        expect(result, isA<Right<Failure, List<TrendAnalysis>>>());
        expect(result.fold((l) => null, (r) => r), [tTrendAnalysis]);
        verify(() => mockRepository.getTrendAnalysisByPeriod('weekly'))
            .called(1);
      });

      test('should propagate repository failure', () async {
        // arrange
        const failure = ServerFailure('Database error');
        when(() => mockRepository.getTrendAnalysisByPeriod('daily'))
            .thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase.callByPeriod('daily');

        // assert
        expect(result, const Left(failure));
        verify(() => mockRepository.getTrendAnalysisByPeriod('daily'))
            .called(1);
      });

      test('should return empty list when no trend analysis exists for period',
          () async {
        // arrange
        when(() => mockRepository.getTrendAnalysisByPeriod('yearly'))
            .thenAnswer((_) async => const Right([]));

        // act
        final result = await useCase.callByPeriod('yearly');

        // assert
        expect(result, isA<Right<Failure, List<TrendAnalysis>>>());
        expect(result.fold((l) => null, (r) => r), isEmpty);
        verify(() => mockRepository.getTrendAnalysisByPeriod('yearly'))
            .called(1);
      });
    });

    group('callByDateRange', () {
      test('should get trend analysis by date range when valid dates provided',
          () async {
        // arrange
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();
        when(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .thenAnswer((_) async => Right([tTrendAnalysis]));

        // act
        final result = await useCase.callByDateRange(startDate, endDate);

        // assert
        expect(result, isA<Right<Failure, List<TrendAnalysis>>>());
        expect(result.fold((l) => null, (r) => r), [tTrendAnalysis]);
        verify(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .called(1);
      });

      test('should return ValidationFailure when start date is after end date',
          () async {
        // arrange
        final startDate = DateTime(2024, 12, 31);
        final endDate = DateTime(2024, 1, 1);

        // act
        final result = await useCase.callByDateRange(startDate, endDate);

        // assert
        expect(
            result,
            const Left(
                ValidationFailure('Start date cannot be after end date')));
        verifyNever(
            () => mockRepository.getTrendAnalysisByDateRange(any(), any()));
      });

      test('should return ValidationFailure when date range exceeds 5 years',
          () async {
        // arrange
        final startDate = DateTime(2019, 1, 1);
        final endDate = DateTime(2024, 12, 31);

        // act
        final result = await useCase.callByDateRange(startDate, endDate);

        // assert
        expect(result,
            const Left(ValidationFailure('Date range cannot exceed 5 years')));
        verifyNever(
            () => mockRepository.getTrendAnalysisByDateRange(any(), any()));
      });

      test('should accept date range of exactly 5 years', () async {
        // arrange
        final startDate =
            DateTime.now().subtract(const Duration(days: 1825)); // 5 years ago
        final endDate = DateTime.now();
        when(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .thenAnswer((_) async => Right([tTrendAnalysis]));

        // act
        final result = await useCase.callByDateRange(startDate, endDate);

        // assert
        expect(result, isA<Right<Failure, List<TrendAnalysis>>>());
        expect(result.fold((l) => null, (r) => r), [tTrendAnalysis]);
        verify(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .called(1);
      });

      test('should propagate repository failure', () async {
        // arrange
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();
        const failure = ServerFailure('Database error');
        when(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase.callByDateRange(startDate, endDate);

        // assert
        expect(result, const Left(failure));
        verify(() =>
                mockRepository.getTrendAnalysisByDateRange(startDate, endDate))
            .called(1);
      });
    });

    group('callLatest', () {
      test('should get latest trend analysis when valid period provided',
          () async {
        // arrange
        when(() => mockRepository.getLatestTrendAnalysis('monthly'))
            .thenAnswer((_) async => Right(tTrendAnalysis));

        // act
        final result = await useCase.callLatest('monthly');

        // assert
        expect(result, isA<Right<Failure, TrendAnalysis?>>());
        expect(result.fold((l) => null, (r) => r), tTrendAnalysis);
        verify(() => mockRepository.getLatestTrendAnalysis('monthly'))
            .called(1);
      });

      test('should return ValidationFailure when period is empty', () async {
        // act
        final result = await useCase.callLatest('');

        // assert
        expect(result, const Left(ValidationFailure('Period cannot be empty')));
        verifyNever(() => mockRepository.getLatestTrendAnalysis(any()));
      });

      test('should return ValidationFailure when period is invalid', () async {
        // act
        final result = await useCase.callLatest('invalid');

        // assert
        expect(
            result,
            const Left(ValidationFailure(
                'Period must be one of: daily, weekly, monthly, yearly')));
        verifyNever(() => mockRepository.getLatestTrendAnalysis(any()));
      });

      test('should accept case-insensitive period values', () async {
        // arrange
        when(() => mockRepository.getLatestTrendAnalysis('daily'))
            .thenAnswer((_) async => Right(tTrendAnalysis));

        // act
        final result = await useCase.callLatest('DAILY');

        // assert
        expect(result, isA<Right<Failure, TrendAnalysis?>>());
        expect(result.fold((l) => null, (r) => r), tTrendAnalysis);
        verify(() => mockRepository.getLatestTrendAnalysis('daily')).called(1);
      });

      test('should return null when no latest trend analysis exists', () async {
        // arrange
        when(() => mockRepository.getLatestTrendAnalysis('weekly'))
            .thenAnswer((_) async => const Right(null));

        // act
        final result = await useCase.callLatest('weekly');

        // assert
        expect(result, isA<Right<Failure, TrendAnalysis?>>());
        expect(result.fold((l) => null, (r) => r), isNull);
        verify(() => mockRepository.getLatestTrendAnalysis('weekly')).called(1);
      });

      test('should propagate repository failure', () async {
        // arrange
        const failure = ServerFailure('Database error');
        when(() => mockRepository.getLatestTrendAnalysis('yearly'))
            .thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase.callLatest('yearly');

        // assert
        expect(result, const Left(failure));
        verify(() => mockRepository.getLatestTrendAnalysis('yearly')).called(1);
      });
    });
  });
}
