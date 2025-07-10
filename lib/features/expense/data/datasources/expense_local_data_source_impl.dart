import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'expense_local_data_source.dart';
import '../../domain/entities/expense.dart';
import 'package:uuid/uuid.dart';

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
      return expense.category == category;
    }).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByType(ExpenseType type) async {
    return _box.values.where((expense) => expense.type == type).toList();
  }

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    if (expense.id.trim().isEmpty ||
        expense.title.trim().isEmpty ||
        expense.category.trim().isEmpty ||
        expense.amount.isNaN ||
        expense.amount.isInfinite ||
        expense.amount <= 0) {
      throw Exception('Invalid expense data');
    }
    await _box.put(expense.id, expense);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id.trim().isEmpty ||
        expense.title.trim().isEmpty ||
        expense.category.trim().isEmpty ||
        expense.amount.isNaN ||
        expense.amount.isInfinite ||
        expense.amount <= 0) {
      throw Exception('Invalid expense data');
    }
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
    // Add custom categories to categories box if not present
    final categoryBox = await Hive.openBox<String>('categories');
    final customCategories = ['travel', 'pets', 'gifts', 'investments'];
    for (final cat in customCategories) {
      if (!categoryBox.values.contains(cat)) {
        await categoryBox.add(cat);
      }
    }
    final allCategories =
        CategoryLocalDataSourceImpl.defaultCategories + customCategories;
    final List<ExpenseModel> dummyExpenses = [];
    // Helper to safely add only valid dummy data
    void addIfValid({
      required String id,
      required String title,
      required String description,
      required double amount,
      required String category,
      required ExpenseType type,
      required DateTime date,
      required DateTime createdAt,
      required DateTime updatedAt,
      Map<String, dynamic>? metadata,
      bool isRecurring = false,
      String? recurringFrequency,
      DateTime? nextOccurrence,
      DateTime? endDate,
    }) {
      if (amount.isNaN || amount.isInfinite || amount <= 0 || amount > 1000000) {
        return;
      }
      if (title.trim().isEmpty) return;
      if (category.trim().isEmpty) return;
      dummyExpenses.add(ExpenseModel(
        id: id,
        title: title,
        description: description,
        amount: amount,
        category: category,
        type: type,
        date: date,
        createdAt: createdAt,
        updatedAt: updatedAt,
        metadata: metadata,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        nextOccurrence: nextOccurrence,
        endDate: endDate,
      ));
    }

    // For all edge/dummy cases, use addIfValid instead of direct ExpenseModel
    dummyExpenses.clear();
    int id = 1;
    for (final cat in allCategories) {
      addIfValid(
        id: (id++).toString(),
        title: 'Expense $cat',
        description: 'Test expense in $cat',
        amount: 10.0 + id,
        category: cat,
        type: ExpenseType.expense,
        date: now.subtract(Duration(days: id)),
        createdAt: now.subtract(Duration(days: id)),
        updatedAt: now.subtract(Duration(days: id)),
        metadata: {'note': 'Test $cat expense'},
      );
      addIfValid(
        id: (id++).toString(),
        title: 'Income $cat',
        description: 'Test income in $cat',
        amount: 20.0 + id,
        category: cat,
        type: ExpenseType.income,
        date: now.subtract(Duration(days: id)),
        createdAt: now.subtract(Duration(days: id)),
        updatedAt: now.subtract(Duration(days: id)),
        metadata: {'note': 'Test $cat income'},
      );
      addIfValid(
        id: (id++).toString(),
        title: 'Recurring $cat',
        description: 'Recurring expense in $cat',
        amount: 5.0 + id,
        category: cat,
        type: ExpenseType.expense,
        date: now.subtract(Duration(days: id)),
        createdAt: now.subtract(Duration(days: id)),
        updatedAt: now.subtract(Duration(days: id)),
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 90)),
        metadata: {'note': 'Recurring $cat expense'},
      );
    }
    // For all edge/dummy cases, use addIfValid instead of direct ExpenseModel
    addIfValid(
      id: (id++).toString(),
      title: 'Large Amount',
      description: 'Edge case: large',
      amount: 1000000.0,
      category: 'investments',
      type: ExpenseType.income,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Small Amount',
      description: 'Edge case: small',
      amount: 0.01,
      category: 'gifts',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Future Expense',
      description: 'Edge case: future',
      amount: 123.45,
      category: 'travel',
      type: ExpenseType.expense,
      date: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Past Expense',
      description: 'Edge case: past',
      amount: 67.89,
      category: 'pets',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 365)),
      createdAt: now.subtract(const Duration(days: 365)),
      updatedAt: now.subtract(const Duration(days: 365)),
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Recurring Income',
      description: 'Edge case: recurring income',
      amount: 500.0,
      category: 'salary',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 10)),
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
      isRecurring: true,
      recurringFrequency: 'weekly',
      nextOccurrence: now.add(const Duration(days: 7)),
      endDate: now.add(const Duration(days: 365)),
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Minimal Fields',
      description: '',
      amount: 42.0,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // All other edge cases: wrap in addIfValid, skip direct ExpenseModel(...)
    // Very long title/description
    addIfValid(
      id: (id++).toString(),
      title: 'L' * 200,
      description: 'D' * 500,
      amount: 123.45,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Special characters/emoji
    addIfValid(
      id: (id++).toString(),
      title: 'Groceries 🛒🥦',
      description: 'Bought milk, eggs, and bread! #breakfast 🍞🥚',
      amount: 55.55,
      category: 'food',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Duplicate category names (case sensitivity)
    addIfValid(
      id: (id++).toString(),
      title: 'Case Test',
      description: 'Category: Food vs food',
      amount: 10.0,
      category: 'Food', // capital F
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Leap day (Feb 29)
    addIfValid(
      id: (id++).toString(),
      title: 'Leap Day',
      description: 'Expense on Feb 29',
      amount: 29.0,
      category: 'other',
      type: ExpenseType.expense,
      date: DateTime(2020, 2, 29),
      createdAt: DateTime(2020, 2, 29),
      updatedAt: DateTime(2020, 2, 29),
    );
    // Year boundary (Dec 31, Jan 1)
    addIfValid(
      id: (id++).toString(),
      title: 'New Year Eve',
      description: 'Expense on Dec 31',
      amount: 100.0,
      category: 'entertainment',
      type: ExpenseType.expense,
      date: DateTime(now.year, 12, 31),
      createdAt: DateTime(now.year, 12, 31),
      updatedAt: DateTime(now.year, 12, 31),
    );
    addIfValid(
      id: (id++).toString(),
      title: 'New Year Day',
      description: 'Expense on Jan 1',
      amount: 101.0,
      category: 'entertainment',
      type: ExpenseType.expense,
      date: DateTime(now.year + 1, 1, 1),
      createdAt: DateTime(now.year + 1, 1, 1),
      updatedAt: DateTime(now.year + 1, 1, 1),
    );
    // Null/empty metadata
    addIfValid(
      id: (id++).toString(),
      title: 'No Metadata',
      description: 'No metadata field',
      amount: 12.0,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
      metadata: null,
    );
    // Only required fields
    addIfValid(
      id: (id++).toString(),
      title: 'Minimal',
      description: '',
      amount: 1.0,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Same date/time (duplicates)
    addIfValid(
      id: (id++).toString(),
      title: 'Duplicate 1',
      description: 'Same date/time',
      amount: 5.0,
      category: 'other',
      type: ExpenseType.expense,
      date: DateTime(2022, 5, 5, 12, 0),
      createdAt: DateTime(2022, 5, 5, 12, 0),
      updatedAt: DateTime(2022, 5, 5, 12, 0),
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Duplicate 2',
      description: 'Same date/time',
      amount: 6.0,
      category: 'other',
      type: ExpenseType.expense,
      date: DateTime(2022, 5, 5, 12, 0),
      createdAt: DateTime(2022, 5, 5, 12, 0),
      updatedAt: DateTime(2022, 5, 5, 12, 0),
    );
    // Extremely old/future dates
    addIfValid(
      id: (id++).toString(),
      title: 'Very Old',
      description: 'Year 1900',
      amount: 19.0,
      category: 'other',
      type: ExpenseType.expense,
      date: DateTime(1900, 1, 1),
      createdAt: DateTime(1900, 1, 1),
      updatedAt: DateTime(1900, 1, 1),
    );
    addIfValid(
      id: (id++).toString(),
      title: 'Very Future',
      description: 'Year 2100',
      amount: 21.0,
      category: 'other',
      type: ExpenseType.expense,
      date: DateTime(2100, 1, 1),
      createdAt: DateTime(2100, 1, 1),
      updatedAt: DateTime(2100, 1, 1),
    );
    // Whitespace-only title/description
    addIfValid(
      id: (id++).toString(),
      title: '   ',
      description: '   ',
      amount: 7.0,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Non-ASCII category
    addIfValid(
      id: (id++).toString(),
      title: 'Non-ASCII Category',
      description: 'Категория',
      amount: 8.0,
      category: 'категория',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );
    // Only add valid dummy data (matches model assertions)
    for (final expense in dummyExpenses) {
      if (expense.amount.isNaN ||
          expense.amount.isInfinite ||
          expense.amount <= 0 ||
          expense.title.trim().isEmpty ||
          expense.category.trim().isEmpty) {
        continue;
      }
      await _box.put(expense.id, expense);
    }
  }

  /// Process recurring expenses: auto-generate entries for due recurring items
  Future<void> processRecurringExpenses() async {
    final now = DateTime.now();
    final List<ExpenseModel> toAdd = [];
    for (final expense in _box.values) {
      if (expense.isRecurring && expense.nextOccurrence != null) {
        final next = expense.nextOccurrence!;
        final ended = expense.endDate != null && now.isAfter(expense.endDate!);
        if (!ended && (next.isBefore(now) || next.isSameDate(now))) {
          // Clone for today
          final newExpense = expense.copyWith(
            id: const Uuid().v4(),
            date: next,
            createdAt: now,
            updatedAt: now,
            isRecurring: false, // The generated entry is not recurring
            recurringFrequency: null,
            nextOccurrence: null,
            endDate: null,
          );
          toAdd.add(newExpense);
          // Update nextOccurrence for the recurring expense
          DateTime nextDate = next;
          switch (expense.recurringFrequency) {
            case 'daily':
              nextDate = next.add(const Duration(days: 1));
              break;
            case 'weekly':
              nextDate = next.add(const Duration(days: 7));
              break;
            case 'monthly':
              nextDate = DateTime(next.year, next.month + 1, next.day);
              break;
            default:
              nextDate = next.add(const Duration(days: 1));
          }
          final updated = expense.copyWith(nextOccurrence: nextDate);
          await _box.put(expense.id, updated);
        }
      }
    }
    for (final e in toAdd) {
      await _box.put(e.id, e);
    }
  }
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension _ExpenseModelRecurring on ExpenseModel {
  ExpenseModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? category,
    ExpenseType? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? nextOccurrence,
    DateTime? endDate,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: endDate ?? this.endDate,
    );
  }
}

class CategoryLocalDataSourceImpl {
  static const String _boxName = 'categories';
  late Box<String> _box;

  static const List<String> defaultCategories = [
    'food',
    'transportation',
    'entertainment',
    'shopping',
    'health',
    'education',
    'utilities',
    'rent',
    'insurance',
    'other',
  ];

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    if (_box.isEmpty) {
      for (final cat in defaultCategories) {
        await _box.add(cat);
      }
    }
  }

  List<String> getCategories() {
    return _box.values.toList();
  }

  Future<void> addCategory(String category) async {
    if (!_box.values.contains(category)) {
      await _box.add(category);
    }
  }

  Future<void> editCategory(String oldCategory, String newCategory) async {
    final key = _box.keys
        .firstWhere((k) => _box.get(k) == oldCategory, orElse: () => null);
    if (key != null && !_box.values.contains(newCategory)) {
      await _box.put(key, newCategory);
    }
  }

  Future<bool> deleteCategory(String category) async {
    if (!defaultCategories.contains(category)) {
      // Prevent deletion if category is in use
      final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
      final inUse = expenseBox.values.any((e) => e.category == category);
      if (inUse) {
        // Optionally, show a user-friendly error via UI (handled in dialog)
        return false;
      }
      final key = _box.keys
          .firstWhere((k) => _box.get(k) == category, orElse: () => null);
      if (key != null) {
        await _box.delete(key);
        return true;
      }
    }
    return false;
  }
}
