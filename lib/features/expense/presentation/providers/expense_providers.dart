// This file defines all Riverpod providers and notifiers for the expense feature.
// It acts as the ViewModel layer in MVVM, exposing state and business logic to the UI.
// Providers connect the UI to the domain and data layers, enforcing Clean Architecture and SOLID.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/expense_local_data_source_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/get_all_expenses.dart';
import '../../domain/usecases/get_expenses_by_date_range.dart';
import '../../domain/usecases/update_expense.dart';
import 'package:expense_tracker/core/errors/failures.dart';

// Data Source Provider (async)
// Provides the local data source (Hive) for dependency injection.
final expenseLocalDataSourceProvider =
    FutureProvider<ExpenseLocalDataSourceImpl>((ref) async {
  final dataSource = ExpenseLocalDataSourceImpl();
  await dataSource.init();
  return dataSource;
});

// Repository Provider (async)
// Provides the repository implementation for dependency injection.
final expenseRepositoryProvider =
    FutureProvider<ExpenseRepositoryImpl>((ref) async {
  final dataSource = await ref.watch(expenseLocalDataSourceProvider.future);
  return ExpenseRepositoryImpl(dataSource);
});

// Use Cases Providers (async)
// Each use case is provided as a dependency for notifiers and UI.
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

final updateExpenseProvider = FutureProvider<UpdateExpense>((ref) async {
  final repository = await ref.watch(expenseRepositoryProvider.future);
  return UpdateExpense(repository);
});

// State Notifier for managing the list of expenses (ViewModel for expenses)
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  bool _isLoading = false;
  bool _hasLoaded = false;

  ExpenseNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Immediate loading but with error handling
    _loadExpenses();
  }

  // Loads all expenses from the repository and updates state.
  Future<void> _loadExpenses() async {
    if (_isLoading || _hasLoaded) return; // Prevent multiple simultaneous loads
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      debugPrint('Loading expenses...');
      final getAllExpenses = await ref.read(getAllExpensesProvider.future);
      debugPrint('Got getAllExpenses use case');
      final result = await getAllExpenses();
      debugPrint('Got result: ${result.isRight()}');
      state = result.fold(
        (failure) {
          debugPrint('Failure: ${failure.message}');
          return AsyncValue.error(
              Exception(failure.message), StackTrace.current);
        },
        (expenses) {
          debugPrint('Success: ${expenses.length} expenses loaded');
          return AsyncValue.data(expenses);
        },
      );
      _hasLoaded = true;
    } catch (e, st) {
      debugPrint('Exception in _loadExpenses: $e');
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  // Refresh expenses data
  Future<void> refresh() async {
    _hasLoaded = false;
    await _loadExpenses();
  }

  // Adds a new expense using the CreateExpense use case.
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
      (failure) {
        if (failure is ValidationFailure) {
          throw Exception(failure.message);
        } else {
          throw Exception(failure.message);
        }
      },
      (_) {
        _loadExpenses();
      },
    );
  }

  // Updates an existing expense using the UpdateExpense use case.
  Future<void> updateExpense(Expense expense) async {
    final updateExpense = await ref.read(updateExpenseProvider.future);
    final result = await updateExpense(expense);
    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          throw Exception(failure.message);
        } else {
          throw Exception(failure.message);
        }
      },
      (_) {
        _loadExpenses();
      },
    );
  }

  // Deletes an expense by ID using the repository.
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

// Provider for the ExpenseNotifier (ViewModel for expenses)
final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpenseNotifier(ref);
});

class ExpenseStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref ref;
  late final ProviderSubscription<AsyncValue<List<Expense>>> _expensesSub;

  ExpenseStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to changes in the expenses provider with memory optimization
    _expensesSub = ref.listen<AsyncValue<List<Expense>>>(
      expenseNotifierProvider,
      (previous, next) {
        if (next is AsyncData<List<Expense>>) {
          // Calculate stats directly for better memory management
          _calculateStatsInIsolate(next.value ?? []);
        } else if (next is AsyncError) {
          state = AsyncValue.error(next.error!, next.stackTrace!);
        } else {
          state = const AsyncValue.loading();
        }
      },
      fireImmediately: false, // Reduce initial load for better stability
    );
  }

  @override
  void dispose() {
    _expensesSub.close();
    super.dispose();
  }

  /// Calculate stats directly for stability
  Future<void> _calculateStatsInIsolate(List<Expense> expenses) async {
    try {
      final stats = _calculateStatsInBackground(expenses);
      if (mounted) {
        state = AsyncValue.data(stats);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  /// Background isolate function for stats calculation
  static Map<String, dynamic> _calculateStatsInBackground(
      List<Expense> expenses) {
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

    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'balance': balance,
      'expenseCount': monthlyExpenses.length,
      'incomeCount': monthlyIncome.length,
      'categoryExpenseBreakdown': categoryExpenseBreakdown,
      'categoryIncomeBreakdown': categoryIncomeBreakdown,
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

/// Notifier for generating smart spending tips based on user stats.
class SmartTipsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref ref;
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>>> _statsSub;

  SmartTipsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _statsSub = ref.listen<AsyncValue<Map<String, dynamic>>>(
      expenseStatsNotifierProvider,
      (prev, next) {
        if (next is AsyncData<Map<String, dynamic>>) {
          state = AsyncValue.data(_generateTipKeys(next.value ?? {}));
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

  /// Generates a list of smart tip keys based on stats.
  List<String> _generateTipKeys(Map<String, dynamic> stats) {
    final tips = <String>[];
    final totalExpenses = stats['totalExpenses'] as double? ?? 0.0;
    final totalIncome = stats['totalIncome'] as double? ?? 0.0;
    final balance = stats['balance'] as double? ?? 0.0;
    final expenseCount = stats['expenseCount'] as int? ?? 0;
    final incomeCount = stats['incomeCount'] as int? ?? 0;
    final categoryExpenseBreakdown =
        stats['categoryExpenseBreakdown'] as Map<String, double>? ?? {};
    // 1. High spending tip
    if (totalIncome > 0 && totalExpenses > totalIncome * 0.8) {
      tips.add('tipHighSpending');
    }
    // 2. No income tip
    if (incomeCount == 0) {
      tips.add('tipNoIncome');
    }
    // 3. Category spike tip
    if (categoryExpenseBreakdown.isNotEmpty) {
      final maxCat = categoryExpenseBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (maxCat.value > totalExpenses * 0.3) {
        tips.add('tipCategorySpike:${maxCat.key}');
      }
    }
    // 4. Low balance tip
    if (balance < 0) {
      tips.add('tipNegativeBalance');
    }
    // 5. Few expenses tip
    if (expenseCount < 3) {
      tips.add('tipFewExpenses');
    }
    if (tips.isEmpty) {
      tips.add('tipAllGood');
    }
    return tips.take(3).toList();
  }
}

final smartTipsNotifierProvider =
    StateNotifierProvider<SmartTipsNotifier, AsyncValue<List<String>>>((ref) {
  return SmartTipsNotifier(ref);
});

// Category Notifier and Provider
class CategoryNotifier extends StateNotifier<AsyncValue<List<String>>> {
  CategoryNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  late final CategoryLocalDataSourceImpl _ds;

  Future<void> _init() async {
    _ds = CategoryLocalDataSourceImpl();
    await _ds.init();
    _loadCategories();
  }

  void _loadCategories() {
    try {
      final categories = _ds.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Add this public method for UI to trigger reload
  void loadCategories() => _loadCategories();

  Future<void> addCategory(String category) async {
    try {
      await _ds.addCategory(category);
      _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> editCategory(String oldCategory, String newCategory) async {
    try {
      await _ds.editCategory(oldCategory, newCategory);
      _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteCategory(String category) async {
    try {
      final result = await _ds.deleteCategory(category);
      _loadCategories();
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<String>>>((ref) {
  return CategoryNotifier();
});
