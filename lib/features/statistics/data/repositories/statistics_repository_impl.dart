import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';
import 'package:expense_tracker/features/statistics/domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  static const String _financialGoalsBoxName = 'financial_goals';
  static const String _trendAnalysisBoxName = 'trend_analysis';

  Box<FinancialGoal>? _financialGoalsBox;
  Box<TrendAnalysis>? _trendAnalysisBox;
  bool _isInitializing = false;

  StatisticsRepositoryImpl() {
    // Remove automatic initialization from constructor
  }

  Future<void> initializeBoxes() async {
    if (_isInitializing) return; // Prevent multiple initializations
    _isInitializing = true;

    try {
      if (_financialGoalsBox == null || !_financialGoalsBox!.isOpen) {
        _financialGoalsBox =
            await Hive.openBox<FinancialGoal>(_financialGoalsBoxName);
      }
      if (_trendAnalysisBox == null || !_trendAnalysisBox!.isOpen) {
        _trendAnalysisBox =
            await Hive.openBox<TrendAnalysis>(_trendAnalysisBoxName);
      }
    } finally {
      _isInitializing = false;
    }
  }

  Box<FinancialGoal> get _goalsBox {
    if (_financialGoalsBox == null) {
      throw StateError(
          'Repository not initialized. Call initializeBoxes() first.');
    }
    return _financialGoalsBox!;
  }

  Box<TrendAnalysis> get _trendBox {
    if (_trendAnalysisBox == null) {
      throw StateError(
          'Repository not initialized. Call initializeBoxes() first.');
    }
    return _trendAnalysisBox!;
  }

  @override
  Future<Either<Failure, void>> saveFinancialGoal(FinancialGoal goal) async {
    try {
      await _goalsBox.put(goal.id, goal);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save financial goal: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialGoal>>> getFinancialGoals() async {
    try {
      final goals = _goalsBox.values.toList();
      // Sort by creation date (newest first)
      goals.sort((a, b) => b.startDate.compareTo(a.startDate));
      return Right(goals);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get financial goals: $e'));
    }
  }

  @override
  Future<Either<Failure, FinancialGoal?>> getFinancialGoalById(
      String id) async {
    try {
      final goal = _goalsBox.get(id);
      return Right(goal);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get financial goal by ID: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFinancialGoal(FinancialGoal goal) async {
    try {
      if (!_goalsBox.containsKey(goal.id)) {
        return const Left(DatabaseFailure('Financial goal not found'));
      }
      await _goalsBox.put(goal.id, goal);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update financial goal: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFinancialGoal(String id) async {
    try {
      if (!_goalsBox.containsKey(id)) {
        return const Left(DatabaseFailure('Financial goal not found'));
      }
      await _goalsBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete financial goal: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveTrendAnalysis(TrendAnalysis trend) async {
    try {
      // Create a unique key for the trend analysis
      final key =
          '${trend.period}_${trend.startDate.millisecondsSinceEpoch}_${trend.endDate.millisecondsSinceEpoch}';
      await _trendBox.put(key, trend);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save trend analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TrendAnalysis>>> getTrendAnalysisByPeriod(
      String period) async {
    try {
      final trends =
          _trendBox.values.where((trend) => trend.period == period).toList();
      // Sort by creation date (newest first)
      trends.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(trends);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get trend analysis by period: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TrendAnalysis>>> getTrendAnalysisByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final trends = _trendBox.values
          .where((trend) =>
              trend.startDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              trend.endDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
      // Sort by creation date (newest first)
      trends.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(trends);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get trend analysis by date range: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOldTrendAnalysis(
      DateTime beforeDate) async {
    try {
      final keysToDelete = <dynamic>[];

      for (final key in _trendBox.keys) {
        final trend = _trendBox.get(key);
        if (trend != null && trend.createdAt.isBefore(beforeDate)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _trendBox.delete(key);
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete old trend analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, TrendAnalysis?>> getLatestTrendAnalysis(
      String period) async {
    try {
      final trends =
          _trendBox.values.where((trend) => trend.period == period).toList();

      if (trends.isEmpty) {
        return const Right(null);
      }

      // Sort by creation date (newest first) and return the first one
      trends.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(trends.first);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get latest trend analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasTrendAnalysis(
    String period,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasAnalysis = _trendBox.values.any((trend) =>
          trend.period == period &&
          trend.startDate.isAtSameMomentAs(startDate) &&
          trend.endDate.isAtSameMomentAs(endDate));

      return Right(hasAnalysis);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to check trend analysis existence: $e'));
    }
  }

  /// Close the Hive boxes when done
  Future<void> close() async {
    await _financialGoalsBox?.close();
    await _trendAnalysisBox?.close();
  }
}
