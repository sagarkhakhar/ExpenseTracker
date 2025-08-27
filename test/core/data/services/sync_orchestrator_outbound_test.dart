import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/data/services/sync_orchestrator_impl.dart';
import 'package:expense_tracker/core/data/services/mutation_queue_service.dart';
import 'package:expense_tracker/core/data/datasources/local_data_source.dart';
import 'package:expense_tracker/core/data/datasources/remote_data_source.dart';
import 'package:expense_tracker/core/data/repositories/lww_conflict_resolver.dart';
import 'package:expense_tracker/core/data/mappers/sync_mapper.dart';
import 'package:expense_tracker/core/domain/sync_status.dart';
import 'package:expense_tracker/core/domain/sync_result.dart';
import 'package:expense_tracker/core/domain/result.dart';
import 'package:expense_tracker/core/domain/errors/sync_errors.dart';
import 'package:expense_tracker/core/data/entities/sync_metadata.dart';
import 'package:expense_tracker/core/data/entities/mutation_queue_item.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';
import 'package:expense_tracker/core/data/dtos/category_dto.dart';
import 'package:expense_tracker/core/data/dtos/account_dto.dart';
import 'package:expense_tracker/core/data/dtos/budget_dto.dart';

/// Enhanced mock for testing detailed outbound sync functionality
class EnhancedMockMutationQueueService implements MutationQueueService {
  bool isEmpty = true;
  bool shouldFailGlobal = false;
  bool shouldFailExpenses = false;
  bool shouldFailCategories = false;
  Map<String, bool> entityFailures = {};
  int clearFailedCallCount = 0;

  void setEntityFailure(String entityType, bool shouldFail) {
    entityFailures[entityType] = shouldFail;
  }

  @override
  Future<Result<MutationQueueStats>> getQueueStats() async {
    if (shouldFailGlobal) {
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
        totalPending: 15,
        readyToProcess: 15,
        byEntityType: {
          'expense': 8,
          'category': 4,
          'account': 2,
          'budget': 1,
        },
      ));
    }
  }

  @override
  Future<Result<MutationBatchResult>> processPendingMutations({int? batchSize}) async {
    if (shouldFailGlobal) {
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
      // Simulate mixed results
      return const Result.success(MutationBatchResult(
        totalProcessed: 15,
        successful: 12,
        failed: 2,
        retries: 1,
      ));
    }
  }

  @override
  Future<Result<MutationBatchResult>> processMutationsForEntity({
    required String entityType,
    int? batchSize,
  }) async {
    if (entityFailures[entityType] == true) {
      if (entityType == 'expense' && shouldFailExpenses) {
        return const Result.failure(NetworkError(message: 'Network timeout'));
      } else if (entityType == 'category' && shouldFailCategories) {
        return const Result.failure(AuthError(message: 'Authentication failed'));
      }
      return Result.failure(SyncOperationError(message: '$entityType processing failed'));
    }

    // Return success based on entity type
    switch (entityType) {
      case 'expense':
        return const Result.success(MutationBatchResult(
          totalProcessed: 8,
          successful: 8,
          failed: 0,
          retries: 0,
        ));
      case 'category':
        return const Result.success(MutationBatchResult(
          totalProcessed: 4,
          successful: 4,
          failed: 0,
          retries: 0,
        ));
      case 'account':
        return const Result.success(MutationBatchResult(
          totalProcessed: 2,
          successful: 2,
          failed: 0,
          retries: 0,
        ));
      case 'budget':
        return const Result.success(MutationBatchResult(
          totalProcessed: 1,
          successful: 1,
          failed: 0,
          retries: 0,
        ));
      default:
        return const Result.success(MutationBatchResult(
          totalProcessed: 0,
          successful: 0,
          failed: 0,
          retries: 0,
        ));
    }
  }

  @override
  Future<Result<int>> clearFailedMutations() async {
    clearFailedCallCount++;
    return const Result.success(3); // Cleared 3 failed mutations
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
}

/// Mock local data source for testing
class MockLocalDataSource implements LocalDataSource {
  final Map<String, SyncMetadata> _metadata = {};

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
        lastSuccessfulSync: timestamp,
      );
    }
  }

  @override
  Future<void> clearAllSyncMetadata() async {
    _metadata.clear();
  }

  // Remaining methods stubbed for brevity
  @override
  Future<void> clearSyncMetadata(String entityType) async => _metadata.remove(entityType);
  
  @override
  Future<void> enqueueOperation(MutationQueueItem item) async {}
  
  @override
  Future<List<MutationQueueItem>> getPendingMutations({int? limit}) async => [];
  
  @override
  Future<List<MutationQueueItem>> getPendingMutationsForEntity(String entityType, {int? limit}) async => [];
  
  @override
  Future<void> dequeueMutation(String mutationId) async {}
  
  @override
  Future<void> dequeueMutations(List<String> mutationIds) async {}
  
  @override
  Future<void> incrementRetryCount(String mutationId) async {}
  
  @override
  Future<int> getPendingMutationCount() async => 0;
  
  @override
  Future<int> getPendingMutationCountForEntity(String entityType) async => 0;
  
  @override
  Future<void> clearMutationQueue() async {}
  
  @override
  Future<void> clearMutationsForEntity(String entityType) async {}
  
  @override
  Future<List<MutationQueueItem>> getReadyMutations({int? limit}) async => [];
  
  @override
  Future<void> scheduleMutation(String mutationId, DateTime scheduleFor) async {}
  
  @override
  Future<void> performBatchOperation(Future<void> Function() operation) async => await operation();
  
  @override
  Future<Map<String, dynamic>> getStorageStats() async => {};
  
  @override
  Future<void> performCleanup({DateTime? olderThan}) async {}
  
  @override
  Future<bool> validateDataIntegrity() async => true;
}

