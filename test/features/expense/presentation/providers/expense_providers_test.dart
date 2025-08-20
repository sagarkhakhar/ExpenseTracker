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
      test('should provide expense repository instance when mocked', () async {
        final mockDataSource = MockExpenseLocalDataSourceImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) async => mockDataSource),
          ],
        );
        addTearDown(container.dispose);

        final repository = await container.read(expenseRepositoryProvider.future);
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

      test('should provide GetAllExpenses use case', () async {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) async => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) async => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = await container.read(getAllExpensesProvider.future);
        expect(useCase, isA<GetAllExpenses>());
      });

      test('should provide CreateExpense use case', () async {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) async => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) async => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = await container.read(createExpenseProvider.future);
        expect(useCase, isA<CreateExpense>());
      });

      test('should provide UpdateExpense use case', () async {
        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) async => mockDataSource),
            expenseRepositoryProvider.overrideWith((ref) async => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = await container.read(updateExpenseProvider.future);
        expect(useCase, isA<UpdateExpense>());
      });
    });

    group('ExpenseNotifier with Mocks', () {
      late MockGetAllExpenses mockGetAllExpenses;

      setUp(() {
        mockGetAllExpenses = MockGetAllExpenses();
      });

      test('should start with loading state', () {
        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(expenseNotifierProvider);
        expect(state, isA<AsyncLoading>());
      });

      test('should load expenses on refresh success', () async {
        when(() => mockGetAllExpenses.call()).thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(expenseNotifierProvider.notifier);
        await notifier.refresh();

        final state = container.read(expenseNotifierProvider);
        expect(state.hasValue, isTrue);
        if (state.hasValue) {
          expect(state.value, equals(testExpenses));
        }
      });

      test('should handle error when loading expenses fails', () async {
        when(() => mockGetAllExpenses.call()).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(expenseNotifierProvider.notifier);
        await notifier.refresh();

        final state = container.read(expenseNotifierProvider);
        expect(state, isA<AsyncError>());
      });

      test('addExpense should create expense and refresh list', () async {
        final mockCreateExpense = MockCreateExpense();
        when(() => mockCreateExpense(any())).thenAnswer((_) async => Right(testExpense));
        when(() => mockGetAllExpenses.call()).thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
            createExpenseProvider.overrideWith((ref) async => mockCreateExpense),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(expenseNotifierProvider.notifier);
        
        await notifier.addExpense(
          title: 'New Expense',
          description: 'Test expense',
          amount: 50.0,
          category: 'Food',
          type: ExpenseType.expense,
          date: DateTime.now(),
        );

        // Verify create expense was called
        verify(() => mockCreateExpense(any())).called(1);
        // Verify expenses were reloaded
        verify(() => mockGetAllExpenses.call()).called(greaterThanOrEqualTo(1));
      });

      test('updateExpense should update expense and refresh list', () async {
        final mockUpdateExpense = MockUpdateExpense();
        when(() => mockUpdateExpense(any())).thenAnswer((_) async => Right(testExpense));
        when(() => mockGetAllExpenses.call()).thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
            updateExpenseProvider.overrideWith((ref) async => mockUpdateExpense),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(expenseNotifierProvider.notifier);
        
        await notifier.updateExpense(testExpense);

        // Verify update expense was called
        verify(() => mockUpdateExpense(testExpense)).called(1);
        // Verify expenses were reloaded
        verify(() => mockGetAllExpenses.call()).called(greaterThanOrEqualTo(1));
      });

      test('deleteExpense should delete expense and refresh list', () async {
        when(() => mockGetAllExpenses.call()).thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            getAllExpensesProvider.overrideWith((ref) async => mockGetAllExpenses),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(expenseNotifierProvider.notifier);
        
        await notifier.deleteExpense('expense-1');

        // Verify expenses were reloaded
        verify(() => mockGetAllExpenses.call()).called(greaterThanOrEqualTo(1));
      });
    });

    group('Provider Types', () {
      test('should have correct provider types', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Test that all providers return the correct types without calling them
        expect(expenseLocalDataSourceProvider, isA<FutureProvider<ExpenseLocalDataSourceImpl>>());
        expect(expenseRepositoryProvider, isA<FutureProvider<ExpenseRepositoryImpl>>());
        expect(getAllExpensesProvider, isA<FutureProvider<GetAllExpenses>>());
        expect(createExpenseProvider, isA<FutureProvider<CreateExpense>>());
        expect(updateExpenseProvider, isA<FutureProvider<UpdateExpense>>());
        expect(expenseNotifierProvider, isA<StateNotifierProvider>());
        expect(expenseStatsNotifierProvider, isA<StateNotifierProvider>());
      });
    });
  });
}