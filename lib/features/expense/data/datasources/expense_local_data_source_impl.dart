import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'expense_local_data_source.dart';
import '../../domain/entities/expense.dart';

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

  /// Seeds the box with dummy data for all categories and types if empty
  Future<void> seedDummyDataIfEmpty() async {
    if (_box.isNotEmpty) return;
    final now = DateTime.now();
    final List<ExpenseModel> dummyExpenses = [
      // Expenses for each category
      ExpenseModel(
        id: '1',
        title: 'Lunch',
        description: 'Lunch at restaurant',
        amount: 15.5,
        category: ExpenseCategory.food,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        metadata: {'note': 'Test food'},
      ),
      ExpenseModel(
        id: '2',
        title: 'Bus Ticket',
        description: 'Daily commute',
        amount: 2.75,
        category: ExpenseCategory.transportation,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        metadata: {'note': 'Test transportation'},
      ),
      ExpenseModel(
        id: '3',
        title: 'Movie Night',
        description: 'Cinema with friends',
        amount: 12.0,
        category: ExpenseCategory.entertainment,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        metadata: {'note': 'Test entertainment'},
      ),
      ExpenseModel(
        id: '4',
        title: 'Clothes Shopping',
        description: 'Bought new jeans',
        amount: 40.0,
        category: ExpenseCategory.shopping,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        metadata: {'note': 'Test shopping'},
      ),
      ExpenseModel(
        id: '5',
        title: 'Doctor Visit',
        description: 'Annual checkup',
        amount: 60.0,
        category: ExpenseCategory.health,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        metadata: {'note': 'Test health'},
      ),
      ExpenseModel(
        id: '6',
        title: 'Online Course',
        description: 'Flutter course',
        amount: 100.0,
        category: ExpenseCategory.education,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
        metadata: {'note': 'Test education'},
      ),
      ExpenseModel(
        id: '7',
        title: 'Electricity Bill',
        description: 'Monthly bill',
        amount: 75.0,
        category: ExpenseCategory.utilities,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        metadata: {'note': 'Test utilities'},
      ),
      ExpenseModel(
        id: '8',
        title: 'Rent Payment',
        description: 'Monthly rent',
        amount: 1200.0,
        category: ExpenseCategory.rent,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
        metadata: {'note': 'Test rent'},
      ),
      ExpenseModel(
        id: '9',
        title: 'Insurance Premium',
        description: 'Car insurance',
        amount: 200.0,
        category: ExpenseCategory.insurance,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 9)),
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 9)),
        metadata: {'note': 'Test insurance'},
      ),
      ExpenseModel(
        id: '10',
        title: 'Miscellaneous',
        description: 'Other expense',
        amount: 25.0,
        category: ExpenseCategory.other,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
        metadata: {'note': 'Test other'},
      ),
      // Incomes for some categories
      ExpenseModel(
        id: '11',
        title: 'Salary',
        description: 'Monthly salary',
        amount: 3000.0,
        category: ExpenseCategory.other,
        type: ExpenseType.income,
        date: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        metadata: {'note': 'Test income'},
      ),
      ExpenseModel(
        id: '12',
        title: 'Freelance',
        description: 'Freelance project',
        amount: 800.0,
        category: ExpenseCategory.education,
        type: ExpenseType.income,
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        metadata: {'note': 'Test freelance income'},
      ),
      ExpenseModel(
        id: '13',
        title: 'Gift',
        description: 'Birthday gift',
        amount: 100.0,
        category: ExpenseCategory.entertainment,
        type: ExpenseType.income,
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        metadata: {'note': 'Test gift income'},
      ),
    ];
    for (final expense in dummyExpenses) {
      await _box.put(expense.id, expense);
    }
  }
}
