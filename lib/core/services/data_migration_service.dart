import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../data/services/mutation_queue_service.dart';
import '../data/entities/mutation_queue_item.dart';
import '../providers/sync_providers.dart';
import '../domain/result.dart';
import '../domain/errors/sync_errors.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/budget/data/models/budget_model.dart';

/// Data migration service for handling existing local data when users first authenticate
/// 
/// In an offline-first architecture with RLS, local data doesn't have user context,
/// but when a user first authenticates, we need to ensure their existing local data
/// gets synced to Supabase with proper user association.
class DataMigrationService {
  final MutationQueueService _mutationQueueService;
  
  static const String _migrationVersionKey = 'migration_version';
  static const int _currentMigrationVersion = 1;
  
  const DataMigrationService({
    required MutationQueueService mutationQueueService,
  }) : _mutationQueueService = mutationQueueService;

  /// Check if migration is needed for the given user
  /// Migration is needed if:
  /// 1. There's local data present
  /// 2. No migration has been performed for this version
  Future<Result<bool>> needsMigration(String userId) async {
    try {
      // Check if migration already completed for this version
      final migrationBox = await Hive.openBox('migration_status');
      final lastMigrationVersion = migrationBox.get('${userId}_$_migrationVersionKey', defaultValue: 0) as int;
      
      if (lastMigrationVersion >= _currentMigrationVersion) {
        debugPrint('📦 Migration not needed - already at version $lastMigrationVersion');
        return const Result.success(false);
      }
      
      // Check if there's any local data to migrate
      final hasLocalData = await _hasLocalDataToMigrate();
      
      if (!hasLocalData) {
        // No data to migrate, mark migration as complete
        await _markMigrationComplete(userId);
        debugPrint('📦 Migration not needed - no local data found');
        return const Result.success(false);
      }
      
      debugPrint('📦 Migration needed for user $userId');
      return const Result.success(true);
      
    } catch (e) {
      return Result.failure(
        StorageError(message: 'Failed to check migration status: $e'),
      );
    }
  }

  /// Perform data migration for the given user
  /// This queues existing local data for sync to ensure it gets associated with the user
  Future<Result<DataMigrationResult>> performMigration(String userId) async {
    try {
      debugPrint('🔄 Starting data migration for user $userId');
      
      int totalItems = 0;
      int migratedItems = 0;
      final errors = <String>[];
      
      // Migrate expenses
      final expenseResult = await _migrateExpenses(userId);
      expenseResult.when(
        success: (count) {
          totalItems += count.total;
          migratedItems += count.migrated;
        },
        failure: (error) {
          errors.add('Expense migration failed: ${error.message}');
        },
      );
      
      // Migrate budgets
      final budgetResult = await _migrateBudgets(userId);
      budgetResult.when(
        success: (count) {
          totalItems += count.total;
          migratedItems += count.migrated;
        },
        failure: (error) {
          errors.add('Budget migration failed: ${error.message}');
        },
      );
      
      // Mark migration as complete
      await _markMigrationComplete(userId);
      
      final result = DataMigrationResult(
        userId: userId,
        totalItems: totalItems,
        migratedItems: migratedItems,
        errors: errors.isEmpty ? null : errors,
        completedAt: DateTime.now().toUtc(),
      );
      
      debugPrint('✅ Data migration completed: ${result.toString()}');
      
      return Result.success(result);
      
    } catch (e) {
      return Result.failure(
        SyncOperationError(message: 'Migration failed: $e'),
      );
    }
  }

  /// Check if there's any local data that needs migration
  Future<bool> _hasLocalDataToMigrate() async {
    try {
      // Check expenses
      if (Hive.isBoxOpen('expenses')) {
        final expenseBox = Hive.box<ExpenseModel>('expenses');
        if (expenseBox.isNotEmpty) {
          debugPrint('📦 Found ${expenseBox.length} expenses to migrate');
          return true;
        }
      }
      
      // Check budgets
      if (Hive.isBoxOpen('budgets')) {
        final budgetBox = Hive.box<BudgetModel>('budgets');
        if (budgetBox.isNotEmpty) {
          debugPrint('📦 Found ${budgetBox.length} budgets to migrate');
          return true;
        }
      }
      
      // Add other entity types as needed
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking local data: $e');
      return false;
    }
  }

