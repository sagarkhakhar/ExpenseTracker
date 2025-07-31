import 'package:dartz/dartz.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../../../../core/errors/failures.dart';

class UpdateBudget {
  final BudgetRepository repository;

  UpdateBudget(this.repository);

  Future<Either<Failure, void>> call(Budget budget) async {
    try {
      await repository.updateBudget(budget);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class UpdateBudgetSpentAmount {
  final BudgetRepository repository;

  UpdateBudgetSpentAmount(this.repository);

  Future<Either<Failure, void>> call(String budgetId, double spentAmount) async {
    try {
      await repository.updateSpentAmount(budgetId, spentAmount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 