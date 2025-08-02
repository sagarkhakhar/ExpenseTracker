import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/financial_goal.dart';
import '../repositories/statistics_repository.dart';

/// Use case for retrieving all financial goals.
/// No business logic validation needed for retrieval operations.
class GetFinancialGoals {
  /// The repository abstraction (injected).
  final StatisticsRepository repository;

  /// Constructor with dependency injection.
  GetFinancialGoals(this.repository);

  /// Call this to get all financial goals. Returns either a Failure or the list of goals.
  Future<Either<Failure, List<FinancialGoal>>> call() async {
    return await repository.getFinancialGoals();
  }
}