  /// Migrate expenses by queuing them for sync
  Future<Result<MigrationCount>> _migrateExpenses(String userId) async {
    try {
      if (!Hive.isBoxOpen('expenses')) {
        return const Result.success(MigrationCount(total: 0, migrated: 0));
      }
      
      final expenseBox = Hive.box<ExpenseModel>('expenses');
      final expenses = expenseBox.values.toList();
      
      if (expenses.isEmpty) {
        return const Result.success(MigrationCount(total: 0, migrated: 0));
      }
      
      debugPrint('🔄 Migrating ${expenses.length} expenses for user $userId');
      
      int migrated = 0;
      for (final expense in expenses) {
        try {
          // Convert to mutation for sync queue
          final expenseJson = {
            'id': expense.id,
            'title': expense.title,
            'description': expense.description,
            'amount': expense.amount,
            'category': expense.category,
            'type': expense.type.name,
            'date': expense.date.toUtc().toIso8601String(),
            'created_at': expense.createdAt.toUtc().toIso8601String(),
            'updated_at': expense.updatedAt.toUtc().toIso8601String(),
            'metadata': expense.metadata,
            'is_recurring': expense.isRecurring,
            'recurring_frequency': expense.recurringFrequency,
            'next_occurrence': expense.nextOccurrence?.toUtc().toIso8601String(),
            'end_date': expense.endDate?.toUtc().toIso8601String(),
          };
          
          // Queue for sync - the sync system will associate with the authenticated user
          final result = await _mutationQueueService.enqueueOperation(
            entityType: 'expense',
            entityId: expense.id,
            operation: MutationType.update, // Use update since we're migrating existing data
            data: expenseJson,
          );
          
          result.when(
            success: (_) {
              migrated++;
            },
            failure: (error) {
              debugPrint('❌ Failed to queue expense ${expense.id} for migration: ${error.message}');
            },
          );
        } catch (e) {
          debugPrint('❌ Error migrating expense ${expense.id}: $e');
        }
      }
      
      debugPrint('✅ Queued $migrated/${expenses.length} expenses for migration');
      
      return Result.success(MigrationCount(
        total: expenses.length,
        migrated: migrated,
      ));
      
    } catch (e) {
      return Result.failure(
        SyncOperationError(message: 'Failed to migrate expenses: $e'),
      );
    }
  }

  /// Migrate budgets by queuing them for sync
  Future<Result<MigrationCount>> _migrateBudgets(String userId) async {
    try {
      if (!Hive.isBoxOpen('budgets')) {
        return const Result.success(MigrationCount(total: 0, migrated: 0));
      }
      
      final budgetBox = Hive.box<BudgetModel>('budgets');
      final budgets = budgetBox.values.toList();
      
      if (budgets.isEmpty) {
        return const Result.success(MigrationCount(total: 0, migrated: 0));
      }
      
      debugPrint('🔄 Migrating ${budgets.length} budgets for user $userId');
      
      int migrated = 0;
      for (final budget in budgets) {
        try {
          // Convert to mutation for sync queue
          final budgetJson = {
            'id': budget.id,
            'category_id': budget.categoryId,
            'amount': budget.amount,
            'spent_amount': budget.spentAmount,
            'period': budget.period,
            'alert_threshold': budget.alertThreshold,
            'is_active': budget.isActive,
            'created_at': budget.createdAt.toUtc().toIso8601String(),
            'updated_at': budget.updatedAt.toUtc().toIso8601String(),
            'start_date': budget.startDate.toUtc().toIso8601String(),
            'end_date': budget.endDate.toUtc().toIso8601String(),
          };
          
          // Queue for sync - the sync system will associate with the authenticated user
          final result = await _mutationQueueService.enqueueOperation(
            entityType: 'budget',
            entityId: budget.id,
            operation: MutationType.update, // Use update since we're migrating existing data
            data: budgetJson,
          );
          
          result.when(
            success: (_) {
              migrated++;
            },
            failure: (error) {
              debugPrint('❌ Failed to queue budget ${budget.id} for migration: ${error.message}');
            },
          );
        } catch (e) {
          debugPrint('❌ Error migrating budget ${budget.id}: $e');
        }
      }
      
      debugPrint('✅ Queued $migrated/${budgets.length} budgets for migration');
      
      return Result.success(MigrationCount(
        total: budgets.length,
        migrated: migrated,
      ));
      
    } catch (e) {
      return Result.failure(
        SyncOperationError(message: 'Failed to migrate budgets: $e'),
      );
    }
  }

  /// Mark migration as complete for the user
  Future<void> _markMigrationComplete(String userId) async {
    try {
      final migrationBox = await Hive.openBox('migration_status');
      await migrationBox.put('${userId}_$_migrationVersionKey', _currentMigrationVersion);
      await migrationBox.put('${userId}_completed_at', DateTime.now().toUtc().toIso8601String());
      debugPrint('✅ Migration marked as complete for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to mark migration complete: $e');
    }
  }
}

/// Result of data migration operation
class DataMigrationResult {
  final String userId;
  final int totalItems;
  final int migratedItems;
  final List<String>? errors;
  final DateTime completedAt;

  const DataMigrationResult({
    required this.userId,
    required this.totalItems,
    required this.migratedItems,
    this.errors,
    required this.completedAt,
  });

  bool get isSuccess => errors == null || errors!.isEmpty;
  
  @override
  String toString() {
    return 'DataMigrationResult{userId: $userId, totalItems: $totalItems, migratedItems: $migratedItems, errors: $errors, completedAt: $completedAt}';
  }
}

/// Count of items in a migration operation
class MigrationCount {
  final int total;
  final int migrated;

  const MigrationCount({
    required this.total,
    required this.migrated,
  });
}

/// Provider for data migration service
final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  final mutationQueueService = ref.read(mutationQueueServiceProvider);
  return DataMigrationService(mutationQueueService: mutationQueueService);
});