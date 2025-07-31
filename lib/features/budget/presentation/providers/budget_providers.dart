import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/create_budget.dart';
import '../../domain/usecases/get_budgets.dart';
import '../../domain/usecases/update_budget.dart';
import '../../domain/services/budget_service.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/datasources/budget_local_data_source.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../expense/data/repositories/expense_repository_impl.dart';
import '../../../expense/data/datasources/expense_local_data_source_impl.dart';

// Repository providers
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final localDataSource = BudgetLocalDataSourceImpl();
  return BudgetRepositoryImpl(localDataSource: localDataSource);
});

// Use case providers
final createBudgetProvider = Provider<CreateBudget>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return CreateBudget(repository);
});

final getBudgetsProvider = Provider<GetBudgets>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return GetBudgets(repository);
});

final getBudgetsByCategoryProvider = Provider<GetBudgetsByCategory>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return GetBudgetsByCategory(repository);
});

final getActiveBudgetsProvider = Provider<GetActiveBudgets>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return GetActiveBudgets(repository);
});

final updateBudgetProvider = Provider<UpdateBudget>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return UpdateBudget(repository);
});

final updateBudgetSpentAmountProvider =
    Provider<UpdateBudgetSpentAmount>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return UpdateBudgetSpentAmount(repository);
});

// Expense repository provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final localDataSource = ExpenseLocalDataSourceImpl();
  return ExpenseRepositoryImpl(localDataSource);
});

// Service provider
final budgetServiceProvider = Provider<BudgetService>((ref) {
  final budgetRepository = ref.watch(budgetRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  return BudgetService(
    repository: budgetRepository,
    expenseRepository: expenseRepository,
  );
});

// State providers
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final getBudgets = ref.watch(getBudgetsProvider);
  final result = await getBudgets();
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (budgets) => budgets,
  );
});

final activeBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final getActiveBudgets = ref.watch(getActiveBudgetsProvider);
  final result = await getActiveBudgets();
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (budgets) => budgets,
  );
});

final budgetsByCategoryProvider =
    FutureProvider.family<List<Budget>, String>((ref, categoryId) async {
  final getBudgetsByCategory = ref.watch(getBudgetsByCategoryProvider);
  final result = await getBudgetsByCategory(categoryId);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (budgets) => budgets,
  );
});

final budgetsWithAlertsProvider = FutureProvider<List<Budget>>((ref) async {
  final budgetService = ref.watch(budgetServiceProvider);
  return await budgetService.getBudgetsWithAlerts();
});

final budgetsApproachingLimitProvider =
    FutureProvider<List<Budget>>((ref) async {
  final budgetService = ref.watch(budgetServiceProvider);
  return await budgetService.getBudgetsApproachingLimit();
});

final budgetsExceededProvider = FutureProvider<List<Budget>>((ref) async {
  final budgetService = ref.watch(budgetServiceProvider);
  return await budgetService.getBudgetsExceeded();
});

// Notifier for budget operations
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final CreateBudget _createBudget;
  final UpdateBudget _updateBudget;
  final UpdateBudgetSpentAmount _updateSpentAmount;

  BudgetNotifier({
    required CreateBudget createBudget,
    required UpdateBudget updateBudget,
    required UpdateBudgetSpentAmount updateSpentAmount,
  })  : _createBudget = createBudget,
        _updateBudget = updateBudget,
        _updateSpentAmount = updateSpentAmount,
        super(const AsyncValue.data(null));

  Future<void> createBudget(Budget budget) async {
    state = const AsyncValue.loading();
    final result = await _createBudget(budget);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateBudget(Budget budget) async {
    state = const AsyncValue.loading();
    final result = await _updateBudget(budget);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateSpentAmount(String budgetId, double spentAmount) async {
    state = const AsyncValue.loading();
    final result = await _updateSpentAmount(budgetId, spentAmount);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  final createBudget = ref.watch(createBudgetProvider);
  final updateBudget = ref.watch(updateBudgetProvider);
  final updateSpentAmount = ref.watch(updateBudgetSpentAmountProvider);

  return BudgetNotifier(
    createBudget: createBudget,
    updateBudget: updateBudget,
    updateSpentAmount: updateSpentAmount,
  );
});
