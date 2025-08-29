import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/data/services/sync_orchestrator_impl.dart';
import 'package:expense_tracker/core/data/services/mutation_queue_service.dart';
import 'package:expense_tracker/core/data/datasources/local_data_source.dart';
import 'package:expense_tracker/core/data/datasources/remote_data_source.dart';
import 'package:expense_tracker/core/data/repositories/lww_conflict_resolver.dart';
import 'package:expense_tracker/core/data/mappers/sync_mapper.dart';
import 'package:expense_tracker/core/domain/sync_status.dart';
import 'package:expense_tracker/core/domain/result.dart';
import 'package:expense_tracker/core/domain/errors/sync_errors.dart';
import 'package:expense_tracker/core/data/entities/sync_metadata.dart';
import 'package:expense_tracker/core/data/entities/mutation_queue_item.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';
import 'package:expense_tracker/core/data/dtos/category_dto.dart';
import 'package:expense_tracker/core/data/dtos/account_dto.dart';
import 'package:expense_tracker/core/data/dtos/budget_dto.dart';

/// Mock implementations for testing sync orchestrator
class MockLocalDataSource implements LocalDataSource {
  final Map<String, SyncMetadata> _metadata = {};
  final List<MutationQueueItem> _mutations = [];
  
  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<SyncMetadata?> getSyncMetadata(String entityType) async {
    return _metadata[entityType];
  }

  @override
  Future<void> setSyncMetadata(SyncMetadata metadata) async {
    _metadata[metadata.entityType] = metadata;
  }

  @override
  Future<void> updateLastPullCursor(String entityType, DateTime cursor) async {
    final existing = _metadata[entityType];
    if (existing != null) {
      _metadata[entityType] = existing.copyWith(lastPullCursor: cursor);
    } else {
      _metadata[entityType] = SyncMetadata(
        entityType: entityType,
        lastPullCursor: cursor,
        lastSuccessfulSync: null,
        syncVersion: 1,
      );
    }
  }

  @override
  Future<void> updateLastSuccessfulSync(String entityType, DateTime timestamp) async {
    final existing = _metadata[entityType];
    if (existing != null) {
      _metadata[entityType] = existing.copyWith(lastSuccessfulSync: timestamp);
    } else {
      _metadata[entityType] = SyncMetadata(
        entityType: entityType,
        lastPullCursor: null,
        lastSuccessfulSync: timestamp,
        syncVersion: 1,
      );
    }
  }

  @override
  Future<void> clearSyncMetadata(String entityType) async {
    _metadata.remove(entityType);
  }

  @override
  Future<void> clearAllSyncMetadata() async {
    _metadata.clear();
  }

  @override
  Future<void> enqueueOperation(MutationQueueItem item) async {
    _mutations.add(item);
  }

  @override
  Future<List<MutationQueueItem>> getPendingMutations({int? limit}) async {
    return limit != null ? _mutations.take(limit).toList() : _mutations;
  }

  @override
  Future<List<MutationQueueItem>> getPendingMutationsForEntity(String entityType, {int? limit}) async {
    final filtered = _mutations.where((m) => m.entityType == entityType).toList();
    return limit != null ? filtered.take(limit).toList() : filtered;
  }

  @override
  Future<void> dequeueMutation(String mutationId) async {
    _mutations.removeWhere((m) => m.id == mutationId);
  }

  @override
  Future<void> dequeueMutations(List<String> mutationIds) async {
    _mutations.removeWhere((m) => mutationIds.contains(m.id));
  }

  @override
  Future<void> incrementRetryCount(String mutationId) async {
    final index = _mutations.indexWhere((m) => m.id == mutationId);
    if (index >= 0) {
      _mutations[index] = _mutations[index].copyWith(
        retryCount: _mutations[index].retryCount + 1,
      );
    }
  }

  @override
  Future<int> getPendingMutationCount() async => _mutations.length;

  @override
  Future<int> getPendingMutationCountForEntity(String entityType) async {
    return _mutations.where((m) => m.entityType == entityType).length;
  }

  @override
  Future<void> clearMutationQueue() async {
    _mutations.clear();
  }

  @override
  Future<void> clearMutationsForEntity(String entityType) async {
    _mutations.removeWhere((m) => m.entityType == entityType);
  }

  @override
  Future<List<MutationQueueItem>> getReadyMutations({int? limit}) async {
    final now = DateTime.now().toUtc();
    final ready = _mutations.where((m) => 
      m.scheduledFor == null || m.scheduledFor!.isBefore(now)
    ).toList();
    return limit != null ? ready.take(limit).toList() : ready;
  }

  @override
  Future<void> scheduleMutation(String mutationId, DateTime scheduleFor) async {
    final index = _mutations.indexWhere((m) => m.id == mutationId);
    if (index >= 0) {
      _mutations[index] = _mutations[index].copyWith(scheduledFor: scheduleFor);
    }
  }

  @override
  Future<void> performBatchOperation(Future<void> Function() operation) async {
    await operation();
  }

