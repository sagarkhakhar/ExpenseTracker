import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/sync_expense.dart';
import 'sync_expense_local_data_source.dart';

/// Hive-based implementation of SyncExpenseLocalDataSource
/// Provides local storage operations for sync-enabled expense entities
class SyncExpenseLocalDataSourceImpl implements SyncExpenseLocalDataSource {
  static const String boxName = 'sync_expenses';
  
  late Box<SyncExpense> _box;

  @override
  Future<void> init() async {
    debugPrint('Initializing SyncExpenseLocalDataSourceImpl...');
    
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<SyncExpense>(boxName);
      debugPrint('Opened new Hive box: $boxName');
    } else {
      _box = Hive.box<SyncExpense>(boxName);
      debugPrint('Using existing Hive box: $boxName');
    }
  }

  @override
  Future<List<SyncExpense>> getAllSyncExpenses() async {
    try {
      final expenses = _box.values.where((expense) => !expense.isDeleted).toList();
      debugPrint('Retrieved ${expenses.length} active sync expenses from Hive');
      return expenses;
    } catch (e) {
      debugPrint('Error getting all sync expenses: $e');
      rethrow;
    }
  }

  @override
  Future<SyncExpense?> getSyncExpenseById(String id) async {
    try {
      final expense = _box.values
          .where((expense) => expense.id == id && !expense.isDeleted)
          .firstOrNull;
      debugPrint('Retrieved sync expense with ID $id: ${expense != null ? 'found' : 'not found'}');
      return expense;
    } catch (e) {
      debugPrint('Error getting sync expense by ID $id: $e');
      rethrow;
    }
  }

  @override
  Future<String> createSyncExpense(SyncExpense expense) async {
    try {
      await _box.add(expense);
      debugPrint('Created sync expense with ID ${expense.id}');
      return expense.id;
    } catch (e) {
      debugPrint('Error creating sync expense: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSyncExpense(SyncExpense expense) async {
    try {
      // Find the existing expense in the box
      final existingIndex = _box.values
          .toList()
          .indexWhere((e) => e.id == expense.id);

      if (existingIndex != -1) {
        await _box.putAt(existingIndex, expense);
        debugPrint('Updated sync expense with ID ${expense.id}');
      } else {
        // If not found, create new entry
        await _box.add(expense);
        debugPrint('Created new sync expense with ID ${expense.id} (update operation)');
      }
    } catch (e) {
      debugPrint('Error updating sync expense: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSyncExpense(String id) async {
    try {
      final existingIndex = _box.values
          .toList()
          .indexWhere((e) => e.id == id);

      if (existingIndex != -1) {
        final existing = _box.getAt(existingIndex)!;
        // Soft delete by marking as deleted
        final deletedExpense = existing.copyWith(
          isDeleted: true,
          updatedAt: DateTime.now().toUtc(),
          version: existing.version + 1,
        );
        await _box.putAt(existingIndex, deletedExpense);
        debugPrint('Soft deleted sync expense with ID $id');
      } else {
        debugPrint('Sync expense with ID $id not found for deletion');
      }
    } catch (e) {
      debugPrint('Error deleting sync expense: $e');
      rethrow;
    }
  }

  @override
  Future<List<SyncExpense>> getSyncExpensesModifiedSince(DateTime timestamp) async {
    try {
      final expenses = _box.values
          .where((expense) => expense.updatedAt.isAfter(timestamp))
          .toList();
      debugPrint('Retrieved ${expenses.length} sync expenses modified since $timestamp');
      return expenses;
    } catch (e) {
      debugPrint('Error getting sync expenses modified since $timestamp: $e');
      rethrow;
    }
  }

  @override
  Future<List<SyncExpense>> getDeletedSyncExpenses() async {
    try {
      final expenses = _box.values
          .where((expense) => expense.isDeleted)
          .toList();
      debugPrint('Retrieved ${expenses.length} deleted sync expenses');
      return expenses;
    } catch (e) {
      debugPrint('Error getting deleted sync expenses: $e');
      rethrow;
    }
  }

  @override
  Future<List<SyncExpense>> getSyncExpensesByVersion(int minVersion) async {
    try {
      final expenses = _box.values
          .where((expense) => expense.version >= minVersion)
          .toList();
      debugPrint('Retrieved ${expenses.length} sync expenses with version >= $minVersion');
      return expenses;
    } catch (e) {
      debugPrint('Error getting sync expenses by version: $e');
      rethrow;
    }
  }

  @override
  Future<void> bulkUpsertSyncExpenses(List<SyncExpense> expenses) async {
    try {
      for (final expense in expenses) {
        final existingIndex = _box.values
            .toList()
            .indexWhere((e) => e.id == expense.id);

        if (existingIndex != -1) {
          // Update existing
          await _box.putAt(existingIndex, expense);
        } else {
          // Insert new
          await _box.add(expense);
        }
      }
      debugPrint('Bulk upserted ${expenses.length} sync expenses');
    } catch (e) {
      debugPrint('Error bulk upserting sync expenses: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnsyncedChangeCount() async {
    try {
      // For now, consider all expenses as potentially unsynced
      // In a real implementation, you might track sync status separately
      final count = _box.values.length;
      debugPrint('Unsynced changes count: $count');
      return count;
    } catch (e) {
      debugPrint('Error getting unsynced change count: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllSyncExpenses() async {
    try {
      await _box.clear();
      debugPrint('Cleared all sync expenses from local storage');
    } catch (e) {
      debugPrint('Error clearing all sync expenses: $e');
      rethrow;
    }
  }

  @override
  Future<bool> syncExpenseExists(String id) async {
    try {
      final exists = _box.values
          .any((expense) => expense.id == id && !expense.isDeleted);
      debugPrint('Sync expense with ID $id exists: $exists');
      return exists;
    } catch (e) {
      debugPrint('Error checking if sync expense exists: $e');
      rethrow;
    }
  }
}