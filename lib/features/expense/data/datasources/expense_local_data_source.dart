import '../models/expense_model.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getAllExpenses();
  Future<ExpenseModel?> getExpenseById(String id);
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<List<ExpenseModel>> getExpensesByCategory(String category);
  Future<List<ExpenseModel>> getExpensesByType(String type);
  Future<void> createExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<void> clearAllExpenses();
}
