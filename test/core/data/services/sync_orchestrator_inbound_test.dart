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
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';

/// Enhanced mock for testing detailed inbound sync functionality
class EnhancedMockRemoteDataSource implements RemoteDataSource {
  bool shouldFail = false;
  bool shouldFailExpenses = false;
  bool shouldFailCategories = false;
  Map<String, bool> entityFailures = {};
  Map<String, List<dynamic>> mockDeltas = {};

  void setEntityFailure(String entityType, bool shouldFail) {
    entityFailures[entityType] = shouldFail;
  }

  void setMockDeltas(String entityType, List<dynamic> deltas) {
    mockDeltas[entityType] = deltas;
  }

  @override
  Future<Result<bool>> testConnection() async {
    return Result.success(!shouldFail);
  }

  @override
  Future<Result<DateTime>> getServerTimestamp() async {
    return Result.success(DateTime.now().toUtc());
  }

  @override
  Future<Result<List<ExpenseDto>>> pullExpenseDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    if (entityFailures['expense'] == true || shouldFailExpenses) {
      return Result.failure(NetworkError(message: 'Network error pulling expenses'));
    }

    final deltas = mockDeltas['expense']?.cast<ExpenseDto>() ?? <ExpenseDto>[];
    return Result.success(deltas);
  }

  @override
  Future<Result<List<CategoryDto>>> pullCategoryDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    if (entityFailures['category'] == true || shouldFailCategories) {
      return Result.failure(AuthError(message: 'Auth error pulling categories'));
    }

    final deltas = mockDeltas['category']?.cast<CategoryDto>() ?? <CategoryDto>[];
    return Result.success(deltas);
  }

  @override
  Future<Result<List<AccountDto>>> pullAccountDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    if (entityFailures['account'] == true) {
      return Result.failure(SyncOperationError(message: 'Sync error pulling accounts'));
    }

    final deltas = mockDeltas['account']?.cast<AccountDto>() ?? <AccountDto>[];
    return Result.success(deltas);
  }

  @override
  Future<Result<List<BudgetDto>>> pullBudgetDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    if (entityFailures['budget'] == true) {
      return Result.failure(ValidationError(message: 'Validation error pulling budgets'));
    }

    final deltas = mockDeltas['budget']?.cast<BudgetDto>() ?? <BudgetDto>[];
    return Result.success(deltas);
  }

  // Unimplemented methods for brevity
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

/// Mock mutation queue service for inbound testing
class MockMutationQueueService implements MutationQueueService {
  @override
  Future<Result<MutationQueueStats>> getQueueStats() async {
    return const Result.success(MutationQueueStats(
      totalPending: 0,
      readyToProcess: 0,
      byEntityType: {},
    ));
  }

  @override
  Future<Result<MutationBatchResult>> processPendingMutations({int? batchSize}) async {
    return const Result.success(MutationBatchResult(
      totalProcessed: 0,
      successful: 0,
      failed: 0,
      retries: 0,
    ));
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
  }) => throw UnimplementedError();

  @override
  Future<Result<int>> clearFailedMutations() => throw UnimplementedError();
}

/// Mock local data source for inbound testing
class EnhancedMockLocalDataSource implements LocalDataSource {
  final Map<String, SyncMetadata> _metadata = {};
  final Map<String, Map<String, dynamic>> _entities = {}; // entityType -> id -> entity
  int cursorUpdateCount = 0;

  void addMockEntity(String entityType, String id, dynamic entity) {
    _entities.putIfAbsent(entityType, () => {})[id] = entity;
  }

