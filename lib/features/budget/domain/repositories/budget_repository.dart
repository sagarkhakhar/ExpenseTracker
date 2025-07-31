import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAllBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<List<Budget>> getBudgetsByCategory(String categoryId);
  Future<List<Budget>> getActiveBudgets();
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> updateSpentAmount(String budgetId, double spentAmount);
} 