  @override
  Future<Map<String, dynamic>> getStorageStats() async => {};

  @override
  Future<void> performCleanup({DateTime? olderThan}) async {}

  @override
  Future<bool> validateDataIntegrity() async => true;
}

class MockRemoteDataSource implements RemoteDataSource {
  bool shouldFail = false;
  
  @override
  Future<Result<List<ExpenseDto>>> pullExpenseDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    // Add delay to simulate real network operation timing for cancellation tests
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFail) {
      return const Result.failure(NetworkError(message: 'Network error'));
    }
    return const Result.success([]);
  }

  @override
  Future<Result<List<CategoryDto>>> pullCategoryDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFail) {
      return const Result.failure(NetworkError(message: 'Network error'));
    }
    return const Result.success([]);
  }

  @override
  Future<Result<List<AccountDto>>> pullAccountDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFail) {
      return const Result.failure(NetworkError(message: 'Network error'));
    }
    return const Result.success([]);
  }

  @override
  Future<Result<List<BudgetDto>>> pullBudgetDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFail) {
      return const Result.failure(NetworkError(message: 'Network error'));
    }
    return const Result.success([]);
  }

  @override
  Future<Result<bool>> testConnection() async {
    if (shouldFail) {
      return const Result.failure(NetworkError(message: 'No connection'));
    }
    return const Result.success(true);
  }

  @override
  Future<Result<DateTime>> getServerTimestamp() async {
    return Result.success(DateTime.now().toUtc());
  }

  // Unimplemented methods for brevity
  @override
  Future<Result<List<ExpenseDto>>> upsertExpenses(List<ExpenseDto> expenses, String userId) =>
    throw UnimplementedError();

  @override
  Future<Result<List<CategoryDto>>> upsertCategories(List<CategoryDto> categories, String userId) =>
    throw UnimplementedError();

  @override
  Future<Result<List<AccountDto>>> upsertAccounts(List<AccountDto> accounts, String userId) =>
    throw UnimplementedError();

  @override
  Future<Result<List<BudgetDto>>> upsertBudgets(List<BudgetDto> budgets, String userId) =>
    throw UnimplementedError();

  @override
  Future<Result<void>> batchUpsertExpenses(List<Map<String, dynamic>> expensesData) async =>
    const Result.success(null);

  @override
  Future<Result<void>> batchUpsertCategories(List<Map<String, dynamic>> categoriesData) async =>
    const Result.success(null);

  @override
  Future<Result<void>> batchUpsertAccounts(List<Map<String, dynamic>> accountsData) async =>
    const Result.success(null);

  @override
  Future<Result<void>> batchUpsertBudgets(List<Map<String, dynamic>> budgetsData) async =>
    const Result.success(null);
}

class MockMutationQueueService implements MutationQueueService {
  bool isEmpty = true;
  bool shouldFail = false;

  @override
  Future<Result<MutationQueueStats>> getQueueStats() async {
    // Add delay to simulate real operation timing for cancellation tests
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFail) {
      return const Result.failure(StorageError(message: 'Storage error'));
    }
    
    if (isEmpty) {
      return const Result.success(MutationQueueStats(
        totalPending: 0,
        readyToProcess: 0,
        byEntityType: {},
      ));
    } else {
      return const Result.success(MutationQueueStats(
        totalPending: 5,
        readyToProcess: 5,
        byEntityType: {'expense': 3, 'category': 2},
      ));
    }
  }

  @override
  Future<Result<MutationBatchResult>> processPendingMutations({int? batchSize}) async {
    if (shouldFail) {
      return const Result.failure(SyncOperationError(message: 'Processing failed'));
    }
    
    if (isEmpty) {
      return const Result.success(MutationBatchResult(
        totalProcessed: 0,
        successful: 0,
        failed: 0,
        retries: 0,
      ));
    } else {
      return const Result.success(MutationBatchResult(
        totalProcessed: 5,
        successful: 5,
        failed: 0,
        retries: 0,
      ));
    }
  }

  // Unimplemented methods for brevity
  @override
  Future<Result<void>> enqueueOperation({
    required String entityType,
    required String entityId,
    required MutationType operation,
    required Map<String, dynamic> data,
    int priority = 0,
    DateTime? scheduleFor,
  }) => throw UnimplementedError();

  @override
  Future<Result<MutationBatchResult>> processMutationsForEntity({
    required String entityType,
    int? batchSize,
  }) async {
    if (shouldFail) {
      return const Result.failure(SyncOperationError(message: 'Processing failed'));
    }
    
    if (isEmpty) {
      return const Result.success(MutationBatchResult(
        totalProcessed: 0,
        successful: 0,
        failed: 0,
        retries: 0,
      ));
    } else {
      // Return different counts based on entity type for testing
      final int entityCount = entityType == 'expense' ? 3 : 2;
      return Result.success(MutationBatchResult(
        totalProcessed: entityCount,
        successful: entityCount,
        failed: 0,
        retries: 0,
      ));
    }
  }

  @override
  Future<Result<int>> clearFailedMutations() async {
    if (shouldFail) {
      return const Result.failure(StorageError(message: 'Failed to clear mutations'));
    }
    return const Result.success(0);
  }
}

