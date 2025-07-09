import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/expense_local_data_source_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/get_all_expenses.dart';
import '../../domain/usecases/get_expenses_by_date_range.dart';

// Data Source Provider (async)
final expenseLocalDataSourceProvider =
    FutureProvider<ExpenseLocalDataSourceImpl>((ref) async {
  final dataSource = ExpenseLocalDataSourceImpl();
  await dataSource.init();
  return dataSource;
});

// Repository Provider (async)
final expenseRepositoryProvider =
    FutureProvider<ExpenseRepositoryImpl>((ref) async {
  final dataSource = await ref.watch(expenseLocalDataSourceProvider.future);
  return ExpenseRepositoryImpl(dataSource);
});

// Use Cases Providers (async)
final getAllExpensesProvider = FutureProvider<GetAllExpenses>((ref) async {
  final repository = await ref.watch(expenseRepositoryProvider.future);
  return GetAllExpenses(repository);
});

final createExpenseProvider = FutureProvider<CreateExpense>((ref) async {
  final repository = await ref.watch(expenseRepositoryProvider.future);
  return CreateExpense(repository);
});

final getExpensesByDateRangeProvider =
    FutureProvider<GetExpensesByDateRange>((ref) async {
  final repository = await ref.watch(expenseRepositoryProvider.future);
  return GetExpensesByDateRange(repository);
});

// State Providers (async)
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  ExpenseNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final getAllExpenses = await ref.read(getAllExpensesProvider.future);
      final result = await getAllExpenses();
      state = result.fold(
        (failure) =>
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (expenses) => AsyncValue.data(expenses),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense({
    required String title,
    required String description,
    required double amount,
    required String category,
    required ExpenseType type,
    required DateTime date,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? nextOccurrence,
    DateTime? endDate,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();
    final expense = Expense(
      id: uuid.v4(),
      title: title,
      description: description,
      amount: amount,
      category: category,
      type: type,
      date: date,
      createdAt: now,
      updatedAt: now,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      nextOccurrence: nextOccurrence,
      endDate: endDate,
    );
    final createExpense = await ref.read(createExpenseProvider.future);
    final result = await createExpense(expense);
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        _loadExpenses();
      },
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final repository = await ref.read(expenseRepositoryProvider.future);
    final result = await repository.updateExpense(expense);
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        _loadExpenses();
      },
    );
  }

  Future<void> deleteExpense(String id) async {
    final repository = await ref.read(expenseRepositoryProvider.future);
    final result = await repository.deleteExpense(id);
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        _loadExpenses();
      },
    );
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpenseNotifier(ref);
});

class ExpenseStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref ref;
  late final ProviderSubscription<AsyncValue<List<Expense>>> _expensesSub;

  ExpenseStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to changes in the expenses provider
    _expensesSub = ref.listen<AsyncValue<List<Expense>>>(
      expenseNotifierProvider,
      (previous, next) {
        if (next is AsyncData<List<Expense>>) {
          state = AsyncValue.data(_calculateStats(next.value ?? []));
        } else if (next is AsyncError) {
          state = AsyncValue.error(next.error!, next.stackTrace!);
        } else {
          state = const AsyncValue.loading();
        }
      },
      fireImmediately: true, // So it runs on initialization too
    );
  }

  @override
  void dispose() {
    _expensesSub.close();
    super.dispose();
  }

  Map<String, dynamic> _calculateStats(List<Expense> expenses) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthlyExpenses = expenses
        .where((expense) =>
            expense.isExpense &&
            expense.date
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();
    final monthlyIncome = expenses
        .where((expense) =>
            expense.isIncome &&
            expense.date
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();
    final totalExpenses =
        monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalIncome =
        monthlyIncome.fold(0.0, (sum, expense) => sum + expense.amount);
    final balance = totalIncome - totalExpenses;
    final categoryExpenseBreakdown = <String, double>{};
    for (final expense in monthlyExpenses) {
      categoryExpenseBreakdown[expense.category] =
          (categoryExpenseBreakdown[expense.category] ?? 0.0) + expense.amount;
    }
    final categoryIncomeBreakdown = <String, double>{};
    for (final income in monthlyIncome) {
      categoryIncomeBreakdown[income.category] =
          (categoryIncomeBreakdown[income.category] ?? 0.0) + income.amount;
    }
    // Daily trend
    final Map<DateTime, Map<String, double>> dailyTotals = {};
    for (var d = startOfMonth;
        !d.isAfter(endOfMonth);
        d = d.add(const Duration(days: 1))) {
      final dayExpenses = monthlyExpenses
          .where((e) =>
              e.date.year == d.year &&
              e.date.month == d.month &&
              e.date.day == d.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      final dayIncome = monthlyIncome
          .where((e) =>
              e.date.year == d.year &&
              e.date.month == d.month &&
              e.date.day == d.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      dailyTotals[d] = {
        'expenses': dayExpenses,
        'income': dayIncome,
        'balance': dayIncome - dayExpenses,
      };
    }
    // Weekly trend (weeks start on Monday)
    final Map<int, Map<String, double>> weeklyTotals = {};
    for (final e in monthlyExpenses + monthlyIncome) {
      final week = _weekOfMonth(e.date);
      weeklyTotals[week] ??= {'expenses': 0.0, 'income': 0.0, 'balance': 0.0};
      if (e.isExpense) {
        weeklyTotals[week]!['expenses'] =
            weeklyTotals[week]!['expenses']! + e.amount;
      } else {
        weeklyTotals[week]!['income'] =
            weeklyTotals[week]!['income']! + e.amount;
      }
    }
    for (final week in weeklyTotals.keys) {
      final w = weeklyTotals[week]!;
      w['balance'] = w['income']! - w['expenses']!;
    }
    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'balance': balance,
      'categoryExpenseBreakdown': categoryExpenseBreakdown,
      'categoryIncomeBreakdown': categoryIncomeBreakdown,
      'expenseCount': monthlyExpenses.length,
      'incomeCount': monthlyIncome.length,
      'dailyTotals': dailyTotals,
      'weeklyTotals': weeklyTotals,
    };
  }

  int _weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final diff = date.difference(firstDay).inDays;
    return ((diff + firstDay.weekday - 1) / 7).floor() + 1;
  }
}

