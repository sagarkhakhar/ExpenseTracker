import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getAllExpenses();
  Future<Either<Failure, Expense>> getExpenseById(String id);
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
    ExpenseCategory category,
  );
  Future<Either<Failure, List<Expense>>> getExpensesByType(ExpenseType type);
  Future<Either<Failure, Expense>> createExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, bool>> deleteExpense(String id);
  Future<Either<Failure, double>> getTotalExpenses(
    DateTime start,
    DateTime end,
  );
  Future<Either<Failure, double>> getTotalIncome(DateTime start, DateTime end);
  Future<Either<Failure, Map<ExpenseCategory, double>>>
  getExpensesByCategorySummary(DateTime start, DateTime end);
}
