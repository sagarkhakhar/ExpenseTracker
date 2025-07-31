import 'package:dartz/dartz.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../../../../core/errors/failures.dart';

class GetBudgets {
  final BudgetRepository repository;

  GetBudgets(this.repository);

  Future<Either<Failure, List<Budget>>> call() async {
    try {
      final budgets = await repository.getAllBudgets();
      return Right(budgets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetBudgetsByCategory {
  final BudgetRepository repository;

  GetBudgetsByCategory(this.repository);

  Future<Either<Failure, List<Budget>>> call(String categoryId) async {
    try {
      final budgets = await repository.getBudgetsByCategory(categoryId);
      return Right(budgets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetActiveBudgets {
  final BudgetRepository repository;

  GetActiveBudgets(this.repository);

  Future<Either<Failure, List<Budget>>> call() async {
    try {
      final budgets = await repository.getActiveBudgets();
      return Right(budgets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 