import 'package:hive/hive.dart';
import '../models/budget_model.dart';
import '../../domain/entities/budget.dart';
import 'package:flutter/foundation.dart';

abstract class BudgetLocalDataSource {
  Future<List<Budget>> getAllBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<List<Budget>> getBudgetsByCategory(String categoryId);
  Future<List<Budget>> getActiveBudgets();
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> updateSpentAmount(String budgetId, double spentAmount);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  static const String _boxName = 'budgets';
  late Box<BudgetModel> _budgetBox;

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _budgetBox = await Hive.openBox<BudgetModel>(_boxName);
    } else {
      _budgetBox = Hive.box<BudgetModel>(_boxName);
    }
  }

  /// Seed comprehensive budget dummy data for widget testing
  Future<void> seedComprehensiveBudgetData() async {
    await _initBox();

    // Force reseed for testing - clear existing data first
    if (_budgetBox.isNotEmpty) {
      debugPrint('Clearing existing budget data for fresh seeding...');
      await _budgetBox.clear();
    }

    debugPrint('Seeding comprehensive budget dummy data...');
    final now = DateTime.now();
    final List<BudgetModel> dummyBudgets = [];

    // Helper function to add budget with validation
    void addIfValid({
      required String id,
      required String categoryId,
      required double amount,
      required double spentAmount,
      required DateTime startDate,
      required DateTime endDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      bool isActive = true,
      String period = 'monthly',
    }) {
      try {
        final budget = BudgetModel(
          id: id,
          categoryId: categoryId,
          amount: amount,
          period: period,
          startDate: startDate,
          endDate: endDate,
          spentAmount: spentAmount,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        dummyBudgets.add(budget);
      } catch (e) {
        debugPrint('Failed to create budget $id: $e');
      }
    }

    // All available categories for comprehensive testing
    final allCategories = [
      'food',
      'transport',
      'entertainment',
      'shopping',
      'health',
      'education',
      'bills',
      'salary',
      'investments',
      'gifts',
      'pets',
      'travel',
      'home',
      'technology',
      'sports',
      'beauty',
      'books',
      'charity',
      'insurance',
      'taxes'
    ];

    int id = 1;

    // 1. REGULAR MONTHLY BUDGETS - All categories
    for (final cat in allCategories) {
      final baseAmount = 100.0 + (id % 500);
      final spentAmount =
          (baseAmount * (0.3 + (id % 7) * 0.1)).clamp(0.0, baseAmount);

      addIfValid(
        id: (id++).toString(),
        categoryId: cat,
        amount: baseAmount,
        spentAmount: spentAmount,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now.subtract(Duration(days: id % 30)),
        updatedAt: now.subtract(Duration(days: id % 30)),
      );
    }

    // 2. YEARLY BUDGETS
    final yearlyCategories = ['travel', 'education', 'investments', 'home'];
    for (final cat in yearlyCategories) {
      final baseAmount = 1000.0 + (id % 5000);
      final spentAmount =
          (baseAmount * (0.2 + (id % 8) * 0.1)).clamp(0.0, baseAmount);

      addIfValid(
        id: (id++).toString(),
        categoryId: cat,
        amount: baseAmount,
        spentAmount: spentAmount,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        createdAt: now.subtract(Duration(days: id % 365)),
        updatedAt: now.subtract(Duration(days: id % 365)),
        period: 'yearly',
      );
    }

    // 3. EDGE CASES - Amount ranges
    addIfValid(
      id: (id++).toString(),
      categoryId: 'other',
      amount: 0.01,
      spentAmount: 0.0,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'investments',
      amount: 1000000.00,
      spentAmount: 500000.00,
      startDate: now,
      endDate: now.add(const Duration(days: 365)),
      createdAt: now,
      updatedAt: now,
      period: 'yearly',
    );

    // 4. OVER-BUDGET SCENARIOS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'shopping',
      amount: 500.00,
      spentAmount: 750.00,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'entertainment',
      amount: 200.00,
      spentAmount: 250.00,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 3)),
    );

    // 5. NEAR-LIMIT SCENARIOS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'food',
      amount: 300.00,
      spentAmount: 285.00,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'transport',
      amount: 150.00,
      spentAmount: 142.50,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    // 6. UNDER-BUDGET SCENARIOS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'health',
      amount: 200.00,
      spentAmount: 50.00,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 7)),
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'education',
      amount: 500.00,
      spentAmount: 100.00,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 10)),
    );

    // 7. EXPIRED BUDGETS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'bills',
      amount: 400.00,
      spentAmount: 380.00,
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0),
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now.subtract(const Duration(days: 5)),
      isActive: false,
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'insurance',
      amount: 300.00,
      spentAmount: 300.00,
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0),
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now.subtract(const Duration(days: 5)),
      isActive: false,
    );

    // 8. FUTURE BUDGETS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'travel',
      amount: 2000.00,
      spentAmount: 0.0,
      startDate: now.add(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 60)),
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'holidays',
      amount: 1000.00,
      spentAmount: 0.0,
      startDate: DateTime(now.year, 12, 1),
      endDate: DateTime(now.year, 12, 31),
      createdAt: now,
      updatedAt: now,
    );

    // 9. ZERO SPENT BUDGETS
    addIfValid(
      id: (id++).toString(),
      categoryId: 'charity',
      amount: 100.00,
      spentAmount: 0.0,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
    );

    addIfValid(
      id: (id++).toString(),
      categoryId: 'books',
      amount: 50.00,
      spentAmount: 0.0,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
    );

    // 10. DECIMAL PRECISION TESTING
    addIfValid(
      id: (id++).toString(),
      categoryId: 'other',
      amount: 123.456789,
      spentAmount: 98.765432,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    // Batch insert all valid budgets
    final validBudgets = dummyBudgets
        .where((budget) =>
            budget.amount.isFinite &&
            budget.amount > 0 &&
            budget.spentAmount >= 0 &&
            budget.spentAmount <= budget.amount)
        .toList();

    debugPrint('Adding ${validBudgets.length} dummy budgets...');

    // Use batch operation for efficiency
    final batch = <String, BudgetModel>{};
    for (final budget in validBudgets) {
      batch[budget.id] = budget;
    }

    await _budgetBox.putAll(batch);
    debugPrint('Successfully added ${batch.length} dummy budgets');
  }

  @override
  Future<List<Budget>> getAllBudgets() async {
    await _initBox();
    return _budgetBox.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    await _initBox();
    final model = _budgetBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<List<Budget>> getBudgetsByCategory(String categoryId) async {
    await _initBox();
    return _budgetBox.values
        .where((model) => model.categoryId == categoryId)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<Budget>> getActiveBudgets() async {
    await _initBox();
    return _budgetBox.values
        .where((model) => model.isActive)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> createBudget(Budget budget) async {
    await _initBox();
    final model = BudgetModel.fromEntity(budget);
    await _budgetBox.put(budget.id, model);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _initBox();
    final model = BudgetModel.fromEntity(budget);
    await _budgetBox.put(budget.id, model);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _initBox();
    await _budgetBox.delete(id);
  }

  @override
  Future<void> updateSpentAmount(String budgetId, double spentAmount) async {
    await _initBox();
    final model = _budgetBox.get(budgetId);
    if (model != null) {
      final updatedModel = model.copyWith(
        spentAmount: spentAmount,
        updatedAt: DateTime.now(),
      );
      await _budgetBox.put(budgetId, updatedModel);
    }
  }
}
