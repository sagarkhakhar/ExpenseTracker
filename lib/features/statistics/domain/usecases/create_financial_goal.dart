import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/financial_goal.dart';
import '../repositories/statistics_repository.dart';

/// Use case for creating a new financial goal.
/// Validates all business rules before calling the repository.
class CreateFinancialGoal {
  /// The repository abstraction (injected).
  final StatisticsRepository repository;

  /// Constructor with dependency injection.
  CreateFinancialGoal(this.repository);

  /// Call this to create a financial goal. Returns either a Failure or void on success.
  Future<Either<Failure, void>> call(FinancialGoal goal) async {
    // Business rule: Title must not be empty
    if (goal.title.trim().isEmpty) {
      return const Left(ValidationFailure('Goal title cannot be empty'));
    }

    // Business rule: Target amount must be a positive, finite number
    if (goal.targetAmount.isNaN ||
        goal.targetAmount.isInfinite ||
        goal.targetAmount <= 0) {
      return const Left(
          ValidationFailure('Target amount must be positive and finite'));
    }

    // Business rule: Current amount must be non-negative
    if (goal.currentAmount.isNaN ||
        goal.currentAmount.isInfinite ||
        goal.currentAmount < 0) {
      return const Left(
          ValidationFailure('Current amount must be non-negative'));
    }

    // Business rule: Current amount cannot exceed target amount
    if (goal.currentAmount > goal.targetAmount) {
      return const Left(
          ValidationFailure('Current amount cannot exceed target amount'));
    }

    // Business rule: Start date must not be in the future
    if (goal.startDate.isAfter(DateTime.now())) {
      return const Left(
          ValidationFailure('Start date cannot be in the future'));
    }

    // Business rule: Target date must be after start date
    if (goal.targetDate.isBefore(goal.startDate)) {
      return const Left(
          ValidationFailure('Target date must be after start date'));
    }

    // Business rule: Target date must not be in the past
    if (goal.targetDate.isBefore(DateTime.now())) {
      return const Left(ValidationFailure('Target date cannot be in the past'));
    }

    // Business rule: Category must not be empty if provided
    if (goal.category != null && goal.category!.trim().isEmpty) {
      return const Left(
          ValidationFailure('Category cannot be empty if provided'));
    }

    // If all validations pass, call the repository to persist the goal
    return await repository.saveFinancialGoal(goal);
  }
}
