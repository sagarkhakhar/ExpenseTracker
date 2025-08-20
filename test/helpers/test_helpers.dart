// Advanced testing utilities and helpers for exceptional test coverage
// This demonstrates comprehensive testing strategies with builders, mocks, and utilities

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/core/errors/exceptions.dart';
import 'package:expense_tracker/core/types/result.dart';

/// Comprehensive test data builders for consistent test fixtures
class TestDataBuilders {
  static final Random _random = Random(42); // Fixed seed for reproducible tests

  /// Build expense with customizable properties
  static ExpenseBuilder expense() => ExpenseBuilder();

  /// Build financial goal with customizable properties
  static FinancialGoalBuilder financialGoal() => FinancialGoalBuilder();

  /// Build list of expenses with different patterns
  static List<Expense> expenseList({
    int count = 5,
    ExpenseType? type,
    String? category,
    DateRange? dateRange,
  }) {
    return List.generate(count, (index) {
      final builder = expense();
      
      if (type != null) builder.withType(type);
      if (category != null) builder.withCategory(category);
      if (dateRange != null) {
        final date = _randomDateInRange(dateRange.start, dateRange.end);
        builder.withDate(date);
      }
      
      return builder.build();
    });
  }

  /// Generate realistic test amounts
  static double randomAmount({double min = 1.0, double max = 1000.0}) {
    return double.parse((min + _random.nextDouble() * (max - min)).toStringAsFixed(2));
  }

  /// Generate realistic test dates
  static DateTime randomDate({DateTime? start, DateTime? end}) {
    start ??= DateTime.now().subtract(const Duration(days: 365));
    end ??= DateTime.now().add(const Duration(days: 365));
    return _randomDateInRange(start, end);
  }

  static DateTime _randomDateInRange(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    final randomDays = _random.nextInt(difference);
    return start.add(Duration(days: randomDays));
  }
}

/// Builder pattern for creating test expenses
class ExpenseBuilder {
  String _id = 'test-expense-${DateTime.now().millisecondsSinceEpoch}';
  String _title = 'Test Expense';
  String _description = 'Test expense description';
  double _amount = 50.0;
  String _category = 'Food';
  ExpenseType _type = ExpenseType.expense;
  DateTime _date = DateTime.now();
  DateTime _createdAt = DateTime.now();
  DateTime _updatedAt = DateTime.now();
  Map<String, dynamic>? _metadata;
  bool _isRecurring = false;
  String? _recurringFrequency;
  DateTime? _nextOccurrence;
  DateTime? _endDate;

  ExpenseBuilder withId(String id) {
    _id = id;
    return this;
  }

  ExpenseBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  ExpenseBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  ExpenseBuilder withAmount(double amount) {
    _amount = amount;
    return this;
  }

  ExpenseBuilder withCategory(String category) {
    _category = category;
    return this;
  }

  ExpenseBuilder withType(ExpenseType type) {
    _type = type;
    return this;
  }

  ExpenseBuilder withDate(DateTime date) {
    _date = date;
    return this;
  }

  ExpenseBuilder withTimestamps(DateTime createdAt, DateTime updatedAt) {
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    return this;
  }

  ExpenseBuilder withMetadata(Map<String, dynamic> metadata) {
    _metadata = metadata;
    return this;
  }

  ExpenseBuilder asRecurring({
    required String frequency,
    required DateTime nextOccurrence,
    DateTime? endDate,
  }) {
    _isRecurring = true;
    _recurringFrequency = frequency;
    _nextOccurrence = nextOccurrence;
    _endDate = endDate;
    return this;
  }

  ExpenseBuilder asIncome() {
    _type = ExpenseType.income;
    return this;
  }

  ExpenseBuilder asExpense() {
    _type = ExpenseType.expense;
    return this;
  }

  /// Build with realistic random data
  ExpenseBuilder withRealisticData() {
    final categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Bills'];
    final titles = {
      'Food': ['Lunch', 'Dinner', 'Grocery shopping', 'Coffee', 'Restaurant'],
      'Transport': ['Uber ride', 'Gas', 'Parking', 'Train ticket', 'Bus fare'],
      'Shopping': ['Clothes', 'Electronics', 'Books', 'Gifts', 'Home items'],
      'Entertainment': ['Movie', 'Concert', 'Games', 'Streaming', 'Events'],
      'Health': ['Doctor visit', 'Pharmacy', 'Gym', 'Supplements', 'Therapy'],
      'Bills': ['Electricity', 'Internet', 'Phone', 'Water', 'Insurance'],
    };

    _category = categories[TestDataBuilders._random.nextInt(categories.length)];
    final categoryTitles = titles[_category]!;
    _title = categoryTitles[TestDataBuilders._random.nextInt(categoryTitles.length)];
    _amount = TestDataBuilders.randomAmount(min: 5.0, max: 500.0);
    _date = TestDataBuilders.randomDate(
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    );
    
    return this;
  }

