// This file implements the ExpenseLocalDataSource interface using Hive for local storage.
// It is responsible for all low-level data access and persistence.

import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

import '../models/expense_model.dart';
import '../../domain/entities/expense.dart';
import 'expense_local_data_source.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

/// Concrete implementation of ExpenseLocalDataSource using Hive.
class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  // The Hive box name for storing expenses.
  static const String boxName = 'expenses';

  // The Hive box instance (opened in init).
  late Box<ExpenseModel> _box;

  /// Initialize the data source by opening the Hive box.
  @override
  Future<void> init() async {
    debugPrint('Initializing ExpenseLocalDataSourceImpl...');
    // Use a more efficient box opening strategy
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<ExpenseModel>(boxName);
      debugPrint('Opened new Hive box: $boxName');
    } else {
      _box = Hive.box<ExpenseModel>(boxName);
      debugPrint('Using existing Hive box: $boxName');
    }

    debugPrint('Box contains ${_box.length} items');

    // Seed minimal data if empty
    await seedComprehensiveDummyDataIfEmpty();
    debugPrint('After seeding: Box contains ${_box.length} items');
  }

  /// Get all expenses and income records from local storage.
  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    // Reverted to direct access for stability
    return _box.values.toList();
  }

  /// Get a single expense by its unique ID.
  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    // Use firstWhereOrNull from collection package for null safety
    return _box.values.firstWhereOrNull((e) => e.id == id);
  }

  /// Get all expenses/income in a date range (inclusive).
  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    // Reverted to direct access for stability
    return _box.values
        .where((e) =>
            e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Get all expenses/income for a specific category.
  @override
  Future<List<ExpenseModel>> getExpensesByCategory(String category) async {
    // Reverted to direct access for stability
    return _box.values.where((e) => e.category == category).toList();
  }

  /// Get all expenses/income of a specific type (expense or income).
  @override
  Future<List<ExpenseModel>> getExpensesByType(ExpenseType type) async {
    // Reverted to direct access for stability
    return _box.values.where((e) => e.type == type).toList();
  }

  /// Create a new expense or income record in local storage.
  @override
  Future<void> createExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  /// Update an existing expense or income record in local storage.
  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  /// Delete an expense or income record by ID from local storage.
  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clearAllExpenses() async {
    await _box.clear();
  }

  /// Seed comprehensive dummy data for thorough widget testing
  Future<void> seedComprehensiveDummyDataIfEmpty() async {
    // Force reseed for testing - clear existing data first
    if (_box.isNotEmpty) {
      debugPrint('Clearing existing expense data for fresh seeding...');
      await _box.clear();
    }

    debugPrint('Seeding comprehensive dummy data for widget testing...');
    final now = DateTime.now();
    final List<ExpenseModel> dummyExpenses = [];

    // Helper function to capitalize first letter
    String capitalize(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }

    // Helper function to add expense with validation
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
      bool isRecurring = false,
      String? recurringFrequency,
      DateTime? nextOccurrence,
      DateTime? endDate,
      Map<String, dynamic>? metadata,
    }) {
      try {
        final expense = ExpenseModel(
          id: id,
          title: title,
          description: description,
          amount: amount,
          category: category,
          type: type,
          date: date,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isRecurring: isRecurring,
          recurringFrequency: recurringFrequency,
          nextOccurrence: nextOccurrence,
          endDate: endDate,
          metadata: metadata,
        );
        dummyExpenses.add(expense);
      } catch (e) {
        debugPrint('Failed to create expense $id: $e');
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

    // 1. REGULAR EXPENSES - All categories with realistic data
    for (final cat in allCategories) {
      // Regular expenses
      addIfValid(
        id: (id++).toString(),
        title: '${capitalize(cat)} Expense',
        description: 'Regular $cat expense for testing',
        amount: 25.0 + (id % 100),
        category: cat,
        type: ExpenseType.expense,
        date: now.subtract(Duration(days: id % 30)),
        createdAt: now.subtract(Duration(days: id % 30)),
        updatedAt: now.subtract(Duration(days: id % 30)),
      );

      // Income entries
      if (['salary', 'investments', 'gifts'].contains(cat)) {
        addIfValid(
          id: (id++).toString(),
          title: '${capitalize(cat)} Income',
          description: 'Income from $cat',
          amount: 500.0 + (id % 1000),
          category: cat,
          type: ExpenseType.income,
          date: now.subtract(Duration(days: id % 30)),
          createdAt: now.subtract(Duration(days: id % 30)),
          updatedAt: now.subtract(Duration(days: id % 30)),
        );
      }
    }

    // 2. RECURRING EXPENSES - Various frequencies
    final recurringCategories = ['bills', 'subscriptions', 'rent', 'insurance'];
    for (final cat in recurringCategories) {
      addIfValid(
        id: (id++).toString(),
        title: 'Monthly ${capitalize(cat)}',
        description: 'Recurring monthly $cat payment',
        amount: 100.0 + (id % 200),
        category: cat,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 15)),
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: now.add(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 365)),
      );

      addIfValid(
        id: (id++).toString(),
        title: 'Weekly ${capitalize(cat)}',
        description: 'Recurring weekly $cat payment',
        amount: 25.0 + (id % 50),
        category: cat,
        type: ExpenseType.expense,
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 7)),
        isRecurring: true,
        recurringFrequency: 'weekly',
        nextOccurrence: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 365)),
      );
    }

    // 3. EDGE CASES - Amount ranges
    addIfValid(
      id: (id++).toString(),
      title: 'Micro Transaction',
      description: 'Very small amount test',
      amount: 0.01,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Large Purchase',
      description: 'High value transaction',
      amount: 9999.99,
      category: 'technology',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 5)),
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Million Dollar Deal',
      description: 'Extreme amount test',
      amount: 1000000.00,
      category: 'investments',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 10)),
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
    );

    // 4. DATE EDGE CASES - Various time periods
    addIfValid(
      id: (id++).toString(),
      title: 'Future Expense',
      description: 'Expense scheduled for future',
      amount: 150.00,
      category: 'travel',
      type: ExpenseType.expense,
      date: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Historical Expense',
      description: 'Very old expense',
      amount: 50.00,
      category: 'education',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 365)),
      createdAt: now.subtract(const Duration(days: 365)),
      updatedAt: now.subtract(const Duration(days: 365)),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Today\'s Expense',
      description: 'Expense from today',
      amount: 75.00,
      category: 'food',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    // 5. SPECIAL CHARACTERS AND EMOJIS
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

    addIfValid(
      id: (id++).toString(),
      title: 'Travel ✈️🌍',
      description: 'Flight tickets to Paris 🇫🇷',
      amount: 1200.00,
      category: 'travel',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Gym Membership 💪',
      description: 'Monthly fitness subscription',
      amount: 89.99,
      category: 'health',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 7)),
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    );

    // 6. LONG TEXT EDGE CASES
    addIfValid(
      id: (id++).toString(),
      title:
          'Very Long Title That Should Test UI Layout and Text Wrapping Capabilities in the Expense List Widget',
      description:
          'This is a very long description that should test how the UI handles long text content. It includes multiple sentences and should wrap properly in the expense detail view. The description should be long enough to test text overflow handling and ensure the UI remains responsive and readable.',
      amount: 123.45,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    // 7. DUPLICATE DATES - Multiple expenses on same day
    final sameDate = now.subtract(const Duration(days: 2));
    for (int i = 1; i <= 5; i++) {
      addIfValid(
        id: (id++).toString(),
        title: 'Same Day Expense $i',
        description: 'Multiple expenses on same day - test $i',
        amount: 10.0 * i,
        category: 'food',
        type: ExpenseType.expense,
        date: sameDate,
        createdAt: sameDate,
        updatedAt: sameDate,
      );
    }

    // 8. CATEGORY EDGE CASES
    addIfValid(
      id: (id++).toString(),
      title: 'Case Sensitive Category',
      description: 'Testing category case sensitivity',
      amount: 25.00,
      category: 'Food', // Capital F
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Non-ASCII Category',
      description: 'Testing non-ASCII characters',
      amount: 30.00,
      category: 'категория',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    // 9. METADATA TESTING
    addIfValid(
      id: (id++).toString(),
      title: 'Expense with Metadata',
      description: 'Testing metadata functionality',
      amount: 45.00,
      category: 'shopping',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
      metadata: {
        'store': 'Walmart',
        'payment_method': 'credit_card',
        'receipt_number': 'RCPT-12345',
        'notes': 'Bought household items',
        'tags': ['essential', 'monthly'],
      },
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Income with Metadata',
      description: 'Testing income metadata',
      amount: 2500.00,
      category: 'salary',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      metadata: {
        'employer': 'Tech Corp',
        'payment_method': 'direct_deposit',
        'tax_deductible': false,
        'bonus': true,
      },
    );

    // 10. WHITESPACE AND EMPTY EDGE CASES
    addIfValid(
      id: (id++).toString(),
      title: '   Whitespace Title   ',
      description: '   Whitespace description   ',
      amount: 15.00,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Empty Description',
      description: '',
      amount: 20.00,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    // 11. DECIMAL PRECISION TESTING
    addIfValid(
      id: (id++).toString(),
      title: 'Precise Amount',
      description: 'Testing decimal precision',
      amount: 123.456789,
      category: 'other',
      type: ExpenseType.expense,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    // 12. SEASONAL AND HOLIDAY EXPENSES
    addIfValid(
      id: (id++).toString(),
      title: 'Christmas Shopping',
      description: 'Holiday gifts and decorations',
      amount: 500.00,
      category: 'gifts',
      type: ExpenseType.expense,
      date: DateTime(now.year, 12, 25),
      createdAt: DateTime(now.year, 12, 25),
      updatedAt: DateTime(now.year, 12, 25),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Valentine\'s Day',
      description: 'Romantic dinner and gifts',
      amount: 150.00,
      category: 'entertainment',
      type: ExpenseType.expense,
      date: DateTime(now.year, 2, 14),
      createdAt: DateTime(now.year, 2, 14),
      updatedAt: DateTime(now.year, 2, 14),
    );

    // 13. BUSINESS EXPENSES
    addIfValid(
      id: (id++).toString(),
      title: 'Business Lunch',
      description: 'Client meeting expense',
      amount: 85.00,
      category: 'food',
      type: ExpenseType.expense,
      date: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      metadata: {
        'business_expense': true,
        'client': 'ABC Corp',
        'tax_deductible': true,
      },
    );

    // 14. FREQUENT EXPENSES (for testing filtering)
    for (int i = 1; i <= 10; i++) {
      addIfValid(
        id: (id++).toString(),
        title: 'Daily Coffee $i',
        description: 'Morning coffee run',
        amount: 4.50,
        category: 'food',
        type: ExpenseType.expense,
        date: now.subtract(Duration(days: i)),
        createdAt: now.subtract(Duration(days: i)),
        updatedAt: now.subtract(Duration(days: i)),
      );
    }

    // 15. INCOME VARIETY
    addIfValid(
      id: (id++).toString(),
      title: 'Freelance Payment',
      description: 'Web development project',
      amount: 800.00,
      category: 'salary',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Investment Dividend',
      description: 'Quarterly stock dividend',
      amount: 250.00,
      category: 'investments',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 7)),
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    );

    addIfValid(
      id: (id++).toString(),
      title: 'Birthday Gift',
      description: 'Cash gift from family',
      amount: 100.00,
      category: 'gifts',
      type: ExpenseType.income,
      date: now.subtract(const Duration(days: 5)),
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    // Batch insert all valid expenses
    final validExpenses = dummyExpenses
        .where((expense) =>
            expense.amount.isFinite &&
            expense.amount > 0 &&
            expense.title.trim().isNotEmpty &&
            expense.category.trim().isNotEmpty)
        .toList();

    debugPrint('Adding ${validExpenses.length} dummy expenses...');

    // Use batch operation for efficiency
    final batch = <String, ExpenseModel>{};
    for (final expense in validExpenses) {
      batch[expense.id] = expense;
    }

    await _box.putAll(batch);
    debugPrint('Successfully added ${batch.length} dummy expenses');
  }

  /// Seed minimal dummy data if empty (legacy method)
  Future<void> seedMinimalDummyDataIfEmpty() async {
    await seedComprehensiveDummyDataIfEmpty();
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
      if (amount.isNaN ||
          amount.isInfinite ||
          amount <= 0 ||
          amount > 1000000) {
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
    // Use a more efficient box opening strategy
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }

    if (_box.isEmpty) {
      // Batch add categories for better performance
      final batch = <String>[];
      for (final cat in defaultCategories) {
        batch.add(cat);
      }
      await _box.addAll(batch);
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
