// This file contains unit tests for the statistics providers.
// Tests cover state management, error handling, and integration with existing providers.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/statistics/presentation/providers/statistics_providers.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/create_financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/get_financial_goals.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/update_financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/usecases/get_trend_analysis.dart';
import 'package:expense_tracker/features/statistics/domain/services/statistics_service.dart';
import 'package:expense_tracker/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

// Mocks
class MockStatisticsRepositoryImpl extends Mock
    implements StatisticsRepositoryImpl {}

class MockCreateFinancialGoal extends Mock implements CreateFinancialGoal {}

class MockGetFinancialGoals extends Mock implements GetFinancialGoals {}

class MockUpdateFinancialGoal extends Mock implements UpdateFinancialGoal {}

class MockGetTrendAnalysis extends Mock implements GetTrendAnalysis {}

class MockStatisticsService extends Mock implements StatisticsService {}

void main() {
  setUpAll(() async {
    final testDir = Directory('./test/hive_testing').absolute;
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    Hive.init(testDir.path);
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(ExpenseTypeAdapter());
    Hive.registerAdapter(FinancialGoalAdapter());
    Hive.registerAdapter(GoalStatusAdapter());
    Hive.registerAdapter(TrendAnalysisAdapter());
    Hive.registerAdapter(TrendDirectionAdapter());
  });

  group('Statistics Providers', () {
    late ProviderContainer container;
    late MockStatisticsRepositoryImpl mockRepository;
    late MockCreateFinancialGoal mockCreateGoal;
    late MockGetFinancialGoals mockGetGoals;
    late MockUpdateFinancialGoal mockUpdateGoal;
    late MockGetTrendAnalysis mockGetTrends;
    late MockStatisticsService mockService;

    setUp(() {
      mockRepository = MockStatisticsRepositoryImpl();
      mockCreateGoal = MockCreateFinancialGoal();
      mockGetGoals = MockGetFinancialGoals();
      mockUpdateGoal = MockUpdateFinancialGoal();
      mockGetTrends = MockGetTrendAnalysis();
      mockService = MockStatisticsService();

      container = ProviderContainer(
        overrides: [
          // Override repository provider
          statisticsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
          // Override use case providers
          createFinancialGoalProvider.overrideWith(
            (ref) async => mockCreateGoal,
          ),
          getFinancialGoalsProvider.overrideWith(
            (ref) async => mockGetGoals,
          ),
          updateFinancialGoalProvider.overrideWith(
            (ref) async => mockUpdateGoal,
          ),
          getTrendAnalysisProvider.overrideWith(
            (ref) async => mockGetTrends,
          ),
          // Override service provider
          statisticsServiceProvider.overrideWith(
            (ref) async => mockService,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('FinancialGoalsNotifier', () {
      test('should load goals successfully', () async {
        // Arrange
        final testGoals = [
          FinancialGoal(
            id: '1',
            title: 'Test Goal',
            targetAmount: 1000,
            currentAmount: 500,
            startDate: DateTime.now(),
            targetDate: DateTime.now().add(const Duration(days: 30)),
            status: GoalStatus.active,
          ),
        ];

        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => Right(testGoals),
        );

        // Act
        final notifier =
            container.read(financialGoalsNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(financialGoalsNotifierProvider);

        expect(state, isA<AsyncData<List<FinancialGoal>>>());
        expect(state.value, equals(testGoals));
        verify(() => mockGetGoals.call()).called(1);
      });

      test('should handle goal loading error', () async {
        // Arrange
        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => const Left(DatabaseFailure('Failed to load goals')),
        );

        // Act
        final notifier =
            container.read(financialGoalsNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(financialGoalsNotifierProvider);

        expect(state, isA<AsyncError>());
        expect(state.error.toString(), contains('Failed to load goals'));
      });

      test('should create goal successfully', () async {
        // Arrange
        final testGoal = FinancialGoal(
          id: '1',
          title: 'New Goal',
          targetAmount: 1000,
          currentAmount: 0,
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          status: GoalStatus.active,
        );

        final testGoals = [testGoal];

        when(() => mockCreateGoal.call(testGoal)).thenAnswer(
          (_) async => const Right(null),
        );
        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => Right(testGoals),
        );

        // Act
        final notifier =
            container.read(financialGoalsNotifierProvider.notifier);
        await notifier.createGoal(testGoal);

        // Assert
        verify(() => mockCreateGoal.call(testGoal)).called(1);
        verify(() => mockGetGoals.call()).called(1);
      });

      test('should update goal successfully', () async {
        // Arrange
        final testGoal = FinancialGoal(
          id: '1',
          title: 'Updated Goal',
          targetAmount: 1000,
          currentAmount: 750,
          startDate: DateTime.now(),
          targetDate: DateTime.now().add(const Duration(days: 30)),
          status: GoalStatus.active,
        );

        final testGoals = [testGoal];

        when(() => mockUpdateGoal.call(testGoal)).thenAnswer(
          (_) async => const Right(null),
        );
        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => Right(testGoals),
        );

        // Act
        final notifier =
            container.read(financialGoalsNotifierProvider.notifier);
        await notifier.updateGoal(testGoal);

        // Assert
        verify(() => mockUpdateGoal.call(testGoal)).called(1);
        verify(() => mockGetGoals.call()).called(1);
      });
    });

    group('TrendAnalysisNotifier', () {
      test('should load trends successfully', () async {
        // Arrange
        final testTrends = [
          TrendAnalysis(
            period: 'monthly',
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
            totalSpending: 1500,
            categoryBreakdown: {'Food': 500, 'Transport': 1000},
            trendDirection: TrendDirection.increasing,
            percentageChange: 10.5,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockGetTrends.callByPeriod('monthly')).thenAnswer(
          (_) async => Right(testTrends),
        );

        // Act
        final notifier = container.read(trendAnalysisNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(trendAnalysisNotifierProvider);

        expect(state, isA<AsyncData<List<TrendAnalysis>>>());
        expect(state.value, equals(testTrends));
        verify(() => mockGetTrends.callByPeriod('monthly')).called(1);
      });

      test('should handle trend loading error', () async {
        // Arrange
        when(() => mockGetTrends.callByPeriod('monthly')).thenAnswer(
          (_) async => const Left(DatabaseFailure('Failed to load trends')),
        );

        // Act
        final notifier = container.read(trendAnalysisNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(trendAnalysisNotifierProvider);

        expect(state, isA<AsyncError>());
        expect(state.error.toString(), contains('Failed to load trends'));
      });

      test('should get trends by period', () async {
        // Arrange
        final testTrends = [
          TrendAnalysis(
            period: 'weekly',
            startDate: DateTime.now().subtract(const Duration(days: 7)),
            endDate: DateTime.now(),
            totalSpending: 300,
            categoryBreakdown: {'Food': 100, 'Transport': 200},
            trendDirection: TrendDirection.decreasing,
            percentageChange: -5.0,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockGetTrends.callByPeriod('weekly')).thenAnswer(
          (_) async => Right(testTrends),
        );

        // Act
        final notifier = container.read(trendAnalysisNotifierProvider.notifier);
        await notifier.getTrendsByPeriod('weekly');

        // Assert
        verify(() => mockGetTrends.callByPeriod('weekly')).called(1);
      });

      test('should get trends by date range', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();
        final testTrends = [
          TrendAnalysis(
            period: 'custom',
            startDate: startDate,
            endDate: endDate,
            totalSpending: 2000,
            categoryBreakdown: {'Food': 800, 'Transport': 1200},
            trendDirection: TrendDirection.stable,
            percentageChange: 0.0,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockGetTrends.callByDateRange(startDate, endDate))
            .thenAnswer(
          (_) async => Right(testTrends),
        );

        // Act
        final notifier = container.read(trendAnalysisNotifierProvider.notifier);
        await notifier.getTrendsByDateRange(startDate, endDate);

        // Assert
        verify(() => mockGetTrends.callByDateRange(startDate, endDate))
            .called(1);
      });
    });

    group('EnhancedStatsNotifier', () {
      test('should load enhanced stats successfully', () async {
        // Arrange
        final testGoals = [
          FinancialGoal(
            id: '1',
            title: 'Test Goal',
            targetAmount: 1000,
            currentAmount: 500,
            startDate: DateTime.now(),
            targetDate: DateTime.now().add(const Duration(days: 30)),
            status: GoalStatus.active,
          ),
        ];

        final testTrends = [
          TrendAnalysis(
            period: 'monthly',
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
            totalSpending: 1500,
            categoryBreakdown: {'Food': 500, 'Transport': 1000},
            trendDirection: TrendDirection.increasing,
            percentageChange: 10.5,
            createdAt: DateTime.now(),
          ),
        ];

        final expectedEnhancedStats = {
          'goals': testGoals,
          'trends': testTrends,
          'currentExpenses': [],
          'totalExpensesCount': 0,
        };

        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => Right(testGoals),
        );
        when(() => mockGetTrends.callByPeriod('monthly')).thenAnswer(
          (_) async => Right(testTrends),
        );
        when(() => mockService.generateEnhancedStats(testGoals, testTrends))
            .thenAnswer(
          (_) async => expectedEnhancedStats,
        );

        // Act
        final notifier = container.read(enhancedStatsNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(enhancedStatsNotifierProvider);

        expect(state, isA<AsyncData<Map<String, dynamic>>>());
        expect(state.value, equals(expectedEnhancedStats));
        verify(() => mockService.generateEnhancedStats(testGoals, testTrends))
            .called(1);
      });

      test('should handle enhanced stats loading error', () async {
        // Arrange
        when(() => mockGetGoals.call()).thenAnswer(
          (_) async => const Left(DatabaseFailure('Failed to load goals')),
        );

        // Act
        final notifier = container.read(enhancedStatsNotifierProvider.notifier);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(enhancedStatsNotifierProvider);

        expect(state, isA<AsyncError>());
        expect(state.error.toString(),
            contains('Failed to load enhanced statistics'));
      });
    });

    group('Provider Integration', () {
      test('should provide statistics repository', () async {
        // Act
        final repository =
            await container.read(statisticsRepositoryProvider.future);

        // Assert
        expect(repository, isA<StatisticsRepositoryImpl>());
      });

      test('should provide use cases', () async {
        // Act
        final createGoal =
            await container.read(createFinancialGoalProvider.future);
        final getGoals = await container.read(getFinancialGoalsProvider.future);
        final updateGoal =
            await container.read(updateFinancialGoalProvider.future);
        final getTrends = await container.read(getTrendAnalysisProvider.future);

        // Assert
        expect(createGoal, isA<CreateFinancialGoal>());
        expect(getGoals, isA<GetFinancialGoals>());
        expect(updateGoal, isA<UpdateFinancialGoal>());
        expect(getTrends, isA<GetTrendAnalysis>());
      });

      test('should provide statistics service', () async {
        // Act
        final service = await container.read(statisticsServiceProvider.future);

        // Assert
        expect(service, isA<StatisticsService>());
      });
    });
  });
}
