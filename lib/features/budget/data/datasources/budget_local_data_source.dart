import 'package:hive/hive.dart';
import '../models/budget_model.dart';
import '../../domain/entities/budget.dart';

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