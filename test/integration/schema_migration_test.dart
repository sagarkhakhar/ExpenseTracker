// Integration test for the future-proof schema migration
// Validates that legacy data works with new foreign key relationships

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/data/models/enhanced_expense_model.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('Schema Migration Integration Tests', () {
    late List<Map<String, dynamic>> sampleExpenseData;

    setUpAll(() async {
      // Load the sample data file
      final file = File('docs/expenses_rows.json');
      if (!await file.exists()) {
        throw Exception('Sample data file not found: docs/expenses_rows.json');
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      // The JSON file has a nested array structure [[{...}]]
      final innerData = jsonData.first as List<dynamic>;
      sampleExpenseData = innerData.cast<Map<String, dynamic>>();
    });

    test('should load legacy expense data successfully', () {
      expect(sampleExpenseData, isNotEmpty);
      expect(sampleExpenseData.length, equals(70)); // Based on the JSON file
      
      // Check first expense has expected fields
      final firstExpense = sampleExpenseData.first;
      expect(firstExpense['id'], isNotNull);
      expect(firstExpense['title'], isNotNull);
      expect(firstExpense['amount'], isNotNull);
      expect(firstExpense['category'], isNotNull);
      expect(firstExpense['type'], isNotNull);
    });

    test('should convert legacy data to enhanced model', () {
      for (final expenseData in sampleExpenseData.take(5)) {
        final enhancedModel = EnhancedExpenseModel.fromLegacyJson(expenseData);
        
        // Verify core fields are preserved
        expect(enhancedModel.id, equals(expenseData['id']));
        expect(enhancedModel.title, equals(expenseData['title']));
        expect(enhancedModel.amount, equals(expenseData['amount']));
        expect(enhancedModel.category, equals(expenseData['category']));
        
        // Verify foreign key fields are null (as expected in legacy data)
        expect(enhancedModel.categoryId, isNull);
        expect(enhancedModel.accountId, isNull);
        expect(enhancedModel.receiptPhotoId, isNull);
        expect(enhancedModel.deviceId, isNull);
        
        // Verify conversion to domain entity works
        final expense = enhancedModel.toEntity();
        expect(expense.id, equals(expenseData['id']));
        expect(expense.title, equals(expenseData['title']));
        expect(expense.amount, equals(double.parse(expenseData['amount'] as String)));
      }
    });

    test('should identify all unique categories in sample data', () {
      final categories = <String>{};
      for (final expense in sampleExpenseData) {
        final category = expense['category'] as String?;
        if (category != null) {
          categories.add(category);
        }
      }
      
      // Verify we found the expected categories
      expect(categories, contains('food'));
      expect(categories, contains('transport'));
      expect(categories, contains('entertainment'));
      expect(categories, contains('salary'));
      expect(categories, contains('investments'));
      
      // Check for problematic categories
      expect(categories, contains('категория')); // Cyrillic
      expect(categories, contains('Food')); // Capital F
      
      print('Found ${categories.length} unique categories:');
      for (final category in categories.toList()..sort()) {
        print('  - $category');
      }
    });

    test('should handle income vs expense types correctly', () {
      final incomeExpenses = sampleExpenseData.where(
        (expense) => expense['type'] == 'income'
      ).toList();
      
      final regularExpenses = sampleExpenseData.where(
        (expense) => expense['type'] == 'expense'
      ).toList();
      
      expect(incomeExpenses, isNotEmpty);
      expect(regularExpenses, isNotEmpty);
      
      // Test a few income records
      for (final incomeData in incomeExpenses.take(3)) {
        final model = EnhancedExpenseModel.fromLegacyJson(incomeData);
        expect(model.type, equals(ExpenseType.income));
        
        final entity = model.toEntity();
        expect(entity.type, equals(ExpenseType.income));
      }
    });

    test('should handle special characters and edge cases', () {
      // Find expenses with special characteristics
      final emojiExpense = sampleExpenseData.firstWhere(
        (expense) => expense['title'].toString().contains('🛒'),
        orElse: () => <String, dynamic>{},
      );
      
      final longTitleExpense = sampleExpenseData.firstWhere(
        (expense) => expense['title'].toString().length > 50,
        orElse: () => <String, dynamic>{},
      );
      
      final emptyDescExpense = sampleExpenseData.firstWhere(
        (expense) => expense['description'] == '',
        orElse: () => <String, dynamic>{},
      );
      
      // Test emoji handling
      if (emojiExpense.isNotEmpty) {
        final model = EnhancedExpenseModel.fromLegacyJson(emojiExpense);
        expect(model.title, contains('🛒'));
        expect(model.toEntity().title, contains('🛒'));
      }
      
      // Test long titles
      if (longTitleExpense.isNotEmpty) {
        final model = EnhancedExpenseModel.fromLegacyJson(longTitleExpense);
        expect(model.title.length, greaterThan(50));
        expect(model.toEntity().title.length, greaterThan(50));
      }
      
      // Test empty descriptions
      if (emptyDescExpense.isNotEmpty) {
        final model = EnhancedExpenseModel.fromLegacyJson(emptyDescExpense);
        expect(model.description, equals(''));
        expect(model.toEntity().description, equals(''));
      }
    });

    test('should simulate foreign key population', () {
      // Simulate what the migration script would do
      final mockCategories = [
        Category(
          id: 'cat-1',
          name: 'food',
          displayName: 'Food & Dining',
          isIncomeCategory: false,
          isActive: true,
          sortOrder: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Category(
          id: 'cat-2',
          name: 'transport',
          displayName: 'Transportation',
          isIncomeCategory: false,
          isActive: true,
          sortOrder: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      final mockAccounts = [
        Account(
          id: 'acc-1',
          userId: '8964bb00-5ec5-4c19-9a5e-19f3a877becd',
          name: 'Cash Account',
          accountType: AccountType.cash,
          currency: 'USD',
          initialBalance: 0,
          currentBalance: 1000,
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      // Take a sample expense and enhance it with foreign keys
      final sampleExpense = sampleExpenseData.first;
      final legacyModel = EnhancedExpenseModel.fromLegacyJson(sampleExpense);
      
      // Find matching category
      final matchingCategory = mockCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == legacyModel.category?.toLowerCase(),
        orElse: () => mockCategories.first, // Default fallback
      );
      
      // Find matching account (assume first account for this user)
      final matchingAccount = mockAccounts.first;
      
      // Create enhanced model with foreign keys
      final enhancedModel = legacyModel.copyWith(
        categoryId: matchingCategory.id,
        accountId: matchingAccount.id,
        categoryObject: matchingCategory,
        accountObject: matchingAccount,
      );
      
      // Verify the enhanced model
      expect(enhancedModel.categoryId, equals(matchingCategory.id));
      expect(enhancedModel.accountId, equals(matchingAccount.id));
      expect(enhancedModel.effectiveCategoryName, equals(matchingCategory.name));
      expect(enhancedModel.effectiveCategoryDisplayName, equals(matchingCategory.displayName));
      expect(enhancedModel.effectiveAccountName, equals(matchingAccount.name));
      
      // Verify conversion to entity still works
      final entity = enhancedModel.toEntity();
      expect(entity.category, equals(matchingCategory.name));
    });

    test('should batch convert all legacy data', () {
      // Convert all sample data to enhanced models
      final enhancedModels = EnhancedExpenseModel.fromLegacyList(sampleExpenseData);
      
      expect(enhancedModels.length, equals(sampleExpenseData.length));
      
      // Verify each conversion
      for (int i = 0; i < enhancedModels.length; i++) {
        final model = enhancedModels[i];
        final original = sampleExpenseData[i];
        
        expect(model.id, equals(original['id']));
        expect(model.title, equals(original['title']));
        expect(model.amount, equals(original['amount']));
        
        // All should have null foreign keys (legacy data)
        expect(model.categoryId, isNull);
        expect(model.accountId, isNull);
        expect(model.receiptPhotoId, isNull);
        expect(model.deviceId, isNull);
      }
    });
  });
}