import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/domain/usecases/create_budget.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budget/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/budget/domain/services/budget_service.dart';
import 'package:expense_tracker/features/budget/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/core/errors/failures.dart';

// Mock classes
class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockBudgetService extends Mock implements BudgetService {}
class MockCreateBudget extends Mock implements CreateBudget {}
class MockGetBudgets extends Mock implements GetBudgets {}
class MockGetBudgetsByCategory extends Mock implements GetBudgetsByCategory {}
class MockGetActiveBudgets extends Mock implements GetActiveBudgets {}
class MockUpdateBudget extends Mock implements UpdateBudget {}
class MockUpdateBudgetSpentAmount extends Mock implements UpdateBudgetSpentAmount {}

// Fake classes for fallback values
class FakeBudget extends Fake implements Budget {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeBudget());
  });
  // Test data
  final testBudget = Budget(
    id: 'budget-1',
    categoryId: 'category-1',
    amount: 1000.0,
    period: 'monthly',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
    spentAmount: 500.0,
    alertThreshold: 80.0,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testBudgets = [testBudget];
  const testFailure = DatabaseFailure('Test error');

  group('Budget Providers', () {
    group('Repository Provider', () {
      test('should provide budget repository instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repository = container.read(budgetRepositoryProvider);
        expect(repository, isA<BudgetRepository>());
      });
    });

    group('Use Case Providers', () {
      test('should provide CreateBudget use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(createBudgetProvider);
        expect(useCase, isA<CreateBudget>());
      });

      test('should provide GetBudgets use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(getBudgetsProvider);
        expect(useCase, isA<GetBudgets>());
      });

      test('should provide GetBudgetsByCategory use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(getBudgetsByCategoryProvider);
        expect(useCase, isA<GetBudgetsByCategory>());
      });

      test('should provide GetActiveBudgets use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(getActiveBudgetsProvider);
        expect(useCase, isA<GetActiveBudgets>());
      });

      test('should provide UpdateBudget use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(updateBudgetProvider);
        expect(useCase, isA<UpdateBudget>());
      });

      test('should provide UpdateBudgetSpentAmount use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(updateBudgetSpentAmountProvider);
        expect(useCase, isA<UpdateBudgetSpentAmount>());
      });
    });

    group('Service Provider', () {
      test('should provide budget service', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(budgetServiceProvider);
        expect(service, isA<BudgetService>());
      });
    });

    group('State Providers', () {
      late MockGetBudgets mockGetBudgets;
      late MockGetActiveBudgets mockGetActiveBudgets;
      late MockGetBudgetsByCategory mockGetBudgetsByCategory;
      late MockBudgetService mockBudgetService;

      setUp(() {
        mockGetBudgets = MockGetBudgets();
        mockGetActiveBudgets = MockGetActiveBudgets();
        mockGetBudgetsByCategory = MockGetBudgetsByCategory();
        mockBudgetService = MockBudgetService();
      });

      test('budgetsProvider should return budgets on success', () async {
        when(() => mockGetBudgets()).thenAnswer((_) async => Right(testBudgets));

        final container = ProviderContainer(
          overrides: [
            getBudgetsProvider.overrideWithValue(mockGetBudgets),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(budgetsProvider.future);
        expect(budgets, equals(testBudgets));
      });

      test('budgetsProvider should throw exception on failure', () async {
        when(() => mockGetBudgets()).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getBudgetsProvider.overrideWithValue(mockGetBudgets),
          ],
        );
        addTearDown(container.dispose);

        expect(() => container.read(budgetsProvider.future), throwsException);
      });

      test('activeBudgetsProvider should return active budgets on success', () async {
        when(() => mockGetActiveBudgets()).thenAnswer((_) async => Right(testBudgets));

        final container = ProviderContainer(
          overrides: [
            getActiveBudgetsProvider.overrideWithValue(mockGetActiveBudgets),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(activeBudgetsProvider.future);
        expect(budgets, equals(testBudgets));
      });

      test('activeBudgetsProvider should throw exception on failure', () async {
        when(() => mockGetActiveBudgets()).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getActiveBudgetsProvider.overrideWithValue(mockGetActiveBudgets),
          ],
        );
        addTearDown(container.dispose);

        expect(() => container.read(activeBudgetsProvider.future), throwsException);
      });

      test('budgetsByCategoryProvider should return budgets for category on success', () async {
        const categoryId = 'category-1';
        when(() => mockGetBudgetsByCategory(categoryId))
            .thenAnswer((_) async => Right(testBudgets));

        final container = ProviderContainer(
          overrides: [
            getBudgetsByCategoryProvider.overrideWithValue(mockGetBudgetsByCategory),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(budgetsByCategoryProvider(categoryId).future);
        expect(budgets, equals(testBudgets));
      });

      test('budgetsByCategoryProvider should throw exception on failure', () async {
        const categoryId = 'category-1';
        when(() => mockGetBudgetsByCategory(categoryId))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getBudgetsByCategoryProvider.overrideWithValue(mockGetBudgetsByCategory),
          ],
        );
        addTearDown(container.dispose);

        expect(() => container.read(budgetsByCategoryProvider(categoryId).future), 
               throwsException);
      });

      test('budgetsWithAlertsProvider should return budgets with alerts', () async {
        when(() => mockBudgetService.getBudgetsWithAlerts())
            .thenAnswer((_) async => testBudgets);

        final container = ProviderContainer(
          overrides: [
            budgetServiceProvider.overrideWithValue(mockBudgetService),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(budgetsWithAlertsProvider.future);
        expect(budgets, equals(testBudgets));
      });

      test('budgetsApproachingLimitProvider should return budgets approaching limit', () async {
        when(() => mockBudgetService.getBudgetsApproachingLimit())
            .thenAnswer((_) async => testBudgets);

        final container = ProviderContainer(
          overrides: [
            budgetServiceProvider.overrideWithValue(mockBudgetService),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(budgetsApproachingLimitProvider.future);
        expect(budgets, equals(testBudgets));
      });

      test('budgetsExceededProvider should return exceeded budgets', () async {
        when(() => mockBudgetService.getBudgetsExceeded())
            .thenAnswer((_) async => testBudgets);

        final container = ProviderContainer(
          overrides: [
            budgetServiceProvider.overrideWithValue(mockBudgetService),
          ],
        );
        addTearDown(container.dispose);

        final budgets = await container.read(budgetsExceededProvider.future);
        expect(budgets, equals(testBudgets));
      });
    });

    group('BudgetNotifier', () {
      late MockCreateBudget mockCreateBudget;
      late MockUpdateBudget mockUpdateBudget;
      late MockUpdateBudgetSpentAmount mockUpdateSpentAmount;

      setUp(() {
        mockCreateBudget = MockCreateBudget();
        mockUpdateBudget = MockUpdateBudget();
        mockUpdateSpentAmount = MockUpdateBudgetSpentAmount();
      });

      test('should start with data state', () {
        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(budgetNotifierProvider);
        expect(state, isA<AsyncData>());
      });

      test('createBudget should set loading state then data state on success', () async {
        when(() => mockCreateBudget(any())).thenAnswer((_) async => const Right(null));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.createBudget(testBudget);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be data
        expect(container.read(budgetNotifierProvider), isA<AsyncData>());
        verify(() => mockCreateBudget(testBudget)).called(1);
      });

      test('createBudget should set loading state then error state on failure', () async {
        when(() => mockCreateBudget(any())).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.createBudget(testBudget);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be error
        final state = container.read(budgetNotifierProvider);
        expect(state, isA<AsyncError>());
        expect(state.error, equals(testFailure));
      });

      test('updateBudget should set loading state then data state on success', () async {
        when(() => mockUpdateBudget(any())).thenAnswer((_) async => const Right(null));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.updateBudget(testBudget);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be data
        expect(container.read(budgetNotifierProvider), isA<AsyncData>());
        verify(() => mockUpdateBudget(testBudget)).called(1);
      });

      test('updateBudget should set loading state then error state on failure', () async {
        when(() => mockUpdateBudget(any())).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.updateBudget(testBudget);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be error
        final state = container.read(budgetNotifierProvider);
        expect(state, isA<AsyncError>());
        expect(state.error, equals(testFailure));
      });

      test('updateSpentAmount should set loading state then data state on success', () async {
        when(() => mockUpdateSpentAmount(any(), any()))
            .thenAnswer((_) async => const Right(null));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.updateSpentAmount('budget-1', 750.0);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be data
        expect(container.read(budgetNotifierProvider), isA<AsyncData>());
        verify(() => mockUpdateSpentAmount('budget-1', 750.0)).called(1);
      });

      test('updateSpentAmount should set loading state then error state on failure', () async {
        when(() => mockUpdateSpentAmount(any(), any()))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            createBudgetProvider.overrideWithValue(mockCreateBudget),
            updateBudgetProvider.overrideWithValue(mockUpdateBudget),
            updateBudgetSpentAmountProvider.overrideWithValue(mockUpdateSpentAmount),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(budgetNotifierProvider.notifier);
        
        // Start operation
        final future = notifier.updateSpentAmount('budget-1', 750.0);
        
        // Should be loading
        expect(container.read(budgetNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await future;
        
        // Should be error
        final state = container.read(budgetNotifierProvider);
        expect(state, isA<AsyncError>());
        expect(state.error, equals(testFailure));
      });
    });
  });
}