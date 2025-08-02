import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/get_financial_goals.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  late GetFinancialGoals useCase;
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    useCase = GetFinancialGoals(mockRepository);
  });

  final tGoals = [
    FinancialGoal(
      id: '1',
      title: 'Save for Vacation',
      targetAmount: 5000.0,
      currentAmount: 1000.0,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      targetDate: DateTime.now().add(const Duration(days: 300)),
      category: 'Travel',
      status: GoalStatus.active,
    ),
    FinancialGoal(
      id: '2',
      title: 'Emergency Fund',
      targetAmount: 10000.0,
      currentAmount: 7500.0,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      targetDate: DateTime.now().add(const Duration(days: 150)),
      category: 'Savings',
      status: GoalStatus.active,
    ),
  ];

  group('GetFinancialGoals', () {
    test('should get all financial goals from repository', () async {
      // arrange
      when(() => mockRepository.getFinancialGoals())
          .thenAnswer((_) async => Right(tGoals));

      // act
      final result = await useCase();

      // assert
      expect(result, Right(tGoals));
      verify(() => mockRepository.getFinancialGoals()).called(1);
    });

    test('should return empty list when no goals exist', () async {
      // arrange
      when(() => mockRepository.getFinancialGoals())
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase();

      // assert
      expect(result, isA<Right<Failure, List<FinancialGoal>>>());
      expect(result.fold((l) => null, (r) => r), isEmpty);
      verify(() => mockRepository.getFinancialGoals()).called(1);
    });

    test('should propagate repository failure', () async {
      // arrange
      final failure = ServerFailure('Database error');
      when(() => mockRepository.getFinancialGoals())
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase();

      // assert
      expect(result, Left(failure));
      verify(() => mockRepository.getFinancialGoals()).called(1);
    });

    test('should propagate cache failure', () async {
      // arrange
      final failure = CacheFailure('Cache error');
      when(() => mockRepository.getFinancialGoals())
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase();

      // assert
      expect(result, Left(failure));
      verify(() => mockRepository.getFinancialGoals()).called(1);
    });
  });
}
