import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'expense_local_data_source.dart';

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  static const String _boxName = 'expenses';
  late Box<ExpenseModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<ExpenseModel>(_boxName);
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    return _box.values.toList();
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    try {
      return _box.values.firstWhere(
        (expense) => expense.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _box.values.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByCategory(String category) async {
    return _box.values.where((expense) {
      return expense.category.toString().split('.').last == category;
    }).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByType(String type) async {
    return _box.values.where((expense) {
      return expense.type.toString().split('.').last == type;
    }).toList();
  }

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clearAllExpenses() async {
    await _box.clear();
  }
}