  dynamic getMockEntity(String entityType, String id) {
    return _entities[entityType]?[id];
  }

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
    cursorUpdateCount++;
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

void main() {
  group('SyncOrchestrator - Task 3: Enhanced Inbound Sync', () {
    late SyncOrchestratorImpl syncOrchestrator;
    late EnhancedMockLocalDataSource mockLocalDataSource;
    late EnhancedMockRemoteDataSource mockRemoteDataSource;
    late MockMutationQueueService mockMutationQueueService;
    late LWWConflictResolver conflictResolver;
    late SyncMapper syncMapper;

    setUp(() {
      mockLocalDataSource = EnhancedMockLocalDataSource();
      mockRemoteDataSource = EnhancedMockRemoteDataSource();
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

    group('Enhanced Inbound Sync Features', () {
      test('should provide detailed progress tracking during inbound sync', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          progressUpdates.add(progress);
        });

        // Setup mock deltas
        mockRemoteDataSource.setMockDeltas('expense', []);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(progressUpdates.length, greaterThan(5));
        
        // Check for specific progress messages
        final messages = progressUpdates.map((p) => p.message).where((m) => m != null).cast<String>().toList();
        expect(messages.any((m) => m.contains('Starting inbound delta sync')), true);
        expect(messages.any((m) => m.contains('Processing') && m.contains('deltas')), true);
        
        await subscription.cancel();
      });

      test('should handle per-entity processing with detailed statistics', () async {
        // Create mock expense DTOs
        final expenseDto1 = ExpenseDto(
          id: 'expense1',
          title: 'Test Expense 1',
          amount: 10.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        );

        final expenseDto2 = ExpenseDto(
          id: 'expense2',
          title: 'Test Expense 2',
          amount: 20.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'transport',
        );

        mockRemoteDataSource.setMockDeltas('expense', [expenseDto1, expenseDto2]);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(result.inboundResults.totalProcessed, 2);
        expect(result.inboundResults.successful, 2);
        expect(result.inboundResults.byEntityType['expense'], 2);
        expect(result.inboundResults.byEntityType['category'], 0);
      });

      test('should handle entity-specific failures gracefully', () async {
        mockRemoteDataSource.setEntityFailure('expense', true);
        mockRemoteDataSource.shouldFailExpenses = true;
        
        // Set other entities to succeed
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true); // Should still succeed overall
        expect(result.inboundResults.failed, greaterThan(0));
        expect(result.inboundResults.errors, isNotNull);
        expect(result.inboundResults.errors!.any((error) => error.contains('expense')), true);
      });

      test('should distinguish between different error types', () async {
        mockRemoteDataSource.setEntityFailure('category', true);
        mockRemoteDataSource.shouldFailCategories = true; // This triggers AuthError
        
        // Set other entities to succeed
        mockRemoteDataSource.setMockDeltas('expense', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(result.inboundResults.errors, isNotNull);
        expect(result.inboundResults.errors!.any((error) => error.contains('Auth error')), true);
      });

      test('should update sync cursors after successful processing', () async {
        final now = DateTime.now().toUtc();
        final expenseDto = ExpenseDto(
          id: 'expense1',
          title: 'Test Expense',
          amount: 10.0,
          date: now,
          createdAt: now,
          updatedAt: now,
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        );

        mockRemoteDataSource.setMockDeltas('expense', [expenseDto]);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(mockLocalDataSource.cursorUpdateCount, greaterThan(0));
      });

      test('should handle large datasets with batch processing', () async {
        // Create 150 mock expense DTOs to test batch processing (batch size is 50)
        final expenseDtos = List.generate(150, (index) => ExpenseDto(
          id: 'expense$index',
          title: 'Test Expense $index',
          amount: 10.0 + index,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().add(Duration(seconds: index)),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        ));

        mockRemoteDataSource.setMockDeltas('expense', expenseDtos);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        expect(result.inboundResults.totalProcessed, 150);
        expect(result.inboundResults.successful, 150);
      });

      test('should provide batch progress updates for large datasets', () async {
        final progressUpdates = <SyncProgress>[];
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          if (progress.progressPercentage != null) {
            progressUpdates.add(progress);
          }
        });

        // Create 100 mock expense DTOs
        final expenseDtos = List.generate(100, (index) => ExpenseDto(
          id: 'expense$index',
          title: 'Test Expense $index',
          amount: 10.0 + index,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        ));

        mockRemoteDataSource.setMockDeltas('expense', expenseDtos);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        await syncOrchestrator.performInboundSync();
        
        // Should have progress updates with percentages
        expect(progressUpdates.length, greaterThan(0));
        final percentages = progressUpdates
            .map((p) => p.progressPercentage)
            .where((p) => p != null)
            .toList();
        expect(percentages, isNotEmpty);
        
        await subscription.cancel();
      });

      test('should handle cancellation during inbound processing', () async {
        mockRemoteDataSource.setMockDeltas('expense', []);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        // Start sync and cancel immediately
        final syncFuture = syncOrchestrator.performInboundSync();
        await syncOrchestrator.cancelSync();
        
        expect(syncOrchestrator.currentStatus, SyncStatus.cancelled);
      });

      test('should handle empty delta responses efficiently', () async {
        mockRemoteDataSource.setMockDeltas('expense', []);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);

        final startTime = DateTime.now();
        final result = await syncOrchestrator.performInboundSync();
        final duration = DateTime.now().difference(startTime);
        
        expect(result.success, true);
        expect(result.inboundResults.totalProcessed, 0);
        expect(duration.inMilliseconds, lessThan(1000)); // Should be very fast
      });

      test('should maintain correct statistics across all entities', () async {
        final expenseDto = ExpenseDto(
          id: 'expense1',
          title: 'Test Expense',
          amount: 10.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        );

        mockRemoteDataSource.setMockDeltas('expense', [expenseDto]);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true);
        
        // Verify statistics consistency
        final totalByType = result.inboundResults.byEntityType.values
            .fold<int>(0, (sum, count) => sum + count);
        expect(totalByType, result.inboundResults.totalProcessed);
        
        // Verify entity counts
        expect(result.inboundResults.byEntityType.length, 4);
        expect(result.inboundResults.byEntityType.containsKey('expense'), true);
        expect(result.inboundResults.byEntityType.containsKey('category'), true);
        expect(result.inboundResults.byEntityType.containsKey('account'), true);
        expect(result.inboundResults.byEntityType.containsKey('budget'), true);
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle global remote failure', () async {
        mockRemoteDataSource.shouldFail = true;
        mockRemoteDataSource.shouldFailExpenses = true;
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true); // Should still succeed overall
        expect(result.inboundResults.failed, greaterThan(0));
      });

      test('should continue processing other entities when one fails', () async {
        final expenseDto = ExpenseDto(
          id: 'expense1',
          title: 'Test Expense',
          amount: 10.0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          deviceId: 'device1',
          lastEditor: 'user1',
          categoryId: 'food',
        );

        mockRemoteDataSource.setEntityFailure('expense', true);
        mockRemoteDataSource.setMockDeltas('category', []);
        mockRemoteDataSource.setMockDeltas('account', []);
        mockRemoteDataSource.setMockDeltas('budget', []);
        
        final result = await syncOrchestrator.performInboundSync();
        
        expect(result.success, true); // Overall sync should succeed
        expect(result.inboundResults.byEntityType['category'], 0); // Other entities processed
        expect(result.inboundResults.byEntityType['account'], 0);
        expect(result.inboundResults.failed, greaterThan(0)); // But some failed
      });
    });
  });
}