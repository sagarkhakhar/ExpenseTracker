import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/update_financial_goal.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  late UpdateFinancialGoal useCase;
  late MockStatisticsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FinancialGoal(
      id: 'fallback',
      title: 'Fallback Goal',
      targetAmount: 1000.0,
      currentAmount: 0.0,
      startDate: DateTime.now(),
      targetDate: DateTime.now().add(const Duration(days: 30)),
      category: 'General',
      status: GoalStatus.active,
    ));
  });

  setUp(() {
    mockRepository = MockStatisticsRepository();
    useCase = UpdateFinancialGoal(mockRepository);
  });

  final tGoal = FinancialGoal(
    id: '1',
    title: 'Save for Vacation',
    targetAmount: 5000.0,
    currentAmount: 1000.0,
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    targetDate: DateTime.now().add(const Duration(days: 300)),
    category: 'Travel',
    status: GoalStatus.active,
  );

  group('UpdateFinancialGoal', () {
    test(
        'should update a financial goal when all validations pass and goal exists',
        () async {
      // arrange
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => Right(tGoal));
      when(() => mockRepository.updateFinancialGoal(tGoal))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verify(() => mockRepository.updateFinancialGoal(tGoal)).called(1);
    });

    test('should return ValidationFailure when goal ID is empty', () async {
      // arrange
      final invalidGoal = tGoal.copyWith(id: '');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result, const Left(ValidationFailure('Goal ID cannot be empty')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should return ValidationFailure when title is empty', () async {
      // arrange
      final invalidGoal = tGoal.copyWith(title: '');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result, const Left(ValidationFailure('Goal title cannot be empty')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should return ValidationFailure when target amount is zero',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(targetAmount: 0.0);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Target amount must be positive and finite')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test(
        'should return ValidationFailure when current amount exceeds target amount',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(
        targetAmount: 1000.0,
        currentAmount: 1500.0,
      );

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Current amount cannot exceed target amount')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should return ValidationFailure when goal does not exist', () async {
      // arrange
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Left(ValidationFailure('Financial goal not found')));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should propagate repository failure when getting goal', () async {
      // arrange
      const failure = ServerFailure('Database error');
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should propagate repository failure when updating goal', () async {
      // arrange
      const failure = ServerFailure('Update error');
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => Right(tGoal));
      when(() => mockRepository.updateFinancialGoal(tGoal))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verify(() => mockRepository.updateFinancialGoal(tGoal)).called(1);
    });

    test('should update goal successfully when category is null', () async {
      // arrange
      final goalWithNullCategory = tGoal.copyWith(category: null);
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => Right(goalWithNullCategory));
      when(() => mockRepository.updateFinancialGoal(goalWithNullCategory))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(goalWithNullCategory);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verify(() => mockRepository.updateFinancialGoal(goalWithNullCategory))
          .called(1);
    });

    test(
        'should update goal successfully when current amount equals target amount',
        () async {
      // arrange
      final goalWithEqualAmounts = tGoal.copyWith(
        targetAmount: 1000.0,
        currentAmount: 1000.0,
      );
      when(() => mockRepository.getFinancialGoalById('1'))
          .thenAnswer((_) async => Right(goalWithEqualAmounts));
      when(() => mockRepository.updateFinancialGoal(goalWithEqualAmounts))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(goalWithEqualAmounts);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.getFinancialGoalById('1')).called(1);
      verify(() => mockRepository.updateFinancialGoal(goalWithEqualAmounts))
          .called(1);
    });

    test('should return ValidationFailure when target date is in the past',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result,
          const Left(ValidationFailure('Target date cannot be in the past')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });

    test('should return ValidationFailure when category is empty string',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(category: '');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Category cannot be empty if provided')));
      verifyNever(() => mockRepository.getFinancialGoalById(any()));
      verifyNever(() => mockRepository.updateFinancialGoal(any()));
    });
  });
}
