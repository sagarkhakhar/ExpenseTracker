// This file defines all Riverpod providers and notifiers for the statistics feature.
// It acts as the ViewModel layer in MVVM, exposing state and business logic to the UI.
// Providers connect the UI to the domain and data layers, enforcing Clean Architecture and SOLID.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/trend_analysis.dart';
import '../../domain/usecases/create_financial_goal.dart';
import '../../domain/usecases/get_financial_goals.dart';
import '../../domain/usecases/update_financial_goal.dart';
import '../../domain/usecases/get_trend_analysis.dart';
import '../../domain/services/statistics_service.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import '../../../expense/presentation/providers/expense_providers.dart';

// Repository Provider (async)
// Provides the repository implementation for dependency injection.
final statisticsRepositoryProvider =
    FutureProvider<StatisticsRepositoryImpl>((ref) async {
  final repository = StatisticsRepositoryImpl();
  // Wait for the repository to initialize its Hive boxes
  await repository.initializeBoxes();
  return repository;
});

// Use Cases Providers (async)
// Each use case is provided as a dependency for notifiers and UI.
final createFinancialGoalProvider =
    FutureProvider<CreateFinancialGoal>((ref) async {
  final repository = await ref.watch(statisticsRepositoryProvider.future);
  return CreateFinancialGoal(repository);
});

final getFinancialGoalsProvider =
    FutureProvider<GetFinancialGoals>((ref) async {
  final repository = await ref.watch(statisticsRepositoryProvider.future);
  return GetFinancialGoals(repository);
});

final updateFinancialGoalProvider =
    FutureProvider<UpdateFinancialGoal>((ref) async {
  final repository = await ref.watch(statisticsRepositoryProvider.future);
  return UpdateFinancialGoal(repository);
});

final getTrendAnalysisProvider = FutureProvider<GetTrendAnalysis>((ref) async {
  final repository = await ref.watch(statisticsRepositoryProvider.future);
  return GetTrendAnalysis(repository);
});

// Service Provider (async)
// Provides the statistics service for business logic.
final statisticsServiceProvider =
    FutureProvider<StatisticsService>((ref) async {
  return StatisticsService();
});

