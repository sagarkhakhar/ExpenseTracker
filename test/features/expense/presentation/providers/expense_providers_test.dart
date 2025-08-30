import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/create_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_all_expenses.dart';
import 'package:expense_tracker/features/expense/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expense/data/datasources/expense_local_data_source_impl.dart';
import 'package:expense_tracker/core/errors/failures.dart';

// Mock classes
class MockExpenseLocalDataSourceImpl extends Mock implements ExpenseLocalDataSourceImpl {}
class MockExpenseRepositoryImpl extends Mock implements ExpenseRepositoryImpl {}
class MockCreateExpense extends Mock implements CreateExpense {}
class MockGetAllExpenses extends Mock implements GetAllExpenses {}
class MockUpdateExpense extends Mock implements UpdateExpense {}

// Fake classes for fallback values
class FakeExpense extends Fake implements Expense {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeExpense());
  });

  // Test data
  final testExpense = Expense(
    id: 'expense-1',
    title: 'Test Expense',
    description: 'A test expense',
    amount: 100.0,
    category: 'Food',
    date: DateTime(2024, 1, 1),
    type: ExpenseType.expense,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testExpenses = [testExpense];
  const testFailure = DatabaseFailure('Test error');

  group('Expense Providers', () {
    group('Repository Provider with Mocks', () {
      test('should provide expense repository instance when mocked', () {
        final mockDataSource = MockExpenseLocalDataSourceImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(expenseRepositoryProvider);
        expect(repository, isA<ExpenseRepositoryImpl>());
      });
    });

    group('Use Case Providers with Mocks', () {
      late MockExpenseLocalDataSourceImpl mockDataSource;
      late MockExpenseRepositoryImpl mockRepository;

      setUp(() {
        mockDataSource = MockExpenseLocalDataSourceImpl();
        mockRepository = MockExpenseRepositoryImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});
      });

      test('should provide GetAllExpenses use case', () {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = container.read(getAllExpensesProvider);
        expect(useCase, isA<GetAllExpenses>());
      });

      test('should provide CreateExpense use case', () {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = container.read(createExpenseProvider);
        expect(useCase, isA<CreateExpense>());
      });

      test('should provide UpdateExpense use case', () {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = container.read(updateExpenseProvider);
        expect(useCase, isA<UpdateExpense>());
      });
    });

    group('ExpenseNotifier', () {
      late MockGetAllExpenses mockGetAllExpenses;
      late MockCreateExpense mockCreateExpense;
      late MockUpdateExpense mockUpdateExpense;

      setUp(() {
        mockGetAllExpenses = MockGetAllExpenses();
        mockCreateExpense = MockCreateExpense();
        mockUpdateExpense = MockUpdateExpense();
      });

      test('should load expenses successfully', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        // Act - read the notifier to trigger initial load
        final notifier = container.read(expenseNotifierProvider.notifier);
        
        // Wait for state to update
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert
        final state = container.read(expenseNotifierProvider);
        expect(state.hasValue, true);
        expect(state.value, testExpenses);
        verify(() => mockGetAllExpenses()).called(1);
      });

      test('should handle load expenses error', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        // Act - read the notifier to trigger initial load
        final notifier = container.read(expenseNotifierProvider.notifier);
        
        // Wait for state to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = container.read(expenseNotifierProvider);
        expect(state.hasError, true);
        verify(() => mockGetAllExpenses()).called(1);
      });

      test('should create expense successfully', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => Right(testExpenses));
        when(() => mockCreateExpense(any())).thenAnswer((_) async => Right(testExpense));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
            createExpenseProvider.overrideWith((ref) => mockCreateExpense),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final notifier = container.read(expenseNotifierProvider.notifier);
        await notifier.addExpense(
          title: 'Test Expense',
          description: 'A test expense',
          amount: 100.0,
          category: 'Food',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 1),
        );

        // Assert
        verify(() => mockCreateExpense(any())).called(1);
        verify(() => mockGetAllExpenses()).called(greaterThanOrEqualTo(2)); // Initial load + reload after create
      });

      test('should handle create expense error', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => Right(testExpenses));
        when(() => mockCreateExpense(any())).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
            createExpenseProvider.overrideWith((ref) => mockCreateExpense),
          ],
        );
        addTearDown(container.dispose);

        // Act & Assert
        final notifier = container.read(expenseNotifierProvider.notifier);
        expect(
          () => notifier.addExpense(
            title: 'Test Expense',
            description: 'A test expense',
            amount: 100.0,
            category: 'Food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
          ),
          throwsException,
        );
      });

      test('should update expense successfully', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => Right(testExpenses));
        when(() => mockUpdateExpense(any())).thenAnswer((_) async => Right(testExpense));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
            updateExpenseProvider.overrideWith((ref) => mockUpdateExpense),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final notifier = container.read(expenseNotifierProvider.notifier);
        await notifier.updateExpense(testExpense);

        // Assert
        verify(() => mockUpdateExpense(testExpense)).called(1);
        verify(() => mockGetAllExpenses()).called(greaterThanOrEqualTo(2)); // Initial load + reload after update
      });

      test('should handle update expense error', () async {
        // Arrange
        when(() => mockGetAllExpenses()).thenAnswer((_) async => Right(testExpenses));
        when(() => mockUpdateExpense(any())).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) => mockGetAllExpenses),
            updateExpenseProvider.overrideWith((ref) => mockUpdateExpense),
          ],
        );
        addTearDown(container.dispose);

        // Act & Assert
        final notifier = container.read(expenseNotifierProvider.notifier);
        expect(
          () => notifier.updateExpense(testExpense),
          throwsException,
        );
      });
    });
  });
}