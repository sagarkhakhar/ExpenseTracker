import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/core/errors/failures.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late GetBudgets getBudgetsUseCase;
  late GetBudgetsByCategory getBudgetsByCategoryUseCase;
  late GetActiveBudgets getActiveBudgetsUseCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    getBudgetsUseCase = GetBudgets(mockRepository);
    getBudgetsByCategoryUseCase = GetBudgetsByCategory(mockRepository);
    getActiveBudgetsUseCase = GetActiveBudgets(mockRepository);
  });

  final testBudgets = [
    Budget(
      id: '1',
      categoryId: 'food',
      amount: 100.0,
      period: 'monthly',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Budget(
      id: '2',
      categoryId: 'transport',
      amount: 50.0,
      period: 'monthly',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('GetBudgets', () {
    test('should get all budgets successfully', () async {
      // arrange
      when(() => mockRepository.getAllBudgets())
          .thenAnswer((_) async => testBudgets);

      // act
      final result = await getBudgetsUseCase();

      // assert
      expect(result, Right(testBudgets));
      verify(() => mockRepository.getAllBudgets()).called(1);
    });

    test('should return ServerFailure when repository throws exception', () async {
      // arrange
      when(() => mockRepository.getAllBudgets())
          .thenThrow(Exception('Database error'));

      // act
      final result = await getBudgetsUseCase();

      // assert
      expect(result, isA<Left<Failure, List<Budget>>>());
      expect(result.fold(
        (failure) => failure,
        (_) => null,
      ), isA<ServerFailure>());
      verify(() => mockRepository.getAllBudgets()).called(1);
    });
  });

  group('GetBudgetsByCategory', () {
    test('should get budgets by category successfully', () async {
      // arrange
      const categoryId = 'food';
      final foodBudgets = testBudgets.where((b) => b.categoryId == categoryId).toList();
      when(() => mockRepository.getBudgetsByCategory(categoryId))
          .thenAnswer((_) async => foodBudgets);

      // act
      final result = await getBudgetsByCategoryUseCase(categoryId);

      // assert
      expect(result, Right(foodBudgets));
      verify(() => mockRepository.getBudgetsByCategory(categoryId)).called(1);
    });

    test('should return ServerFailure when repository throws exception', () async {
      // arrange
      const categoryId = 'food';
      when(() => mockRepository.getBudgetsByCategory(categoryId))
          .thenThrow(Exception('Database error'));

      // act
      final result = await getBudgetsByCategoryUseCase(categoryId);

      // assert
      expect(result, isA<Left<Failure, List<Budget>>>());
      expect(result.fold(
        (failure) => failure,
        (_) => null,
      ), isA<ServerFailure>());
      verify(() => mockRepository.getBudgetsByCategory(categoryId)).called(1);
    });
  });

  group('GetActiveBudgets', () {
    test('should get active budgets successfully', () async {
      // arrange
      final activeBudgets = testBudgets.where((b) => b.isActive).toList();
      when(() => mockRepository.getActiveBudgets())
          .thenAnswer((_) async => activeBudgets);

      // act
      final result = await getActiveBudgetsUseCase();

      // assert
      expect(result, Right(activeBudgets));
      verify(() => mockRepository.getActiveBudgets()).called(1);
    });

    test('should return ServerFailure when repository throws exception', () async {
      // arrange
      when(() => mockRepository.getActiveBudgets())
          .thenThrow(Exception('Database error'));

      // act
      final result = await getActiveBudgetsUseCase();

      // assert
      expect(result, isA<Left<Failure, List<Budget>>>());
      expect(result.fold(
        (failure) => failure,
        (_) => null,
      ), isA<ServerFailure>());
      verify(() => mockRepository.getActiveBudgets()).called(1);
    });
  });
} 