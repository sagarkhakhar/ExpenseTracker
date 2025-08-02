import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trend_analysis.dart';
import '../repositories/statistics_repository.dart';

/// Use case for retrieving trend analysis data.
/// Supports filtering by period and date range.
class GetTrendAnalysis {
  /// The repository abstraction (injected).
  final StatisticsRepository repository;

  /// Constructor with dependency injection.
  GetTrendAnalysis(this.repository);

  /// Call this to get trend analysis by period. Returns either a Failure or the list of trend analysis.
  Future<Either<Failure, List<TrendAnalysis>>> callByPeriod(
      String period) async {
    // Business rule: Period must not be empty
    if (period.trim().isEmpty) {
      return const Left(ValidationFailure('Period cannot be empty'));
    }

    // Business rule: Period must be one of the valid values
    final validPeriods = ['daily', 'weekly', 'monthly', 'yearly'];
    if (!validPeriods.contains(period.toLowerCase())) {
      return const Left(ValidationFailure(
          'Period must be one of: daily, weekly, monthly, yearly'));
    }

    return await repository.getTrendAnalysisByPeriod(period.toLowerCase());
  }

  /// Call this to get trend analysis by date range. Returns either a Failure or the list of trend analysis.
  Future<Either<Failure, List<TrendAnalysis>>> callByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Business rule: Start date must not be after end date
    if (startDate.isAfter(endDate)) {
      return const Left(
          ValidationFailure('Start date cannot be after end date'));
    }

    // Business rule: Date range should not be too large (e.g., more than 5 years)
    final difference = endDate.difference(startDate);
    if (difference.inDays > 1825) {
      // 5 years
      return const Left(ValidationFailure('Date range cannot exceed 5 years'));
    }

    return await repository.getTrendAnalysisByDateRange(startDate, endDate);
  }

  /// Call this to get the latest trend analysis for a period. Returns either a Failure or the trend analysis.
  Future<Either<Failure, TrendAnalysis?>> callLatest(String period) async {
    // Business rule: Period must not be empty
    if (period.trim().isEmpty) {
      return const Left(ValidationFailure('Period cannot be empty'));
    }

    // Business rule: Period must be one of the valid values
    final validPeriods = ['daily', 'weekly', 'monthly', 'yearly'];
    if (!validPeriods.contains(period.toLowerCase())) {
      return const Left(ValidationFailure(
          'Period must be one of: daily, weekly, monthly, yearly'));
    }

    return await repository.getLatestTrendAnalysis(period.toLowerCase());
  }
}
