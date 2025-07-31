import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Budget>> getAllBudgets() async {
    return await localDataSource.getAllBudgets();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    return await localDataSource.getBudgetById(id);
  }

  @override
  Future<List<Budget>> getBudgetsByCategory(String categoryId) async {
    return await localDataSource.getBudgetsByCategory(categoryId);
  }

  @override
  Future<List<Budget>> getActiveBudgets() async {
    return await localDataSource.getActiveBudgets();
  }

  @override
  Future<void> createBudget(Budget budget) async {
    await localDataSource.createBudget(budget);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await localDataSource.updateBudget(budget);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await localDataSource.deleteBudget(id);
  }

  @override
  Future<void> updateSpentAmount(String budgetId, double spentAmount) async {
    await localDataSource.updateSpentAmount(budgetId, spentAmount);
  }
} 