  Expense build() {
    return Expense(
      id: _id,
      title: _title,
      description: _description,
      amount: _amount,
      category: _category,
      type: _type,
      date: _date,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      metadata: _metadata,
      isRecurring: _isRecurring,
      recurringFrequency: _recurringFrequency,
      nextOccurrence: _nextOccurrence,
      endDate: _endDate,
    );
  }
}

/// Builder pattern for creating test financial goals
class FinancialGoalBuilder {
  String _id = 'test-goal-${DateTime.now().millisecondsSinceEpoch}';
  String _title = 'Test Goal';
  double _targetAmount = 1000.0;
  double _currentAmount = 0.0;
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  String? _category;
  GoalStatus _status = GoalStatus.active;

  FinancialGoalBuilder withId(String id) {
    _id = id;
    return this;
  }

  FinancialGoalBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  FinancialGoalBuilder withTargetAmount(double amount) {
    _targetAmount = amount;
    return this;
  }

  FinancialGoalBuilder withCurrentAmount(double amount) {
    _currentAmount = amount;
    return this;
  }

  FinancialGoalBuilder withDateRange(DateTime start, DateTime target) {
    _startDate = start;
    _targetDate = target;
    return this;
  }

  FinancialGoalBuilder withCategory(String category) {
    _category = category;
    return this;
  }

  FinancialGoalBuilder withStatus(GoalStatus status) {
    _status = status;
    return this;
  }

  FinancialGoalBuilder asCompleted() {
    _status = GoalStatus.completed;
    _currentAmount = _targetAmount;
    return this;
  }

  FinancialGoalBuilder asPaused() {
    _status = GoalStatus.paused;
    return this;
  }

  FinancialGoalBuilder withProgress(double progressPercentage) {
    _currentAmount = _targetAmount * (progressPercentage / 100);
    return this;
  }

  FinancialGoal build() {
    return FinancialGoal(
      id: _id,
      title: _title,
      targetAmount: _targetAmount,
      currentAmount: _currentAmount,
      startDate: _startDate,
      targetDate: _targetDate,
      category: _category,
      status: _status,
    );
  }
}

/// Test assertion helpers for complex objects
class TestAssertions {
  /// Assert that two expenses are equal with detailed error messages
  static void expectExpensesEqual(Expense actual, Expense expected) {
    expect(actual.id, expected.id, reason: 'Expense IDs should match');
    expect(actual.title, expected.title, reason: 'Expense titles should match');
    expect(actual.description, expected.description, reason: 'Expense descriptions should match');
    expect(actual.amount, expected.amount, reason: 'Expense amounts should match');
    expect(actual.category, expected.category, reason: 'Expense categories should match');
    expect(actual.type, expected.type, reason: 'Expense types should match');
    expect(actual.date, expected.date, reason: 'Expense dates should match');
  }

  /// Assert that expense list is sorted by date
  static void expectExpensesSortedByDate(List<Expense> expenses, {bool ascending = false}) {
    for (int i = 1; i < expenses.length; i++) {
      final comparison = expenses[i - 1].date.compareTo(expenses[i].date);
      if (ascending) {
        expect(comparison, lessThanOrEqualTo(0), 
            reason: 'Expenses should be sorted by date ascending');
      } else {
        expect(comparison, greaterThanOrEqualTo(0), 
            reason: 'Expenses should be sorted by date descending');
      }
    }
  }

  /// Assert that amounts are approximately equal (for floating point comparisons)
  static void expectAmountsEqual(double actual, double expected, {double tolerance = 0.01}) {
    expect(actual, closeTo(expected, tolerance), 
        reason: 'Amounts should be equal within tolerance');
  }

  /// Assert that a Result is successful with expected value
  static void expectResultSuccess<T>(Result<T> result, T expected) {
    expect(result.isSuccess, isTrue, reason: 'Result should be successful');
    expect(result.valueOrNull, equals(expected), reason: 'Result value should match expected');
  }

  /// Assert that a Result is a failure with expected exception type
  static void expectResultFailure<T, E extends AppException>(Result<T> result) {
    expect(result.isFailure, isTrue, reason: 'Result should be a failure');
    expect(result.exceptionOrNull, isA<E>(), reason: 'Exception should be of expected type');
  }
}

