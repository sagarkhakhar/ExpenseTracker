import 'dart:async';
import 'dart:math';

import '../entities/mutation_queue_item.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../../domain/errors/sync_errors.dart';
import '../../domain/result.dart';

/// Service for managing outbound mutation queue with batch processing
class MutationQueueService {
  static const int maxBatchSize = 200;
  static const int maxRetryCount = 3;
  static const Duration baseRetryDelay = Duration(minutes: 1);

  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;

  MutationQueueService({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  /// Add a mutation operation to the queue
  Future<Result<void>> enqueueOperation({
    required String entityType,
    required String entityId,
    required MutationType operation,
    required Map<String, dynamic> data,
    int priority = 0,
    DateTime? scheduleFor,
  }) async {
    try {
      final item = MutationQueueItem(
        id: _generateMutationId(),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        data: data,
        createdAt: DateTime.now().toUtc(),
        priority: priority,
        scheduledFor: scheduleFor,
      );

      await _localDataSource.enqueueOperation(item);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(StorageError(message: 'Failed to enqueue operation: $e'));
    }
  }

  /// Process all pending mutations in batches
  Future<Result<MutationBatchResult>> processPendingMutations({
    int? batchSize,
  }) async {
    try {
      final effectiveBatchSize = min(batchSize ?? maxBatchSize, maxBatchSize);
      final mutations = await _localDataSource.getReadyMutations(
        limit: effectiveBatchSize,
      );

      if (mutations.isEmpty) {
        return const Result.success(MutationBatchResult(
          totalProcessed: 0,
          successful: 0,
          failed: 0,
          retries: 0,
        ));
      }

      return await _processBatch(mutations);
    } catch (e) {
      return Result.failure(SyncOperationError(message: 'Failed to process mutations: $e'));
    }
  }

  /// Process mutations for a specific entity type
  Future<Result<MutationBatchResult>> processMutationsForEntity({
    required String entityType,
    int? batchSize,
  }) async {
    try {
      final effectiveBatchSize = min(batchSize ?? maxBatchSize, maxBatchSize);
      final mutations = await _localDataSource.getPendingMutationsForEntity(
        entityType,
        limit: effectiveBatchSize,
      );

      if (mutations.isEmpty) {
        return const Result.success(MutationBatchResult(
          totalProcessed: 0,
          successful: 0,
          failed: 0,
          retries: 0,
        ));
      }

      return await _processBatch(mutations);
    } catch (e) {
      return Result.failure(SyncOperationError(message: 'Failed to process mutations for $entityType: $e'));
    }
  }

  /// Get queue statistics
  Future<Result<MutationQueueStats>> getQueueStats() async {
    try {
      final totalCount = await _localDataSource.getPendingMutationCount();
      final readyMutations = await _localDataSource.getReadyMutations();
      final readyCount = readyMutations.length;

      // Group by entity type
      final byEntityType = <String, int>{};
      for (final mutation in readyMutations) {
        byEntityType[mutation.entityType] = 
            (byEntityType[mutation.entityType] ?? 0) + 1;
      }

      return Result.success(MutationQueueStats(
        totalPending: totalCount,
        readyToProcess: readyCount,
        byEntityType: byEntityType,
      ));
    } catch (e) {
      return Result.failure(StorageError(message: 'Failed to get queue stats: $e'));
    }
  }

  /// Clear failed mutations that have exceeded retry limit
  Future<Result<int>> clearFailedMutations() async {
    try {
      final mutations = await _localDataSource.getPendingMutations();
      final failedMutations = mutations
          .where((m) => m.retryCount >= maxRetryCount)
          .toList();

      if (failedMutations.isNotEmpty) {
        await _localDataSource.dequeueMutations(
          failedMutations.map((m) => m.id).toList(),
        );
      }

      return Result.success(failedMutations.length);
    } catch (e) {
      return Result.failure(StorageError(message: 'Failed to clear failed mutations: $e'));
    }
  }

  /// Process a batch of mutations
  Future<Result<MutationBatchResult>> _processBatch(
    List<MutationQueueItem> mutations,
  ) async {
    int successful = 0;
    int failed = 0;
    int retries = 0;
    final processedIds = <String>[];
    final retryIds = <String>[];

    // Group mutations by entity type for efficient batch processing
    final groupedMutations = <String, List<MutationQueueItem>>{};
    for (final mutation in mutations) {
      groupedMutations.putIfAbsent(mutation.entityType, () => []).add(mutation);
    }

    // Process each entity type group
    for (final entry in groupedMutations.entries) {
      final entityType = entry.key;
      final entityMutations = entry.value;

      final batchResult = await _processBatchForEntityType(
        entityType,
        entityMutations,
      );

      successful += batchResult.successful;
      failed += batchResult.failed;
      retries += batchResult.retries;
      processedIds.addAll(batchResult.processedIds);
      retryIds.addAll(batchResult.retryIds);
    }

    // Remove successfully processed mutations
    if (processedIds.isNotEmpty) {
      await _localDataSource.dequeueMutations(processedIds);
    }

    // Schedule retries for failed mutations
    for (final retryId in retryIds) {
      await _localDataSource.incrementRetryCount(retryId);
      await _scheduleRetry(retryId);
    }

    return Result.success(MutationBatchResult(
      totalProcessed: mutations.length,
      successful: successful,
      failed: failed,
      retries: retries,
    ));
  }

  /// Process mutations for a specific entity type
  Future<_EntityBatchResult> _processBatchForEntityType(
    String entityType,
    List<MutationQueueItem> mutations,
  ) async {
    final processedIds = <String>[];
    final retryIds = <String>[];
    int successful = 0;
    int failed = 0;
    int retries = 0;

    try {
      // Convert mutations to DTOs based on entity type
      final dtos = mutations.map((m) => m.data).toList();

      // Perform batch operation via remote data source
      final result = await _performBatchOperation(entityType, mutations, dtos);

      return result.fold(
        onSuccess: (batchResponse) {
          // All operations in batch succeeded
          successful = mutations.length;
          processedIds.addAll(mutations.map((m) => m.id));
          return _EntityBatchResult(
            successful: successful,
            failed: failed,
            retries: retries,
            processedIds: processedIds,
            retryIds: retryIds,
          );
        },
        onFailure: (error) {
          // Handle batch failure - retry individual operations if appropriate
          if (error is NetworkError) {
            // Network issues might be resolved by retrying
            retries = mutations.length;
            retryIds.addAll(mutations.map((m) => m.id));
          } else {
            // Other errors might be permanent
            failed = mutations.length;
            retryIds.addAll(
              mutations.where((m) => m.retryCount < maxRetryCount).map((m) => m.id),
            );
          }

          return _EntityBatchResult(
            successful: successful,
            failed: failed,
            retries: retries,
            processedIds: processedIds,
            retryIds: retryIds,
          );
        },
      );
    } catch (e) {
      // Unexpected error - retry all mutations
      retries = mutations.length;
      retryIds.addAll(mutations.map((m) => m.id));
      return _EntityBatchResult(
        successful: successful,
        failed: failed,
        retries: retries,
        processedIds: processedIds,
        retryIds: retryIds,
      );
    }
  }

  /// Perform batch operation based on entity type
  Future<Result<void>> _performBatchOperation(
    String entityType,
    List<MutationQueueItem> mutations,
    List<Map<String, dynamic>> dtos,
  ) async {
    switch (entityType) {
      case 'expense':
        return await _remoteDataSource.batchUpsertExpenses(dtos);
      case 'category':
        return await _remoteDataSource.batchUpsertCategories(dtos);
      case 'account':
        return await _remoteDataSource.batchUpsertAccounts(dtos);
      case 'budget':
        return await _remoteDataSource.batchUpsertBudgets(dtos);
      default:
        return Result.failure(ValidationError(message: 'Unknown entity type: $entityType'));
    }
  }

  /// Schedule a mutation for retry with exponential backoff
  Future<void> _scheduleRetry(String mutationId) async {
    try {
      final mutations = await _localDataSource.getPendingMutations();
      final mutation = mutations.firstWhere((m) => m.id == mutationId);
      
      final delay = _calculateRetryDelay(mutation.retryCount);
      final scheduleFor = DateTime.now().add(delay);
      
      await _localDataSource.scheduleMutation(mutationId, scheduleFor);
    } catch (e) {
      // If scheduling fails, the mutation will be processed in the next batch
    }
  }

  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int retryCount) {
    final backoffMultiplier = pow(2, retryCount).toInt();
    return baseRetryDelay * backoffMultiplier;
  }

  /// Generate a unique mutation ID
  String _generateMutationId() {
    return 'mut_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }
}

/// Result of processing a batch of mutations
class MutationBatchResult {
  final int totalProcessed;
  final int successful;
  final int failed;
  final int retries;

  const MutationBatchResult({
    required this.totalProcessed,
    required this.successful,
    required this.failed,
    required this.retries,
  });

  @override
  String toString() {
    return 'MutationBatchResult{totalProcessed: $totalProcessed, successful: $successful, failed: $failed, retries: $retries}';
  }
}

/// Statistics about the mutation queue
class MutationQueueStats {
  final int totalPending;
  final int readyToProcess;
  final Map<String, int> byEntityType;

  const MutationQueueStats({
    required this.totalPending,
    required this.readyToProcess,
    required this.byEntityType,
  });

  @override
  String toString() {
    return 'MutationQueueStats{totalPending: $totalPending, readyToProcess: $readyToProcess, byEntityType: $byEntityType}';
  }
}

/// Internal result for entity batch processing
class _EntityBatchResult {
  final int successful;
  final int failed;
  final int retries;
  final List<String> processedIds;
  final List<String> retryIds;

  const _EntityBatchResult({
    required this.successful,
    required this.failed,
    required this.retries,
    required this.processedIds,
    required this.retryIds,
  });
}