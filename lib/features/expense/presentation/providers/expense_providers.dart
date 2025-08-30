// This file defines all Riverpod providers and notifiers for the expense feature.
// It acts as the ViewModel layer in MVVM, exposing state and business logic to the UI.
// Providers connect the UI to the domain and data layers, enforcing Clean Architecture and SOLID.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/expense_local_data_source_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/models/expense_model.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/get_all_expenses.dart';
import '../../domain/usecases/get_expenses_by_date_range.dart';
import '../../domain/usecases/update_expense.dart';
import '../../../../core/providers/simple_sync_provider.dart';

// Data Source Provider (sync initialization) - Fixed timing issues
final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSourceImpl>((ref) {
  final dataSource = ExpenseLocalDataSourceImpl();
  // Remove async initialization - will be handled by lazy loading
  return dataSource;
});

// Repository Provider (sync) - Direct initialization
final expenseRepositoryProvider = Provider<ExpenseRepositoryImpl>((ref) {
  final dataSource = ref.watch(expenseLocalDataSourceProvider);
  return ExpenseRepositoryImpl(dataSource);
});

// Use Cases Providers (sync) - Direct initialization
final getAllExpensesProvider = Provider<GetAllExpenses>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return GetAllExpenses(repository);
});

final createExpenseProvider = Provider<CreateExpense>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return CreateExpense(repository);
});

final getExpensesByDateRangeProvider = Provider<GetExpensesByDateRange>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return GetExpensesByDateRange(repository);
});

final updateExpenseProvider = Provider<UpdateExpense>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return UpdateExpense(repository);
});

// State Notifier for managing the list of expenses (ViewModel for expenses)
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  bool _isLoading = false;
  bool _hasLoaded = false;

  ExpenseNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Immediate loading with proper initialization
    _loadExpenses();
  }

  // Loads all expenses from the repository and updates state.
  Future<void> _loadExpenses() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    _isLoading = true;
    if (mounted) {
      state = const AsyncValue.loading();
    }

    try {
      debugPrint('Loading expenses...');
      
      // Ensure data source is initialized before use
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      
      final getAllExpenses = ref.read(getAllExpensesProvider);
      debugPrint('Got getAllExpenses use case');
      
      final result = await getAllExpenses();
      debugPrint('Got result: ${result.isRight()}');
      
      if (mounted) {
        state = result.fold(
          (failure) {
            debugPrint('Failure: ${failure.message}');
            return AsyncValue.error(
                Exception(failure.message), StackTrace.current);
          },
          (expenses) {
            debugPrint('Success: ${expenses.length} expenses loaded');
            _hasLoaded = true;
            return AsyncValue.data(expenses);
          },
        );
      }
    } catch (e, st) {
      debugPrint('Exception in _loadExpenses: $e');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
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
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final expense = Expense(
        id: uuid.v4(),
        title: title.trim(),
        description: description.trim(),
        amount: amount,
        category: category.trim(),
        type: type,
        date: date,
        createdAt: now,
        updatedAt: now,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        nextOccurrence: nextOccurrence,
        endDate: endDate,
      );

      debugPrint('Creating expense: ${expense.title} - \$${expense.amount}');
      
      // Ensure data source is initialized
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      
      final createExpense = ref.read(createExpenseProvider);
      final result = await createExpense(expense);
      
      result.fold(
        (failure) {
          debugPrint('Failed to create expense: ${failure.message}');
          throw Exception(failure.message);
        },
        (createdExpense) {
          debugPrint('Successfully created expense: ${createdExpense.id}');
          if (mounted) {
            // Force reload to get latest data
            _hasLoaded = false;
            _loadExpenses();
            
            // Trigger outbound sync after successful creation
            _triggerOutboundSync();
          }
        },
      );
    } catch (e) {
      debugPrint('Exception in addExpense: $e');
      rethrow;
    }
  }

  // Updates an existing expense using the UpdateExpense use case.
  Future<void> updateExpense(Expense expense) async {
    try {
      debugPrint('Updating expense: ${expense.id} - ${expense.title}');
      
      // Ensure data source is initialized
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      
      final updateExpense = ref.read(updateExpenseProvider);
      final result = await updateExpense(expense);
      
      result.fold(
        (failure) {
          debugPrint('Failed to update expense: ${failure.message}');
          throw Exception(failure.message);
        },
        (updatedExpense) {
          debugPrint('Successfully updated expense: ${updatedExpense.id}');
          if (mounted) {
            // Force reload to get latest data
            _hasLoaded = false;
            _loadExpenses();
            
            // Trigger outbound sync after successful update
            _triggerOutboundSync();
          }
        },
      );
    } catch (e) {
      debugPrint('Exception in updateExpense: $e');
      rethrow;
    }
  }

  // Deletes an expense by ID using the repository.
  Future<void> deleteExpense(String id) async {
    try {
      debugPrint('Deleting expense: $id');
      
      // Ensure data source is initialized
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      
      final repository = ref.read(expenseRepositoryProvider);
      final result = await repository.deleteExpense(id);
      
      result.fold(
        (failure) {
          debugPrint('Failed to delete expense: ${failure.message}');
          throw Exception(failure.message);
        },
        (_) {
          debugPrint('Successfully deleted expense: $id');
          if (mounted) {
            // Force reload to get latest data
            _hasLoaded = false;
            _loadExpenses();
            
            // Trigger outbound sync after successful deletion
            _triggerOutboundSync();
          }
        },
      );
    } catch (e) {
      debugPrint('Exception in deleteExpense: $e');
      rethrow;
    }
  }

  // Trigger background sync without blocking UI
  void _triggerOutboundSync() {
    // Use fire-and-forget pattern to avoid blocking UI
    Future.microtask(() async {
      try {
        debugPrint('🔄 Triggering outbound sync for expense changes...');
        
        // Get simple sync service from provider
        final syncService = ref.read(simpleSyncServiceProvider);
        
        // Get all expenses that need syncing (for simplicity, we'll sync all)
        final expenses = await _loadExpensesFromDataSource();
        
        int syncedCount = 0;
        for (final expense in expenses) {
          final success = await syncService.syncExpenseToSupabase(expense);
          if (success) syncedCount++;
        }
        
        debugPrint('✅ Sync completed: $syncedCount/${expenses.length} expenses synced');
      } catch (e, stackTrace) {
        debugPrint('❌ Sync trigger failed: $e');
        debugPrint('Stack trace: $stackTrace');
        // Don't throw - sync failures shouldn't break UI operations
      }
    });
  }
  
  // Helper method to load expenses from data source
  Future<List<ExpenseModel>> _loadExpensesFromDataSource() async {
    try {
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      return await dataSource.getAllExpenses();
    } catch (e) {
      debugPrint('Failed to load expenses for sync: $e');
      return [];
    }
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
      fireImmediately: true, // Load immediately for better UX
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
    try {
      // Ensure data source is initialized
      final dataSource = ref.read(expenseLocalDataSourceProvider);
      await dataSource.init();
      
      final getExpensesByDateRange = ref.read(getExpensesByDateRangeProvider);
      final result = await getExpensesByDateRange(start, end);
      
      result.fold(
        (failure) => state =
            AsyncValue.error(Exception(failure.message), StackTrace.current),
        (expenses) => state = AsyncValue.data(expenses),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
