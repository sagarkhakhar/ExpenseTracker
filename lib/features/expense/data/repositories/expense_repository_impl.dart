// This file implements the ExpenseRepository interface for the data layer.
// It connects the domain layer to the data source (Hive/local storage).
// Implements all methods defined in the domain repository abstraction.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_model.dart';

/// Concrete implementation of ExpenseRepository for local storage.
/// Uses a data source (e.g., Hive) to persist and retrieve expenses.
class ExpenseRepositoryImpl implements ExpenseRepository {
  // The data source for local storage (injected for testability and flexibility).
  final ExpenseLocalDataSource localDataSource;

  /// Constructor with dependency injection.
  ExpenseRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Expense>>> getAllExpenses() async {
    try {
      // Get all expenses from the data source and map to domain entities.
      final expenses = await localDataSource.getAllExpenses();
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      // Return a Failure if anything goes wrong.
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
    String category,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByCategory(
        category,
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
      final expenses = await localDataSource.getExpensesByType(type);
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
      // Convert the domain entity to a data model for storage.
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
      return Left(
          DatabaseFailure('Failed to update expense:  [${e.toString()}'));
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
            (expense) => expense.type == ExpenseType.expense,
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
            (expense) => expense.type == ExpenseType.income,
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
  Future<Either<Failure, Map<String, double>>> getExpensesByCategorySummary(
      DateTime start, DateTime end) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      final summary = <String, double>{};

      for (final expense in expenses) {
        if (expense.type == ExpenseType.expense) {
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