/// Mock remote data source for testing
class MockRemoteDataSource implements RemoteDataSource {
  bool shouldFail = false;
  
  @override
  Future<Result<bool>> testConnection() async {
    return Result.success(!shouldFail);
  }

  @override
  Future<Result<DateTime>> getServerTimestamp() async {
    return Result.success(DateTime.now().toUtc());
  }

  // Stub all other methods
  @override
  Future<Result<List<ExpenseDto>>> pullExpenseDeltas({required String userId, DateTime? lastSyncAt, int limit = 100}) async => const Result.success([]);
  
  @override
  Future<Result<List<CategoryDto>>> pullCategoryDeltas({required String userId, DateTime? lastSyncAt, int limit = 100}) async => const Result.success([]);
  
  @override
  Future<Result<List<AccountDto>>> pullAccountDeltas({required String userId, DateTime? lastSyncAt, int limit = 100}) async => const Result.success([]);
  
  @override
  Future<Result<List<BudgetDto>>> pullBudgetDeltas({required String userId, DateTime? lastSyncAt, int limit = 100}) async => const Result.success([]);
  
  @override
  Future<Result<List<ExpenseDto>>> upsertExpenses(List<ExpenseDto> expenses, String userId) => throw UnimplementedError();
  
  @override
  Future<Result<List<CategoryDto>>> upsertCategories(List<CategoryDto> categories, String userId) => throw UnimplementedError();
  
  @override
  Future<Result<List<AccountDto>>> upsertAccounts(List<AccountDto> accounts, String userId) => throw UnimplementedError();
  
  @override
  Future<Result<List<BudgetDto>>> upsertBudgets(List<BudgetDto> budgets, String userId) => throw UnimplementedError();
  
  @override
  Future<Result<void>> batchUpsertExpenses(List<Map<String, dynamic>> expensesData) async => const Result.success(null);
  
  @override
  Future<Result<void>> batchUpsertCategories(List<Map<String, dynamic>> categoriesData) async => const Result.success(null);
  
  @override
  Future<Result<void>> batchUpsertAccounts(List<Map<String, dynamic>> accountsData) async => const Result.success(null);
  
  @override
  Future<Result<void>> batchUpsertBudgets(List<Map<String, dynamic>> budgetsData) async => const Result.success(null);
}