void main() {
  group('SyncOrchestratorImpl - Basic Tests', () {
    late SyncOrchestratorImpl syncOrchestrator;
    late MockLocalDataSource mockLocalDataSource;
    late MockRemoteDataSource mockRemoteDataSource;
    late MockMutationQueueService mockMutationQueueService;
    late LWWConflictResolver conflictResolver;
    late SyncMapper syncMapper;

    setUp(() {
      mockLocalDataSource = MockLocalDataSource();
      mockRemoteDataSource = MockRemoteDataSource();
      mockMutationQueueService = MockMutationQueueService();
      conflictResolver = LWWConflictResolver();
      syncMapper = SyncMapper();

      syncOrchestrator = SyncOrchestratorImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        mutationQueueService: mockMutationQueueService,
        conflictResolver: conflictResolver,
        syncMapper: syncMapper,
      );
    });

    tearDown(() {
      syncOrchestrator.dispose();
    });

    group('Initialization', () {
      test('should initialize with idle status', () {
        expect(syncOrchestrator.currentStatus, SyncStatus.idle);
        expect(syncOrchestrator.isSyncing, false);
        expect(syncOrchestrator.lastSyncResult, isNull);
      });

      test('should provide sync progress stream', () {
        expect(syncOrchestrator.syncProgress, isA<Stream<SyncProgress>>());
      });
    });

    group('Connectivity', () {
      test('should return true when connection succeeds', () async {
        mockRemoteDataSource.shouldFail = false;
        
        final result = await syncOrchestrator.testConnectivity();
        
        expect(result, true);
      });

      test('should return false when connection fails', () async {
        mockRemoteDataSource.shouldFail = true;
        
        final result = await syncOrchestrator.testConnectivity();
        
        expect(result, false);
      });
    });

    group('Outbound Sync', () {
      test('should complete successfully when no mutations pending', () async {
        mockMutationQueueService.isEmpty = true;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 0);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should process mutations when they exist', () async {
        mockMutationQueueService.isEmpty = false;
        mockMutationQueueService.shouldFail = false;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 5);
        expect(result.outboundResults.successful, 5);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should handle failure in outbound sync', () async {
        mockMutationQueueService.shouldFail = true;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, false);
        expect(result.errorMessage, contains('Storage error'));
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });
    });

    group('Inbound Sync', () {
      test('should complete successfully when no deltas available', () async {
        mockRemoteDataSource.shouldFail = false;
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(result.inboundResults.totalProcessed, 0);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should handle network failure in inbound sync', () async {
        mockRemoteDataSource.shouldFail = true;
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true); // Should continue with resilient behavior
        expect(result.inboundResults.failed, greaterThan(0)); // But record failures
        expect(result.inboundResults.errors, isNotNull);
        expect(result.inboundResults.errors!.any((error) => error.contains('Network error')), true);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });
    });

    group('Full Sync', () {
      test('should complete full sync successfully', () async {
        mockMutationQueueService.isEmpty = true;
        mockRemoteDataSource.shouldFail = false;
        
        final result = await syncOrchestrator.performFullSync();
        
        expect(result.success, true);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
        expect(syncOrchestrator.lastSyncResult, isNotNull);
      });

      test('should handle failure in full sync', () async {
        mockMutationQueueService.shouldFail = true;
        
        final result = await syncOrchestrator.performFullSync();
        
        expect(result.success, false);
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });
    });

    group('Sync Cancellation', () {
      test('should cancel sync operation', () async {
        // Start sync and cancel immediately
        final syncFuture = syncOrchestrator.performFullSync();
        await syncOrchestrator.cancelSync();
        
        // Check status immediately after cancellation request
        expect(syncOrchestrator.currentStatus, SyncStatus.cancelled);
        expect(syncOrchestrator.isSyncing, false);
        
        // Wait for sync to complete and check it returns a cancelled result
        final result = await syncFuture;
        expect(result.success, false);
        expect(result.errorMessage, contains('cancelled'));
      });
    });

    group('Status Updates', () {
      test('should emit status updates during sync', () async {
        final statusUpdates = <SyncStatus>[];
        
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          statusUpdates.add(progress.status);
        });

        mockMutationQueueService.isEmpty = true;
        mockRemoteDataSource.shouldFail = false;
        
        await syncOrchestrator.performFullSync();
        
        expect(statusUpdates, isNotEmpty);
        expect(statusUpdates, contains(SyncStatus.preparing));
        expect(statusUpdates, contains(SyncStatus.completed));
        
        await subscription.cancel();
      });
    });

    group('Resync', () {
      test('should perform full resync', () async {
        mockMutationQueueService.isEmpty = true;
        mockRemoteDataSource.shouldFail = false;
        
        final result = await syncOrchestrator.performFullResync();
        
        expect(result.success, true);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });
    });
  });
}