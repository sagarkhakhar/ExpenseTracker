import 'package:dartz/dartz.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../../../../core/errors/failures.dart';

class CreateBudget {
  final BudgetRepository repository;

  CreateBudget(this.repository);

  Future<Either<Failure, void>> call(Budget budget) async {
    try {
      await repository.createBudget(budget);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 