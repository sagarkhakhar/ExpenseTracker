import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Expense>>> getAllExpenses() async {
    try {
      final expenses = await localDataSource.getAllExpenses();
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('Failed to get expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    try {
      final expense = await localDataSource.getExpenseById(id);
      if (expense != null) {
        return Right(expense.toEntity());
      } else {
        return const Left(DatabaseFailure('Expense not found'));
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to get expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to get expenses by date range: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByCategory(
        category.toString().split('.').last,
      );
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get expenses by category: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByType(
    ExpenseType type,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByType(
        type.toString().split('.').last,
      );
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get expenses by type: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      await localDataSource.createExpense(expenseModel);
      return Right(expense);
    } catch (e) {
      return Left(DatabaseFailure('Failed to create expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      await localDataSource.updateExpense(expenseModel);
      return Right(expense);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteExpense(String id) async {
    try {
      await localDataSource.deleteExpense(id);
      return const Right(true);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpenses(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      final total = expenses
          .where(
            (expense) => expense.type.toString().split('.').last == 'expense',
          )
          .fold(0.0, (sum, expense) => sum + expense.amount);
      return Right(total);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get total expenses: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncome(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      final total = expenses
          .where(
            (expense) => expense.type.toString().split('.').last == 'income',
          )
          .fold(0.0, (sum, expense) => sum + expense.amount);
      return Right(total);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get total income: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<ExpenseCategory, double>>>
  getExpensesByCategorySummary(DateTime start, DateTime end) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      final summary = <ExpenseCategory, double>{};

      for (final expense in expenses) {
        if (expense.type.toString().split('.').last == 'expense') {
          summary[expense.category] =
              (summary[expense.category] ?? 0.0) + expense.amount;
        }
      }

      return Right(summary);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get expenses summary: ${e.toString()}'),
      );
    }
  }
}