/// Mock data generators for different scenarios
class TestScenarios {
  /// Generate monthly expense data for testing
  static List<Expense> monthlyExpenseScenario({
    required DateTime month,
    int expenseCount = 20,
    int incomeCount = 5,
  }) {
    final expenses = <Expense>[];
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    // Add expenses
    for (int i = 0; i < expenseCount; i++) {
      expenses.add(
        TestDataBuilders.expense()
            .withRealisticData()
            .asExpense()
            .withDate(_randomDateInRange(startOfMonth, endOfMonth))
            .build(),
      );
    }

    // Add income
    for (int i = 0; i < incomeCount; i++) {
      expenses.add(
        TestDataBuilders.expense()
            .withTitle('Salary')
            .withCategory('Income')
            .withAmount(TestDataBuilders.randomAmount(min: 1000.0, max: 5000.0))
            .asIncome()
            .withDate(_randomDateInRange(startOfMonth, endOfMonth))
            .build(),
      );
    }

    return expenses;
  }

  /// Generate budget tracking scenario
  static Map<String, List<Expense>> budgetTrackingScenario() {
    final categories = ['Food', 'Transport', 'Entertainment', 'Shopping'];
    final scenarios = <String, List<Expense>>{};

    for (final category in categories) {
      scenarios[category] = List.generate(10, (index) =>
          TestDataBuilders.expense()
              .withCategory(category)
              .withRealisticData()
              .build());
    }

    return scenarios;
  }

  /// Generate goal tracking scenario
  static List<FinancialGoal> goalTrackingScenario() {
    return [
      // Active goals with different progress
      TestDataBuilders.financialGoal()
          .withTitle('Emergency Fund')
          .withTargetAmount(10000)
          .withProgress(25)
          .build(),
      
      TestDataBuilders.financialGoal()
          .withTitle('Vacation Fund')
          .withTargetAmount(5000)
          .withProgress(75)
          .build(),
      
      // Completed goal
      TestDataBuilders.financialGoal()
          .withTitle('New Laptop')
          .withTargetAmount(2000)
          .asCompleted()
          .build(),
      
      // Paused goal
      TestDataBuilders.financialGoal()
          .withTitle('Car Fund')
          .withTargetAmount(25000)
          .withProgress(10)
          .asPaused()
          .build(),
    ];
  }

  static DateTime _randomDateInRange(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    final randomDays = TestDataBuilders._random.nextInt(difference);
    return start.add(Duration(days: randomDays));
  }
}

/// Date range utility for tests
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    return DateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  factory DateRange.lastMonth() {
    final now = DateTime.now();
    return DateRange(
      DateTime(now.year, now.month - 1, 1),
      DateTime(now.year, now.month, 0),
    );
  }

  factory DateRange.thisYear() {
    final now = DateTime.now();
    return DateRange(
      DateTime(now.year, 1, 1),
      DateTime(now.year, 12, 31),
    );
  }
}

/// Widget testing utilities
class WidgetTestHelpers {
  /// Create a widget with Riverpod providers for testing
  static Widget createWidgetWithProviders(
    Widget child, {
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );
  }

  /// Pump and settle with custom duration
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), timeout);
  }

  /// Find widget by type and verify it exists
  static T findWidgetByType<T extends Widget>(WidgetTester tester) {
    final finder = find.byType(T);
    expect(finder, findsOneWidget, reason: 'Should find exactly one $T widget');
    return tester.widget<T>(finder);
  }

  /// Verify loading state is displayed
  static void expectLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'Should show loading indicator');
  }

  /// Verify error state is displayed
  static void expectErrorState(WidgetTester tester, {String? message}) {
    expect(find.textContaining('Error'), findsOneWidget,
        reason: 'Should show error message');
    if (message != null) {
      expect(find.textContaining(message), findsOneWidget,
          reason: 'Should show specific error message');
    }
  }
}

/// Hive testing utilities
class HiveTestHelpers {
  /// Setup Hive for testing with temporary directory
  static Future<void> setupHiveForTesting() async {
    await setUpTestHive();
  }

  /// Cleanup Hive after testing
  static Future<void> tearDownHiveAfterTesting() async {
    await tearDownTestHive();
  }

  /// Create a test box with initial data
  static Future<Box<T>> createTestBox<T>(
    String boxName,
    List<T> initialData,
  ) async {
    final box = await Hive.openBox<T>(boxName);
    await box.clear();
    await box.addAll(initialData);
    return box;
  }
}