import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';
import 'package:expense_tracker/core/data/mappers/sync_mapper.dart';
import 'package:expense_tracker/core/domain/base_entity.dart';

// Access EntityUtils from the base_entity.dart file

void main() {
  group('CRUD Operations Test', () {
    test('should create and manipulate SyncExpense entities', () {
      // Test 1: Create a new expense
      final expense = SyncExpense.create(
        title: 'Test Expense',
        description: 'Test Description',
        amount: 100.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'test-device',
        lastEditor: 'test-user',
      );

      expect(expense.title, 'Test Expense');
      expect(expense.amount, 100.0);
      expect(expense.category, 'Food');
      expect(expense.version, 1);
      expect(expense.isDeleted, false);
      print('✅ Create operation successful');
    });

    test('should update expense and increment version', () {
      // Test 2: Update an existing expense
      final expense = SyncExpense.create(
        title: 'Original Title',
        description: 'Original Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'test-device',
        lastEditor: 'test-user',
      );

      final updatedExpense = expense.copyWith(
        title: 'Updated Title',
        amount: 75.0,
        version: expense.version + 1,
      );

      expect(updatedExpense.title, 'Updated Title');
      expect(updatedExpense.amount, 75.0);
      expect(updatedExpense.version, 2);
      expect(updatedExpense.id, expense.id); // ID should remain the same
      print('✅ Update operation successful');
    });

    test('should delete expense using tombstone', () {
      // Test 3: Delete an expense (soft delete)
      final expense = SyncExpense.create(
        title: 'To Be Deleted',
        description: 'Will be deleted',
        amount: 25.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'test-device',
        lastEditor: 'test-user',
      );

      final deletedExpense = expense.toTombstone(
        deviceId: 'test-device',
        lastEditor: 'test-user',
      );

      expect(deletedExpense.isDeleted, true);
      expect(deletedExpense.version, expense.version + 1);
      expect(deletedExpense.lastEditor, 'test-user');
      print('✅ Delete operation successful');
    });

    test('should convert between legacy Expense and SyncExpense', () {
      // Test 4: Legacy <-> Sync conversion
      final legacyExpense = Expense(
        id: 'legacy-id',
        title: 'Legacy Expense',
        description: 'Legacy Description',
        amount: 200.0,
        category: 'Transport',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final syncExpense = SyncMapper.expenseToSync(
        legacyExpense,
        deviceId: 'test-device',
        lastEditor: 'test-user',
      );

      expect(syncExpense.title, legacyExpense.title);
      expect(syncExpense.amount, legacyExpense.amount);
      expect(syncExpense.category, legacyExpense.category);

      final convertedBack = SyncMapper.syncToExpense(syncExpense);
      expect(convertedBack.title, legacyExpense.title);
      expect(convertedBack.amount, legacyExpense.amount);
      print('✅ Legacy conversion operations successful');
    });

    test('should generate valid UUIDs and metadata', () {
      // Test 5: Utility functions
      final id1 = EntityUtils.generateId();
      final id2 = EntityUtils.generateId();
      
      expect(id1, isNot(equals(id2)));
      expect(id1.length, greaterThan(30)); // UUID should be reasonably long
      
      final timestamp = EntityUtils.now();
      expect(timestamp, isNotNull);
      
      print('✅ Utility functions working');
    });
  });
}