final expenseStatsNotifierProvider = StateNotifierProvider<ExpenseStatsNotifier,
    AsyncValue<Map<String, dynamic>>>((ref) {
  return ExpenseStatsNotifier(ref);
});

class FilteredExpensesNotifier
    extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  FilteredExpensesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFiltered();
  }

  Future<void> _loadFiltered() async {
    state = const AsyncValue.loading();
    try {
      final expenses = ref.read(expenseNotifierProvider).value ?? [];
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    final getExpensesByDateRange =
        await ref.read(getExpensesByDateRangeProvider.future);
    final result = await getExpensesByDateRange(start, end);
    result.fold(
      (failure) => state =
          AsyncValue.error(Exception(failure.message), StackTrace.current),
      (expenses) => state = AsyncValue.data(expenses),
    );
  }

  void filterByCategory(String category) {
    state.whenData((expenses) {
      final filtered =
          expenses.where((expense) => expense.category == category).toList();
      state = AsyncValue.data(filtered);
    });
  }

  void filterByType(ExpenseType type) {
    state.whenData((expenses) {
      final filtered =
          expenses.where((expense) => expense.type == type).toList();
      state = AsyncValue.data(filtered);
    });
  }

  void clearFilters() {
    _loadFiltered();
  }
}

final filteredExpensesNotifierProvider =
    StateNotifierProvider<FilteredExpensesNotifier, AsyncValue<List<Expense>>>(
        (ref) {
  return FilteredExpensesNotifier(ref);
});

class SmartTipsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref ref;
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>>> _statsSub;

  SmartTipsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _statsSub = ref.listen<AsyncValue<Map<String, dynamic>>>(
      expenseStatsNotifierProvider,
      (prev, next) {
        if (next is AsyncData<Map<String, dynamic>>) {
          state = AsyncValue.data(_generateTips(next.value ?? {}));
        } else if (next is AsyncError) {
          state = AsyncValue.error(next.error!, next.stackTrace!);
        } else {
          state = const AsyncValue.loading();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _statsSub.close();
    super.dispose();
  }

  List<String> _generateTips(Map<String, dynamic> stats) {
    final tips = <String>[];
    final totalExpenses = stats['totalExpenses'] as double? ?? 0.0;
    final totalIncome = stats['totalIncome'] as double? ?? 0.0;
    final balance = stats['balance'] as double? ?? 0.0;
    final expenseCount = stats['expenseCount'] as int? ?? 0;
    final incomeCount = stats['incomeCount'] as int? ?? 0;
    final categoryExpenseBreakdown =
        stats['categoryExpenseBreakdown'] as Map<String, double>? ?? {};
    final now = DateTime.now();
    // 1. High spending tip
    if (totalIncome > 0 && totalExpenses > totalIncome * 0.8) {
      tips.add(
          "You're spending over 80% of your income. Consider saving more this month.");
    }
    // 2. No income tip
    if (incomeCount == 0) {
      tips.add(
          "No income recorded this month. Add your income to track your balance.");
    }
    // 3. Category spike tip
    if (categoryExpenseBreakdown.isNotEmpty) {
      final maxCat = categoryExpenseBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (maxCat.value > totalExpenses * 0.3) {
        tips.add(
            "High spending on '${maxCat.key}': ${maxCat.value.toStringAsFixed(2)} this month.");
      }
    }
    // 4. Low balance tip
    if (balance < 0) {
      tips.add(
          "Your balance is negative. Try to reduce expenses or increase income.");
    }
    // 5. Few expenses tip
    if (expenseCount < 3) {
      tips.add("Add more expenses to get better insights and tips.");
    }
    if (tips.isEmpty) {
      tips.add("Great job! Your spending is under control this month.");
    }
    return tips.take(3).toList();
  }
}

final smartTipsNotifierProvider =
    StateNotifierProvider<SmartTipsNotifier, AsyncValue<List<String>>>((ref) {
  return SmartTipsNotifier(ref);
});
