import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/core/data/datasources/sync_expense_local_data_source_impl.dart';
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('SyncExpenseLocalDataSourceImpl', () {
    late SyncExpenseLocalDataSourceImpl dataSource;
    late SyncExpense sampleSyncExpense1;
    late SyncExpense sampleSyncExpense2;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Register adapters if they exist
      if (!Hive.isAdapterRegistered(20)) {
        // Adapter registration would normally be done in main.dart
        // For testing, we'll assume the adapters are already registered
      }
    });

    setUp(() async {
      dataSource = SyncExpenseLocalDataSourceImpl();
      
      sampleSyncExpense1 = SyncExpense.create(
        title: 'Test Expense 1',
        description: 'Test Description 1',
        amount: 25.99,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
        deviceId: 'device1',
        lastEditor: 'user1',
        accountId: 'account1',
        categoryId: 'category1',
      );

      sampleSyncExpense2 = SyncExpense.create(
        title: 'Test Expense 2',
        description: 'Test Description 2',
        amount: 35.50,
        category: 'Shopping',
        type: ExpenseType.expense,
        date: DateTime(2024, 2, 20),
        deviceId: 'device2',
        lastEditor: 'user2',
        accountId: 'account2',
        categoryId: 'category2',
      );

      await dataSource.init();
      
      // Clear any existing data
      await dataSource.clearAllSyncExpenses();
    });

    tearDown(() async {
      await dataSource.clearAllSyncExpenses();
      // Close the box if it's still open
      if (Hive.isBoxOpen('sync_expenses')) {
        await Hive.box('sync_expenses').close();
      }
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newDataSource = SyncExpenseLocalDataSourceImpl();
        expect(() => newDataSource.init(), returnsNormally);
      });

      test('should handle multiple initializations gracefully', () async {
        await dataSource.init();
        expect(() => dataSource.init(), returnsNormally);
      });
    });

    group('Create Operations', () {
      test('should create sync expense successfully', () async {
        final id = await dataSource.createSyncExpense(sampleSyncExpense1);
        
        expect(id, equals(sampleSyncExpense1.id));
        
        final retrieved = await dataSource.getSyncExpenseById(id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(sampleSyncExpense1.id));
        expect(retrieved.title, equals(sampleSyncExpense1.title));
        expect(retrieved.amount, equals(sampleSyncExpense1.amount));
      });

      test('should create multiple sync expenses successfully', () async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.createSyncExpense(sampleSyncExpense2);
        
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(2));
        
        final ids = allExpenses.map((e) => e.id).toList();
        expect(ids, contains(sampleSyncExpense1.id));
        expect(ids, contains(sampleSyncExpense2.id));
      });
    });

    group('Read Operations', () {
      setUp(() async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.createSyncExpense(sampleSyncExpense2);
      });

      test('should get all sync expenses', () async {
        final expenses = await dataSource.getAllSyncExpenses();
        
        expect(expenses.length, equals(2));
        expect(expenses.any((e) => e.id == sampleSyncExpense1.id), isTrue);
        expect(expenses.any((e) => e.id == sampleSyncExpense2.id), isTrue);
      });

      test('should get sync expense by ID', () async {
        final expense = await dataSource.getSyncExpenseById(sampleSyncExpense1.id);
        
        expect(expense, isNotNull);
        expect(expense!.id, equals(sampleSyncExpense1.id));
        expect(expense.title, equals(sampleSyncExpense1.title));
        expect(expense.description, equals(sampleSyncExpense1.description));
      });

      test('should return null for non-existent ID', () async {
        final expense = await dataSource.getSyncExpenseById('non-existent-id');
        expect(expense, isNull);
      });

      test('should check if sync expense exists', () async {
        final exists1 = await dataSource.syncExpenseExists(sampleSyncExpense1.id);
        final exists2 = await dataSource.syncExpenseExists('non-existent-id');
        
        expect(exists1, isTrue);
        expect(exists2, isFalse);
      });
    });

    group('Update Operations', () {
      setUp(() async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
      });

      test('should update existing sync expense', () async {
        final updatedExpense = sampleSyncExpense1.copyWith(
          title: 'Updated Title',
          amount: 99.99,
          version: 2,
        );

        await dataSource.updateSyncExpense(updatedExpense);
        
        final retrieved = await dataSource.getSyncExpenseById(sampleSyncExpense1.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Updated Title'));
        expect(retrieved.amount, equals(99.99));
        expect(retrieved.version, equals(2));
      });

      test('should create new expense if ID not found during update', () async {
        final newExpense = SyncExpense.create(
          title: 'New Expense',
          description: 'New Description',
          amount: 75.00,
          category: 'Travel',
          type: ExpenseType.expense,
          date: DateTime(2024, 3, 1),
          deviceId: 'device3',
          lastEditor: 'user3',
        );

        await dataSource.updateSyncExpense(newExpense);
        
        final retrieved = await dataSource.getSyncExpenseById(newExpense.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('New Expense'));
      });
    });

    group('Delete Operations', () {
      setUp(() async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.createSyncExpense(sampleSyncExpense2);
      });

      test('should soft delete sync expense', () async {
        await dataSource.deleteSyncExpense(sampleSyncExpense1.id);
        
        // Should not appear in regular queries
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(1));
        expect(allExpenses.first.id, equals(sampleSyncExpense2.id));
        
        // Should appear in deleted queries
        final deletedExpenses = await dataSource.getDeletedSyncExpenses();
        expect(deletedExpenses.length, equals(1));
        expect(deletedExpenses.first.id, equals(sampleSyncExpense1.id));
        expect(deletedExpenses.first.isDeleted, isTrue);
      });

      test('should handle deletion of non-existent expense gracefully', () async {
        expect(() => dataSource.deleteSyncExpense('non-existent-id'), returnsNormally);
      });
    });

    group('Sync Query Operations', () {
      late DateTime referenceTime;
      late SyncExpense olderExpense;
      late SyncExpense newerExpense;

      setUp(() async {
        referenceTime = DateTime.now().subtract(Duration(hours: 1));
        
        olderExpense = sampleSyncExpense1.copyWith(
          updatedAt: referenceTime.subtract(Duration(minutes: 30)),
        );
        
        newerExpense = sampleSyncExpense2.copyWith(
          updatedAt: referenceTime.add(Duration(minutes: 30)),
        );

        await dataSource.createSyncExpense(olderExpense);
        await dataSource.createSyncExpense(newerExpense);
      });

      test('should get expenses modified since timestamp', () async {
        final modifiedExpenses = await dataSource.getSyncExpensesModifiedSince(referenceTime);
        
        expect(modifiedExpenses.length, equals(1));
        expect(modifiedExpenses.first.id, equals(newerExpense.id));
      });

      test('should get expenses by version', () async {
        final versionedExpense = olderExpense.copyWith(version: 5);
        await dataSource.updateSyncExpense(versionedExpense);
        
        final highVersionExpenses = await dataSource.getSyncExpensesByVersion(3);
        
        expect(highVersionExpenses.length, equals(1));
        expect(highVersionExpenses.first.id, equals(olderExpense.id));
        expect(highVersionExpenses.first.version, equals(5));
      });

      test('should get deleted sync expenses', () async {
        await dataSource.deleteSyncExpense(olderExpense.id);
        
        final deletedExpenses = await dataSource.getDeletedSyncExpenses();
        
        expect(deletedExpenses.length, equals(1));
        expect(deletedExpenses.first.id, equals(olderExpense.id));
        expect(deletedExpenses.first.isDeleted, isTrue);
      });
    });

    group('Bulk Operations', () {
      test('should bulk upsert sync expenses', () async {
        final expenses = [sampleSyncExpense1, sampleSyncExpense2];
        
        await dataSource.bulkUpsertSyncExpenses(expenses);
        
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(2));
      });

      test('should handle bulk upsert with updates and inserts', () async {
        // First, create one expense
        await dataSource.createSyncExpense(sampleSyncExpense1);
        
        // Create updated version and new expense
        final updatedExpense1 = sampleSyncExpense1.copyWith(
          title: 'Bulk Updated',
          version: 3,
        );
        
        final expenses = [updatedExpense1, sampleSyncExpense2];
        await dataSource.bulkUpsertSyncExpenses(expenses);
        
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(2));
        
        final retrievedExpense1 = await dataSource.getSyncExpenseById(sampleSyncExpense1.id);
        expect(retrievedExpense1!.title, equals('Bulk Updated'));
        expect(retrievedExpense1.version, equals(3));
      });

      test('should get unsynced change count', () async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.createSyncExpense(sampleSyncExpense2);
        
        final count = await dataSource.getUnsyncedChangeCount();
        expect(count, equals(2));
      });

      test('should clear all sync expenses', () async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.createSyncExpense(sampleSyncExpense2);
        
        await dataSource.clearAllSyncExpenses();
        
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(0));
      });
    });

    group('Error Handling', () {
      test('should handle operations after clearing gracefully', () async {
        await dataSource.createSyncExpense(sampleSyncExpense1);
        await dataSource.clearAllSyncExpenses();
        
        final expense = await dataSource.getSyncExpenseById(sampleSyncExpense1.id);
        expect(expense, isNull);
        
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(0));
      });

      test('should handle empty state operations gracefully', () async {
        final allExpenses = await dataSource.getAllSyncExpenses();
        expect(allExpenses.length, equals(0));
        
        final deletedExpenses = await dataSource.getDeletedSyncExpenses();
        expect(deletedExpenses.length, equals(0));
        
        final modifiedExpenses = await dataSource.getSyncExpensesModifiedSince(DateTime.now());
        expect(modifiedExpenses.length, equals(0));
        
        final count = await dataSource.getUnsyncedChangeCount();
        expect(count, equals(0));
      });
    });
  });
}