import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../expense/domain/entities/expense.dart';

class BudgetService {
  final BudgetRepository repository;
  final ExpenseRepository expenseRepository;

  BudgetService({
    required this.repository,
    required this.expenseRepository,
  });

  /// Calculate the total spent amount for a budget based on expenses
  Future<double> calculateSpentAmount(String budgetId, String categoryId, DateTime startDate, DateTime endDate) async {
    try {
      // Get expenses for the category within the budget period
      final expensesResult = await expenseRepository.getExpensesByDateRange(startDate, endDate);
      
      return expensesResult.fold(
        (failure) => 0.0, // Return 0.0 if there's a failure
        (expenses) {
          // Filter expenses by category and sum the amounts
          final categoryExpenses = expenses.where((expense) => 
            expense.category == categoryId && expense.type == ExpenseType.expense
          ).toList();
          
          return categoryExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
        },
      );
    } catch (e) {
      // Return 0.0 if there's an error calculating spent amount
      return 0.0;
    }
  }

  /// Get budgets that are approaching or exceeding their limits
  Future<List<Budget>> getBudgetsWithAlerts() async {
    final activeBudgets = await repository.getActiveBudgets();
    return activeBudgets.where((budget) => 
      budget.isApproachingLimit || budget.isExceeded
    ).toList();
  }

  /// Get budgets that are approaching their limits (but not exceeded)
  Future<List<Budget>> getBudgetsApproachingLimit() async {
    final activeBudgets = await repository.getActiveBudgets();
    return activeBudgets.where((budget) => budget.isApproachingLimit).toList();
  }

  /// Get budgets that have exceeded their limits
  Future<List<Budget>> getBudgetsExceeded() async {
    final activeBudgets = await repository.getActiveBudgets();
    return activeBudgets.where((budget) => budget.isExceeded).toList();
  }

  /// Update spent amounts for all active budgets
  Future<void> updateAllBudgetSpentAmounts() async {
    final activeBudgets = await repository.getActiveBudgets();
    
    for (final budget in activeBudgets) {
      final spentAmount = await calculateSpentAmount(
        budget.id,
        budget.categoryId,
        budget.startDate,
        budget.endDate,
      );
      
      await repository.updateSpentAmount(budget.id, spentAmount);
    }
  }

  /// Check if a budget period is current (within start and end dates)
  bool isBudgetPeriodCurrent(Budget budget) {
    final now = DateTime.now();
    return now.isAfter(budget.startDate) && now.isBefore(budget.endDate);
  }

  /// Get the next budget period start date based on the current period
  DateTime getNextPeriodStartDate(Budget budget) {
    switch (budget.period.toLowerCase()) {
      case 'weekly':
        return budget.endDate.add(const Duration(days: 1));
      case 'monthly':
        return DateTime(budget.endDate.year, budget.endDate.month + 1, 1);
      case 'yearly':
        return DateTime(budget.endDate.year + 1, 1, 1);
      default:
        return budget.endDate.add(const Duration(days: 1));
    }
  }

  /// Get the next budget period end date based on the current period
  DateTime getNextPeriodEndDate(Budget budget) {
    final nextStart = getNextPeriodStartDate(budget);
    
    switch (budget.period.toLowerCase()) {
      case 'weekly':
        return nextStart.add(const Duration(days: 6));
      case 'monthly':
        return DateTime(nextStart.year, nextStart.month + 1, 0);
      case 'yearly':
        return DateTime(nextStart.year, 12, 31);
      default:
        return nextStart.add(const Duration(days: 6));
    }
  }
} 