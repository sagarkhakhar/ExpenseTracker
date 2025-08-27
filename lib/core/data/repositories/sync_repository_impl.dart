import '../../domain/entities/sync_expense.dart';
import '../../domain/entities/sync_category.dart';
import '../../domain/entities/sync_account.dart';
import '../../domain/entities/sync_budget.dart';
import '../../domain/base_entity.dart';
import '../../domain/result.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../services/mutation_queue_service.dart';
import '../mappers/sync_mapper.dart';
import 'sync_repository.dart';

/// Implementation of SyncRepository with Last Write Wins conflict resolution
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.mutationQueueService,
    required this.syncMapper,
  });

  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final MutationQueueService mutationQueueService;
  final SyncMapper syncMapper;

  @override
  ConflictResolutionStrategy get conflictResolutionStrategy =>
      ConflictResolutionStrategy.lastWriteWins;

  // ==================== EXPENSE SYNC OPERATIONS ====================

  @override
  Future<List<SyncExpense>> pushExpenseChanges(List<SyncExpense> expenses) async {
    try {
      // Convert to DTOs
      final expenseDtos = expenses.map(SyncMapper.syncExpenseToDto).toList();
      
      // Push to remote with batch processing
      final result = await remoteDataSource.batchUpsertExpenses(expenseDtos);
      
      return result.when(
        success: (remoteDtos) {
          // Convert back to entities
          final remoteExpenses = remoteDtos.map(SyncMapper.dtoToSyncExpense).toList();
          
          // Update local entities with server metadata (version, updatedAt)
          _updateLocalWithServerMetadata(expenses, remoteExpenses);
          
          return remoteExpenses;
        },
        failure: (error) {
          throw Exception('Failed to push expense changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pushing expense changes: $e');
    }
  }

  @override
  Future<List<SyncExpense>> pullExpenseChanges({DateTime? lastSync}) async {
    try {
      // Get cursor from local metadata
      final metadata = await localDataSource.getSyncMetadata('expenses');
      final cursor = lastSync ?? metadata?.lastPullCursor;
      
      // Pull deltas from remote
      final result = await remoteDataSource.pullExpenseDeltas(cursor: cursor);
      
      return result.when(
        success: (remoteDtos) {
          // Convert to entities using correct mapper methods
          final remoteExpenses = remoteDtos.map(SyncMapper.dtoToSyncExpense).toList();
          
          // Apply conflict resolution for each remote entity
          return _mergeRemoteChanges<SyncExpense>(
            remoteExpenses,
            (id) async {
              // Use expense local data source to get by ID
              final localExpenseSource = localDataSource as dynamic;
              return await localExpenseSource.getExpenseById?.call(id);
            },
            (entity) async {
              // Use expense local data source to insert/update
              final localExpenseSource = localDataSource as dynamic;
              await localExpenseSource.insertOrUpdateExpense?.call(entity);
            },
          );
        },
        failure: (error) {
          throw Exception('Failed to pull expense changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pulling expense changes: $e');
    }
  }

  @override
  Future<SyncResult<SyncExpense>> syncExpenses({DateTime? lastSync}) async {
    final List<SyncConflict<SyncExpense>> conflicts = [];
    final List<SyncError> errors = [];
    List<SyncExpense> pushedToRemote = [];
    List<SyncExpense> pulledFromRemote = [];

    try {
      // Step 1: Push local changes
      try {
        final localChanges = await _getLocalChangesToPush<SyncExpense>(
          'expenses',
          lastSync,
        );
        
        if (localChanges.isNotEmpty) {
          pushedToRemote = await pushExpenseChanges(localChanges);
        }
      } catch (e) {
        errors.add(SyncError(
          entityId: null,
          entityType: 'SyncExpense',
          operation: SyncOperation.push,
          message: 'Failed to push changes: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }

      // Step 2: Pull remote changes
      try {
        pulledFromRemote = await pullExpenseChanges(lastSync: lastSync);
      } catch (e) {
        errors.add(SyncError(
          entityId: null,
          entityType: 'SyncExpense',
          operation: SyncOperation.pull,
          message: 'Failed to pull changes: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }

      // Step 3: Update sync cursor
      if (errors.isEmpty) {
        final now = DateTime.now().toUtc();
        await localDataSource.updateSyncCursor('expenses', now);
      }

      return SyncResult<SyncExpense>(
        pushedToRemote: pushedToRemote,
        pulledFromRemote: pulledFromRemote,
        conflicts: conflicts,
        errors: errors,
        syncTimestamp: DateTime.now().toUtc(),
      );
    } catch (e) {
      errors.add(SyncError(
        entityId: null,
        entityType: 'SyncExpense',
        operation: SyncOperation.validation,
        message: 'Sync operation failed: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));

      return SyncResult<SyncExpense>(
        pushedToRemote: pushedToRemote,
        pulledFromRemote: pulledFromRemote,
        conflicts: conflicts,
        errors: errors,
        syncTimestamp: DateTime.now().toUtc(),
      );
    }
  }

  // ==================== CATEGORY SYNC OPERATIONS ====================

  @override
  Future<List<SyncCategory>> pushCategoryChanges(List<SyncCategory> categories) async {
    try {
      final categoryDtos = categories.map(SyncMapper.syncCategoryToDto).toList();
      final result = await remoteDataSource.batchUpsertCategories(categoryDtos);
      
      return result.when(
        success: (remoteDtos) {
          final remoteCategories = remoteDtos.map(syncMapper.dtoToCategory).toList();
          _updateLocalWithServerMetadata(categories, remoteCategories);
          return remoteCategories;
        },
        failure: (error) {
          throw Exception('Failed to push category changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pushing category changes: $e');
    }
  }

  @override
  Future<List<SyncCategory>> pullCategoryChanges({DateTime? lastSync}) async {
    try {
      final metadata = await localDataSource.getSyncMetadata('categories');
      final cursor = lastSync ?? metadata?.lastSyncAt;
      
      final result = await remoteDataSource.pullCategoryDeltas(cursor: cursor);
      
      return result.when(
        success: (remoteDtos) {
          final remoteCategories = remoteDtos.map(syncMapper.dtoToCategory).toList();
          return _mergeRemoteChanges<SyncCategory>(
            remoteCategories,
            (id) => localDataSource.getCategoryById(id),
            (entity) => localDataSource.insertOrUpdateCategory(entity),
          );
        },
        failure: (error) {
          throw Exception('Failed to pull category changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pulling category changes: $e');
    }
  }

  @override
  Future<SyncResult<SyncCategory>> syncCategories({DateTime? lastSync}) async {
    return _performEntitySync<SyncCategory>(
      entityType: 'categories',
      lastSync: lastSync,
      getLocalChanges: () => _getLocalChangesToPush<SyncCategory>('categories', lastSync),
      pushChanges: pushCategoryChanges,
      pullChanges: () => pullCategoryChanges(lastSync: lastSync),
    );
  }

  // ==================== ACCOUNT SYNC OPERATIONS ====================

  @override
  Future<List<SyncAccount>> pushAccountChanges(List<SyncAccount> accounts) async {
    try {
      final accountDtos = accounts.map(syncMapper.accountToDto).toList();
      final result = await remoteDataSource.batchUpsertAccounts(accountDtos);
      
      return result.when(
        success: (remoteDtos) {
          final remoteAccounts = remoteDtos.map(syncMapper.dtoToAccount).toList();
          _updateLocalWithServerMetadata(accounts, remoteAccounts);
          return remoteAccounts;
        },
        failure: (error) {
          throw Exception('Failed to push account changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pushing account changes: $e');
    }
  }

  @override
  Future<List<SyncAccount>> pullAccountChanges({DateTime? lastSync}) async {
    try {
      final metadata = await localDataSource.getSyncMetadata('accounts');
      final cursor = lastSync ?? metadata?.lastSyncAt;
      
      final result = await remoteDataSource.pullAccountDeltas(cursor: cursor);
      
      return result.when(
        success: (remoteDtos) {
          final remoteAccounts = remoteDtos.map(syncMapper.dtoToAccount).toList();
          return _mergeRemoteChanges<SyncAccount>(
            remoteAccounts,
            (id) => localDataSource.getAccountById(id),
            (entity) => localDataSource.insertOrUpdateAccount(entity),
          );
        },
        failure: (error) {
          throw Exception('Failed to pull account changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pulling account changes: $e');
    }
  }

  @override
  Future<SyncResult<SyncAccount>> syncAccounts({DateTime? lastSync}) async {
    return _performEntitySync<SyncAccount>(
      entityType: 'accounts',
      lastSync: lastSync,
      getLocalChanges: () => _getLocalChangesToPush<SyncAccount>('accounts', lastSync),
      pushChanges: pushAccountChanges,
      pullChanges: () => pullAccountChanges(lastSync: lastSync),
    );
  }

  // ==================== BUDGET SYNC OPERATIONS ====================

  @override
  Future<List<SyncBudget>> pushBudgetChanges(List<SyncBudget> budgets) async {
    try {
      final budgetDtos = budgets.map(syncMapper.budgetToDto).toList();
      final result = await remoteDataSource.batchUpsertBudgets(budgetDtos);
      
      return result.when(
        success: (remoteDtos) {
          final remoteBudgets = remoteDtos.map(syncMapper.dtoToBudget).toList();
          _updateLocalWithServerMetadata(budgets, remoteBudgets);
          return remoteBudgets;
        },
        failure: (error) {
          throw Exception('Failed to push budget changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pushing budget changes: $e');
    }
  }

  @override
  Future<List<SyncBudget>> pullBudgetChanges({DateTime? lastSync}) async {
    try {
      final metadata = await localDataSource.getSyncMetadata('budgets');
      final cursor = lastSync ?? metadata?.lastSyncAt;
      
      final result = await remoteDataSource.pullBudgetDeltas(cursor: cursor);
      
      return result.when(
        success: (remoteDtos) {
          final remoteBudgets = remoteDtos.map(syncMapper.dtoToBudget).toList();
          return _mergeRemoteChanges<SyncBudget>(
            remoteBudgets,
            (id) => localDataSource.getBudgetById(id),
            (entity) => localDataSource.insertOrUpdateBudget(entity),
          );
        },
        failure: (error) {
          throw Exception('Failed to pull budget changes: $error');
        },
      );
    } catch (e) {
      throw Exception('Error pulling budget changes: $e');
    }
  }

  @override
  Future<SyncResult<SyncBudget>> syncBudgets({DateTime? lastSync}) async {
    return _performEntitySync<SyncBudget>(
      entityType: 'budgets',
      lastSync: lastSync,
      getLocalChanges: () => _getLocalChangesToPush<SyncBudget>('budgets', lastSync),
      pushChanges: pushBudgetChanges,
      pullChanges: () => pullBudgetChanges(lastSync: lastSync),
    );
  }

  // ==================== FULL SYNC OPERATIONS ====================

  @override
  Future<FullSyncResult> performFullSync({DateTime? lastSync}) async {
    final syncTimestamp = DateTime.now().toUtc();
    
    // Perform sync for all entity types concurrently
    final results = await Future.wait([
      syncExpenses(lastSync: lastSync),
      syncCategories(lastSync: lastSync),
      syncAccounts(lastSync: lastSync),
      syncBudgets(lastSync: lastSync),
    ]);

    return FullSyncResult(
      expenseResult: results[0] as SyncResult<SyncExpense>,
      categoryResult: results[1] as SyncResult<SyncCategory>,
      accountResult: results[2] as SyncResult<SyncAccount>,
      budgetResult: results[3] as SyncResult<SyncBudget>,
      syncTimestamp: syncTimestamp,
    );
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    final metadata = await localDataSource.getSyncMetadata('_global');
    return metadata?.lastSyncAt;
  }

  @override
  Future<void> updateLastSyncTimestamp(DateTime timestamp) async {
    await localDataSource.updateSyncCursor('_global', timestamp);
  }

  // ==================== CONFLICT RESOLUTION ====================

  @override
  Future<T> resolveConflict<T>(T local, T remote) async {
    if (local is! BaseEntity || remote is! BaseEntity) {
      throw ArgumentError('Conflict resolution only supported for BaseEntity types');
    }

    // Last Write Wins (LWW) by version and updatedAt
    // Server wins ties (remote entity used when timestamps equal)
    final BaseEntity localEntity = local as BaseEntity;
    final BaseEntity remoteEntity = remote as BaseEntity;

    if (remoteEntity.isNewerThan(localEntity)) {
      return remote;
    } else if (localEntity.version == remoteEntity.version && 
               localEntity.updatedAt == remoteEntity.updatedAt) {
      // Exact tie - server wins
      return remote;
    } else {
      return local;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Generic method to perform sync for any entity type
  Future<SyncResult<T>> _performEntitySync<T extends BaseEntity>({
    required String entityType,
    required DateTime? lastSync,
    required Future<List<T>> Function() getLocalChanges,
    required Future<List<T>> Function(List<T>) pushChanges,
    required Future<List<T>> Function() pullChanges,
  }) async {
    final List<SyncConflict<T>> conflicts = [];
    final List<SyncError> errors = [];
    List<T> pushedToRemote = [];
    List<T> pulledFromRemote = [];

    try {
      // Step 1: Push local changes
      try {
        final localChanges = await getLocalChanges();
        if (localChanges.isNotEmpty) {
          pushedToRemote = await pushChanges(localChanges);
        }
      } catch (e) {
        errors.add(SyncError(
          entityId: null,
          entityType: T.toString(),
          operation: SyncOperation.push,
          message: 'Failed to push changes: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }

      // Step 2: Pull remote changes
      try {
        pulledFromRemote = await pullChanges();
      } catch (e) {
        errors.add(SyncError(
          entityId: null,
          entityType: T.toString(),
          operation: SyncOperation.pull,
          message: 'Failed to pull changes: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }

      // Step 3: Update sync cursor if successful
      if (errors.isEmpty) {
        final now = DateTime.now().toUtc();
        await localDataSource.updateSyncCursor(entityType, now);
      }

      return SyncResult<T>(
        pushedToRemote: pushedToRemote,
        pulledFromRemote: pulledFromRemote,
        conflicts: conflicts,
        errors: errors,
        syncTimestamp: DateTime.now().toUtc(),
      );
    } catch (e) {
      errors.add(SyncError(
        entityId: null,
        entityType: T.toString(),
        operation: SyncOperation.validation,
        message: 'Sync operation failed: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));

      return SyncResult<T>(
        pushedToRemote: pushedToRemote,
        pulledFromRemote: pulledFromRemote,
        conflicts: conflicts,
        errors: errors,
        syncTimestamp: DateTime.now().toUtc(),
      );
    }
  }

  /// Get local changes that need to be pushed to remote
  Future<List<T>> _getLocalChangesToPush<T extends BaseEntity>(
    String entityType,
    DateTime? lastSync,
  ) async {
    // Get pending mutations from queue
    final queueItems = await localDataSource.getPendingMutations();
    final relevantMutations = queueItems
        .where((item) => item.entityType == entityType)
        .toList();

    // Convert mutation items to entities based on type
    final List<T> changes = [];
    for (final mutation in relevantMutations) {
      try {
        switch (entityType) {
          case 'expenses':
            final expense = await localDataSource.getExpenseById(mutation.entityId);
            if (expense != null) changes.add(expense as T);
            break;
          case 'categories':
            final category = await localDataSource.getCategoryById(mutation.entityId);
            if (category != null) changes.add(category as T);
            break;
          case 'accounts':
            final account = await localDataSource.getAccountById(mutation.entityId);
            if (account != null) changes.add(account as T);
            break;
          case 'budgets':
            final budget = await localDataSource.getBudgetById(mutation.entityId);
            if (budget != null) changes.add(budget as T);
            break;
        }
      } catch (e) {
        // Log error but continue processing other mutations
        print('Error loading entity ${mutation.entityId}: $e');
      }
    }

    return changes;
  }

  /// Merge remote changes with local entities using LWW conflict resolution
  Future<List<T>> _mergeRemoteChanges<T extends BaseEntity>(
    List<T> remoteEntities,
    Future<T?> Function(String id) getLocalEntity,
    Future<void> Function(T entity) saveLocalEntity,
  ) async {
    final List<T> mergedEntities = [];

    for (final remoteEntity in remoteEntities) {
      try {
        final localEntity = await getLocalEntity(remoteEntity.id);
        
        T finalEntity;
        if (localEntity == null) {
          // No local entity - use remote
          finalEntity = remoteEntity;
        } else {
          // Resolve conflict using LWW
          finalEntity = await resolveConflict<T>(localEntity, remoteEntity);
        }

        // Handle tombstones (deleted entities)
        if (finalEntity.isTombstone) {
          // For tombstones, we still save them to mark as deleted
          // The local data source should handle tombstone cleanup
          await saveLocalEntity(finalEntity);
        } else {
          // Normal entity - save to local store
          await saveLocalEntity(finalEntity);
        }

        mergedEntities.add(finalEntity);
      } catch (e) {
        print('Error merging entity ${remoteEntity.id}: $e');
      }
    }

    return mergedEntities;
  }

  /// Update local entities with server-generated metadata after push
  void _updateLocalWithServerMetadata<T extends BaseEntity>(
    List<T> localEntities,
    List<T> serverEntities,
  ) {
    // Create a map for efficient lookup
    final serverMap = <String, T>{
      for (final entity in serverEntities) entity.id: entity
    };

    // Update local entities with server metadata
    for (final localEntity in localEntities) {
      final serverEntity = serverMap[localEntity.id];
      if (serverEntity != null) {
        // Server version should have updated version and timestamp
        // This will be handled by the local data source when it saves the entity
        // The push operation should return entities with server metadata
      }
    }
  }
}