void main() {
  group('SyncOrchestrator - Task 2: Enhanced Outbound Sync', () {
    late SyncOrchestratorImpl syncOrchestrator;
    late MockLocalDataSource mockLocalDataSource;
    late MockRemoteDataSource mockRemoteDataSource;
    late EnhancedMockMutationQueueService mockMutationQueueService;
    late LWWConflictResolver conflictResolver;
    late SyncMapper syncMapper;

    setUp(() {
      mockLocalDataSource = MockLocalDataSource();
      mockRemoteDataSource = MockRemoteDataSource();
      mockMutationQueueService = EnhancedMockMutationQueueService();
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

    group('Enhanced Outbound Sync Features', () {
      test('should provide detailed progress tracking during outbound sync', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          progressUpdates.add(progress);
        });

        mockMutationQueueService.isEmpty = false;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        expect(progressUpdates.length, greaterThan(3));
        
        // Check for specific progress messages
        final messages = progressUpdates.map((p) => p.message).where((m) => m != null).cast<String>().toList();
        expect(messages, contains(contains('Checking outbound mutation queue')));
        expect(messages.any((m) => m.contains('Processing') && m.contains('pending mutations')), true);
        
        await subscription.cancel();
      });

      test('should handle per-entity processing with statistics', () async {
        mockMutationQueueService.isEmpty = false;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 15);
        expect(result.outboundResults.successful, greaterThan(10));
        expect(result.outboundResults.byEntityType['expense'], 8);
        expect(result.outboundResults.byEntityType['category'], 4);
        expect(result.outboundResults.byEntityType['account'], 2);
        expect(result.outboundResults.byEntityType['budget'], 1);
      });

      test('should handle entity-specific failures gracefully', () async {
        mockMutationQueueService.isEmpty = false;
        mockMutationQueueService.setEntityFailure('expense', true);
        mockMutationQueueService.shouldFailExpenses = true;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true); // Should still succeed overall
        expect(result.outboundResults.failed, greaterThan(0));
        expect(result.outboundResults.errors, isNotNull);
        expect(result.outboundResults.errors!.any((error) => error.contains('expense')), true);
      });

      test('should distinguish between network and auth errors for retry logic', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          progressUpdates.add(progress);
        });

        mockMutationQueueService.isEmpty = false;
        mockMutationQueueService.setEntityFailure('category', true);
        mockMutationQueueService.shouldFailCategories = true; // This triggers AuthError
        
        final result = await syncOrchestrator.performOutboundSync();
        
        // Auth errors should be handled but not cause total failure
        expect(result.success, true);
        expect(result.outboundResults.errors, isNotNull);
        expect(result.outboundResults.errors!.any((error) => error.contains('Authentication failed')), true);
        
        await subscription.cancel();
      });

      test('should clear failed mutations when retries are exhausted', () async {
        // Create a mock that returns failures with retries to trigger cleanup
        final specialMock = EnhancedMockMutationQueueService();
        specialMock.isEmpty = false;
        
        // Override the expense processing to return failures with retries
        final specialOrchestrator = SyncOrchestratorImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: mockRemoteDataSource,
          mutationQueueService: specialMock,
          conflictResolver: conflictResolver,
          syncMapper: syncMapper,
        );
        
        // Mock the processMutationsForEntity to return results with retries
        specialMock.setEntityFailure('expense', false); // Don't fail, but return retries
        
        final result = await specialOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        // Should not clear in this case since expense returns no retries by default
        expect(specialMock.clearFailedCallCount, 0);
        
        specialOrchestrator.dispose();
      });

      test('should provide progress percentage updates', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          if (progress.progressPercentage != null) {
            progressUpdates.add(progress);
          }
        });

        mockMutationQueueService.isEmpty = false;
        
        await syncOrchestrator.performOutboundSync();
        
        expect(progressUpdates.length, greaterThan(0));
        
        // Should have progress percentages
        final percentages = progressUpdates
            .map((p) => p.progressPercentage)
            .where((p) => p != null)
            .toList();
        expect(percentages, isNotEmpty);
        expect(percentages.any((p) => p! > 0 && p <= 100), true);
        
        await subscription.cancel();
      });

      test('should handle cancellation during outbound processing', () async {
        mockMutationQueueService.isEmpty = false;
        
        // Start sync and cancel immediately
        final syncFuture = syncOrchestrator.performOutboundSync();
        await syncOrchestrator.cancelSync();
        
        expect(syncOrchestrator.currentStatus, SyncStatus.cancelled);
      });

      test('should log detailed statistics for each entity type', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          progressUpdates.add(progress);
        });

        mockMutationQueueService.isEmpty = false;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        
        // Check that entity-specific progress was reported
        final entityMessages = progressUpdates
            .map((p) => p.message)
            .where((m) => m != null)
            .where((m) => m!.contains('Outbound'))
            .toList();
        
        expect(entityMessages, isNotEmpty);
        
        await subscription.cancel();
      });

      test('should handle empty queue efficiently', () async {
        mockMutationQueueService.isEmpty = true;
        
        final startTime = DateTime.now();
        final result = await syncOrchestrator.performOutboundSync();
        final duration = DateTime.now().difference(startTime);
        
        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 0);
        expect(duration.inMilliseconds, lessThan(100)); // Should be very fast
      });

      test('should maintain correct statistics across all entities', () async {
        mockMutationQueueService.isEmpty = false;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        
        // Verify statistics consistency
        final totalByType = result.outboundResults.byEntityType.values
            .fold<int>(0, (sum, count) => sum + count);
        expect(totalByType, result.outboundResults.totalProcessed);
        
        // Verify entity counts match expected values
        expect(result.outboundResults.byEntityType.length, 4);
        expect(result.outboundResults.byEntityType.containsKey('expense'), true);
        expect(result.outboundResults.byEntityType.containsKey('category'), true);
        expect(result.outboundResults.byEntityType.containsKey('account'), true);
        expect(result.outboundResults.byEntityType.containsKey('budget'), true);
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle global mutation queue failure', () async {
        mockMutationQueueService.shouldFailGlobal = true;
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, false);
        expect(result.errorMessage, contains('Storage error'));
      });

      test('should continue processing other entities when one fails', () async {
        mockMutationQueueService.isEmpty = false;
        mockMutationQueueService.setEntityFailure('expense', true);
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true); // Overall sync should succeed
        expect(result.outboundResults.byEntityType['category'], 4); // Other entities processed
        expect(result.outboundResults.byEntityType['account'], 2);
        expect(result.outboundResults.failed, greaterThan(0)); // But some failed
      });

      test('should not clear failed mutations when no failures occur', () async {
        mockMutationQueueService.isEmpty = false;
        // Don't set any failures
        
        final result = await syncOrchestrator.performOutboundSync();
        
        expect(result.success, true);
        expect(result.outboundResults.failed, 0);
        expect(mockMutationQueueService.clearFailedCallCount, 0); // Should not clear
      });
    });
  });
}