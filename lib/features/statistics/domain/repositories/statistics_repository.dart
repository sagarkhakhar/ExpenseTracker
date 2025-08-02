import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';

/// Repository interface for statistics data operations
/// Handles financial goals and trend analysis data persistence
abstract class StatisticsRepository {
  /// Save a financial goal to the database
  Future<Either<Failure, void>> saveFinancialGoal(FinancialGoal goal);

  /// Get all financial goals from the database
  Future<Either<Failure, List<FinancialGoal>>> getFinancialGoals();

  /// Get a specific financial goal by ID
  Future<Either<Failure, FinancialGoal?>> getFinancialGoalById(String id);

  /// Update an existing financial goal
  Future<Either<Failure, void>> updateFinancialGoal(FinancialGoal goal);

  /// Delete a financial goal by ID
  Future<Either<Failure, void>> deleteFinancialGoal(String id);

  /// Save trend analysis data to the database
  Future<Either<Failure, void>> saveTrendAnalysis(TrendAnalysis trend);

  /// Get trend analysis data for a specific period
  Future<Either<Failure, List<TrendAnalysis>>> getTrendAnalysisByPeriod(
      String period);

  /// Get trend analysis data by date range
  Future<Either<Failure, List<TrendAnalysis>>> getTrendAnalysisByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Delete old trend analysis data (cleanup)
  Future<Either<Failure, void>> deleteOldTrendAnalysis(DateTime beforeDate);

  /// Get the most recent trend analysis for a period
  Future<Either<Failure, TrendAnalysis?>> getLatestTrendAnalysis(String period);

  /// Check if trend analysis exists for a specific period and date range
  Future<Either<Failure, bool>> hasTrendAnalysis(
    String period,
    DateTime startDate,
    DateTime endDate,
  );
}
