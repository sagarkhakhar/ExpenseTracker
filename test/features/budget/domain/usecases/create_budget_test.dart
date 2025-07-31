import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/domain/usecases/create_budget.dart';
import 'package:expense_tracker/core/errors/failures.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late CreateBudget useCase;
  late MockBudgetRepository mockRepository;

  setUp(() {
    mockRepository = MockBudgetRepository();
    useCase = CreateBudget(mockRepository);
  });

  final testBudget = Budget(
    id: '1',
    categoryId: 'food',
    amount: 100.0,
    period: 'monthly',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('CreateBudget', () {
    test('should create budget successfully', () async {
      // arrange
      when(() => mockRepository.createBudget(testBudget))
          .thenAnswer((_) async => {});

      // act
      final result = await useCase(testBudget);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.createBudget(testBudget)).called(1);
    });

    test('should return ServerFailure when repository throws exception', () async {
      // arrange
      when(() => mockRepository.createBudget(testBudget))
          .thenThrow(Exception('Database error'));

      // act
      final result = await useCase(testBudget);

      // assert
      expect(result, isA<Left<Failure, void>>());
      expect(result.fold(
        (failure) => failure,
        (_) => null,
      ), isA<ServerFailure>());
      verify(() => mockRepository.createBudget(testBudget)).called(1);
    });
  });
} 