// State Notifier for managing financial goals
class FinancialGoalsNotifier
    extends StateNotifier<AsyncValue<List<FinancialGoal>>> {
  final Ref ref;
  bool _isLoading = false;

  FinancialGoalsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      final getFinancialGoals =
          await ref.read(getFinancialGoalsProvider.future);
      final result = await getFinancialGoals();

      state = result.fold(
        (failure) =>
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (goals) => AsyncValue.data(goals),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> createGoal(FinancialGoal goal) async {
    try {
      final createFinancialGoal =
          await ref.read(createFinancialGoalProvider.future);
      final result = await createFinancialGoal.call(goal);

      result.fold(
        (failure) => state =
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (_) => _loadGoals(), // Reload goals after creation
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    try {
      final updateFinancialGoal =
          await ref.read(updateFinancialGoalProvider.future);
      final result = await updateFinancialGoal.call(goal);

      result.fold(
        (failure) => state =
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (_) => _loadGoals(), // Reload goals after update
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    _loadGoals();
  }
}

final financialGoalsNotifierProvider = StateNotifierProvider<
    FinancialGoalsNotifier, AsyncValue<List<FinancialGoal>>>((ref) {
  return FinancialGoalsNotifier(ref);
});

// State Notifier for managing trend analysis
class TrendAnalysisNotifier
    extends StateNotifier<AsyncValue<List<TrendAnalysis>>> {
  final Ref ref;
  bool _isLoading = false;

  TrendAnalysisNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadTrendAnalysis();
  }

  Future<void> _loadTrendAnalysis() async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      final getTrendAnalysis = await ref.read(getTrendAnalysisProvider.future);
      final result = await getTrendAnalysis.callByPeriod('monthly');

      state = result.fold(
        (failure) =>
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (trends) => AsyncValue.data(trends),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> getTrendsByPeriod(String period) async {
    try {
      final getTrendAnalysis = await ref.read(getTrendAnalysisProvider.future);
      final result = await getTrendAnalysis.callByPeriod(period);

      state = result.fold(
        (failure) =>
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (trends) => AsyncValue.data(trends),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> getTrendsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final getTrendAnalysis = await ref.read(getTrendAnalysisProvider.future);
      final result = await getTrendAnalysis.callByDateRange(startDate, endDate);

      state = result.fold(
        (failure) =>
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (trends) => AsyncValue.data(trends),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    _loadTrendAnalysis();
  }
}

final trendAnalysisNotifierProvider = StateNotifierProvider<
    TrendAnalysisNotifier, AsyncValue<List<TrendAnalysis>>>((ref) {
  return TrendAnalysisNotifier(ref);
});

// State Notifier for managing enhanced statistics data
class EnhancedStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref ref;
  bool _isLoading = false;
  late final ProviderSubscription<AsyncValue<List<dynamic>>> _expensesSub;

  EnhancedStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to expense changes to update statistics
    _expensesSub = ref.listen<AsyncValue<List<dynamic>>>(
      expenseNotifierProvider,
      (prev, next) {
        if (next is AsyncData<List<dynamic>>) {
          _loadEnhancedStats();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _expensesSub.close();
    super.dispose();
  }

  Future<void> _loadEnhancedStats() async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      final statisticsService =
          await ref.read(statisticsServiceProvider.future);

      // Get current expenses for trend analysis
      final expensesAsync = ref.read(expenseNotifierProvider);
      final expenses = expensesAsync.value ?? [];

      // Get goals and trends
      final getFinancialGoals =
          await ref.read(getFinancialGoalsProvider.future);
      final getTrendAnalysis = await ref.read(getTrendAnalysisProvider.future);

      final goalsResult = await getFinancialGoals.call();
      final trendsResult = await getTrendAnalysis.callByPeriod('monthly');

      if (goalsResult.isLeft() || trendsResult.isLeft()) {
        state = AsyncValue.error(
            Exception('Failed to load enhanced statistics'),
            StackTrace.current);
        return;
      }

      final goals = goalsResult.getOrElse(() => []);
      final trends = trendsResult.getOrElse(() => []);

      // Generate enhanced statistics data with current expenses
      final enhancedStats =
          await statisticsService.generateEnhancedStats(goals, trends);

      // Add current expense data for real-time updates
      enhancedStats['currentExpenses'] = expenses;
      enhancedStats['totalExpensesCount'] = expenses.length;

      state = AsyncValue.data(enhancedStats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  void refresh() {
    _loadEnhancedStats();
  }
}

final enhancedStatsNotifierProvider = StateNotifierProvider<
    EnhancedStatsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return EnhancedStatsNotifier(ref);
});

// Combined statistics provider that merges existing expense stats with enhanced stats
final combinedStatsNotifierProvider = StateNotifierProvider<
    CombinedStatsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return CombinedStatsNotifier(ref);
});

// State Notifier for combining existing expense stats with enhanced statistics
class CombinedStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref ref;
  bool _isLoading = false;
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>>>
      _expenseStatsSub;
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>>>
      _enhancedStatsSub;

  CombinedStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to both expense stats and enhanced stats
    _expenseStatsSub = ref.listen<AsyncValue<Map<String, dynamic>>>(
      expenseStatsNotifierProvider,
      (prev, next) {
        if (next is AsyncData<Map<String, dynamic>>) {
          _combineStats();
        }
      },
      fireImmediately: true,
    );

    _enhancedStatsSub = ref.listen<AsyncValue<Map<String, dynamic>>>(
      enhancedStatsNotifierProvider,
      (prev, next) {
        if (next is AsyncData<Map<String, dynamic>>) {
          _combineStats();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _expenseStatsSub.close();
    _enhancedStatsSub.close();
    super.dispose();
  }

  void _combineStats() {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final expenseStatsAsync = ref.read(expenseStatsNotifierProvider);
      final enhancedStatsAsync = ref.read(enhancedStatsNotifierProvider);

      if (expenseStatsAsync is AsyncData<Map<String, dynamic>> &&
          enhancedStatsAsync is AsyncData<Map<String, dynamic>>) {
        final expenseStats = expenseStatsAsync.value ?? {};
        final enhancedStats = enhancedStatsAsync.value ?? {};

        // Combine the statistics
        final combinedStats = <String, dynamic>{};

        // Add existing expense statistics
        combinedStats.addAll(expenseStats);

        // Add enhanced statistics with prefix to avoid conflicts
        enhancedStats.forEach((key, value) {
          combinedStats['enhanced_$key'] = value;
        });

        // Add combined indicators
        combinedStats['hasEnhancedFeatures'] = true;
        combinedStats['enhancedFeaturesAvailable'] = [
          'goal_tracking',
          'trend_analysis',
          'enhanced_charts',
        ];

        state = AsyncValue.data(combinedStats);
      } else if (expenseStatsAsync is AsyncError) {
        state = AsyncValue.error(
          expenseStatsAsync.error!,
          expenseStatsAsync.stackTrace!,
        );
      } else if (enhancedStatsAsync is AsyncError) {
        state = AsyncValue.error(
          enhancedStatsAsync.error!,
          enhancedStatsAsync.stackTrace!,
        );
      } else {
        state = const AsyncValue.loading();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  void refresh() {
    ref.refresh(expenseStatsNotifierProvider);
    ref.refresh(enhancedStatsNotifierProvider);
  }
}
