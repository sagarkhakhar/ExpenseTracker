import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/create_financial_goal.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  late CreateFinancialGoal useCase;
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
    useCase = CreateFinancialGoal(mockRepository);
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

  group('CreateFinancialGoal', () {
    test('should create a financial goal when all validations pass', () async {
      // arrange
      when(() => mockRepository.saveFinancialGoal(tGoal))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.saveFinancialGoal(tGoal)).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      // arrange
      final invalidGoal = tGoal.copyWith(title: '');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result, const Left(ValidationFailure('Goal title cannot be empty')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when title is only whitespace',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(title: '   ');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result, const Left(ValidationFailure('Goal title cannot be empty')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
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
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when target amount is negative',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(targetAmount: -100.0);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Target amount must be positive and finite')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when target amount is NaN', () async {
      // arrange
      final invalidGoal = tGoal.copyWith(targetAmount: double.nan);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Target amount must be positive and finite')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when target amount is infinite',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(targetAmount: double.infinity);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Target amount must be positive and finite')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when current amount is negative',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(currentAmount: -100.0);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result,
          const Left(ValidationFailure('Current amount must be non-negative')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when current amount is NaN',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(currentAmount: double.nan);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result,
          const Left(ValidationFailure('Current amount must be non-negative')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when current amount is infinite',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(currentAmount: double.infinity);

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result,
          const Left(ValidationFailure('Current amount must be non-negative')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
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
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when start date is in the future',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(
        startDate: DateTime.now().add(const Duration(days: 1)),
      );

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(result,
          const Left(ValidationFailure('Start date cannot be in the future')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test(
        'should return ValidationFailure when target date is before start date',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(
        startDate: DateTime(2024, 12, 31),
        targetDate: DateTime(2024, 1, 1),
      );

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Target date must be after start date')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
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
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
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
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should return ValidationFailure when category is only whitespace',
        () async {
      // arrange
      final invalidGoal = tGoal.copyWith(category: '   ');

      // act
      final result = await useCase(invalidGoal);

      // assert
      expect(
          result,
          const Left(
              ValidationFailure('Category cannot be empty if provided')));
      verifyNever(() => mockRepository.saveFinancialGoal(any()));
    });

    test('should create goal successfully when category is null', () async {
      // arrange
      final goalWithNullCategory = tGoal.copyWith(category: null);
      when(() => mockRepository.saveFinancialGoal(goalWithNullCategory))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(goalWithNullCategory);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.saveFinancialGoal(goalWithNullCategory))
          .called(1);
    });

    test('should create goal successfully when current amount is zero',
        () async {
      // arrange
      final goalWithZeroCurrent = tGoal.copyWith(currentAmount: 0.0);
      when(() => mockRepository.saveFinancialGoal(goalWithZeroCurrent))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(goalWithZeroCurrent);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.saveFinancialGoal(goalWithZeroCurrent))
          .called(1);
    });

    test(
        'should create goal successfully when current amount equals target amount',
        () async {
      // arrange
      final goalWithEqualAmounts = tGoal.copyWith(
        targetAmount: 1000.0,
        currentAmount: 1000.0,
      );
      when(() => mockRepository.saveFinancialGoal(goalWithEqualAmounts))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(goalWithEqualAmounts);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.saveFinancialGoal(goalWithEqualAmounts))
          .called(1);
    });

    test('should propagate repository failure', () async {
      // arrange
      const failure = ServerFailure('Database error');
      when(() => mockRepository.saveFinancialGoal(tGoal))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(tGoal);

      // assert
      expect(result, const Left(failure));
      verify(() => mockRepository.saveFinancialGoal(tGoal)).called(1);
    });
  });
}
