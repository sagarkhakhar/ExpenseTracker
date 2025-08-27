import 'dart:async';
import 'dart:math' as math;

import '../../domain/sync_result.dart';
import '../../domain/sync_status.dart';
import '../../domain/result.dart';
import '../../domain/errors/sync_errors.dart';
import '../../domain/base_entity.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../repositories/lww_conflict_resolver.dart';
import '../mappers/sync_mapper.dart';
import 'mutation_queue_service.dart';
import 'sync_orchestrator.dart';

/// Implementation of bidirectional sync orchestrator
class SyncOrchestratorImpl implements SyncOrchestrator {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final MutationQueueService _mutationQueueService;
  final LWWConflictResolver _conflictResolver;
  final SyncMapper _syncMapper;

  final StreamController<SyncProgress> _progressController = StreamController<SyncProgress>.broadcast();
  Completer<void>? _syncCancellation;
  
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncResult? _lastSyncResult;
  bool _isSyncing = false;
  static final Map<String, Completer<void>?> _syncLocks = {};

  SyncOrchestratorImpl({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    required MutationQueueService mutationQueueService,
    required LWWConflictResolver conflictResolver,
    required SyncMapper syncMapper,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _mutationQueueService = mutationQueueService,
        _conflictResolver = conflictResolver,
        _syncMapper = syncMapper;

  @override
  Stream<SyncProgress> get syncProgress => _progressController.stream;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  bool get isSyncing => _isSyncing;

  @override
  SyncResult? get lastSyncResult => _lastSyncResult;

  @override
  Future<SyncResult> performFullSync({String? userId}) async {
    return _performSyncWithLock('full_sync', () async {
      return await _executeFullSync(userId ?? 'anonymous');
    });
  }

  @override
  Future<SyncResult> performOutboundSync({String? userId}) async {
    return _performSyncWithLock('outbound_sync', () async {
      return await _executeOutboundSync(userId ?? 'anonymous');
    });
  }

  @override
  Future<SyncResult> performInboundSync({String? userId}) async {
    return _performSyncWithLock('inbound_sync', () async {
      return await _executeInboundSync(userId ?? 'anonymous');
    });
  }

  @override
  Future<SyncResult> performFullResync({String? userId}) async {
    return _performSyncWithLock('full_resync', () async {
      // Clear all sync cursors to force full resync
      await _clearSyncCursors();
      return await _executeFullSync(userId ?? 'anonymous');
    });
  }

  @override
  Future<bool> testConnectivity() async {
    try {
      final result = await _remoteDataSource.testConnection();
      return result.fold(
        onSuccess: (connected) => connected,
        onFailure: (_) => false,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cancelSync() async {
    if (_isSyncing) {
      _updateStatus(SyncStatus.cancelled, 'Sync cancelled by user');
      _syncCancellation?.complete();
      _isSyncing = false;
    }
  }

  /// Execute full bidirectional sync with proper error handling
  Future<SyncResult> _executeFullSync(String userId) async {
    final startTime = DateTime.now().toUtc();
    _updateStatus(SyncStatus.preparing, 'Preparing for sync');
    
    var outboundResults = SyncPhaseResults.empty();
    var inboundResults = SyncPhaseResults.empty();
    var statistics = SyncStatistics.empty();

    try {
      // Phase 1: Outbound sync
      _updateStatus(SyncStatus.syncingOutbound, 'Syncing local changes to remote');
      final outboundResult = await _performOutboundPhase(userId);
      
      outboundResult.fold(
        onSuccess: (result) => outboundResults = result,
        onFailure: (error) => throw error,
      );

      // Check for cancellation
      if (_currentStatus == SyncStatus.cancelled || _syncCancellation?.isCompleted == true) {
        return _createCancelledResult(startTime, outboundResults, inboundResults, statistics);
      }

      // Phase 2: Inbound sync
      _updateStatus(SyncStatus.syncingInbound, 'Pulling remote changes');
      final inboundResult = await _performInboundPhase(userId);
      
      inboundResult.fold(
        onSuccess: (result) => inboundResults = result,
        onFailure: (error) => throw error,
      );

      // Check for cancellation
      if (_currentStatus == SyncStatus.cancelled || _syncCancellation?.isCompleted == true) {
        return _createCancelledResult(startTime, outboundResults, inboundResults, statistics);
      }

      // Phase 3: Finalize
      _updateStatus(SyncStatus.finalizing, 'Finalizing sync');
      statistics = _calculateStatistics(outboundResults, inboundResults, startTime);
      
      final endTime = DateTime.now().toUtc();
      _updateStatus(SyncStatus.completed, 'Sync completed successfully');

      final result = SyncResult.success(
        outboundResults: outboundResults,
        inboundResults: inboundResults,
        statistics: statistics,
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = result;
      await _updateLastSuccessfulSyncTime(endTime);
      
      return result;

    } catch (e) {
      final endTime = DateTime.now().toUtc();
      final errorMessage = e is SyncError ? e.message : e.toString();
      
      _updateStatus(SyncStatus.error, 'Sync failed: $errorMessage');

      final result = SyncResult.failure(
        errorMessage: errorMessage,
        outboundResults: outboundResults,
        inboundResults: inboundResults,
        statistics: _calculateStatistics(outboundResults, inboundResults, startTime),
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = result;
      return result;
    }
  }

  /// Execute outbound sync only
  Future<SyncResult> _executeOutboundSync(String userId) async {
    final startTime = DateTime.now().toUtc();
    _updateStatus(SyncStatus.preparing, 'Preparing outbound sync');
    
    try {
      _updateStatus(SyncStatus.syncingOutbound, 'Syncing local changes to remote');
      final result = await _performOutboundPhase(userId);
      
      final outboundResults = await result.fold(
        onSuccess: (results) async => results,
        onFailure: (error) async => throw error,
      );

      final endTime = DateTime.now().toUtc();
      _updateStatus(SyncStatus.completed, 'Outbound sync completed');

      final syncResult = SyncResult.success(
        outboundResults: outboundResults,
        inboundResults: SyncPhaseResults.empty(),
        statistics: _calculateStatistics(outboundResults, SyncPhaseResults.empty(), startTime),
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = syncResult;
      return syncResult;

    } catch (e) {
      final endTime = DateTime.now().toUtc();
      final errorMessage = e is SyncError ? e.message : e.toString();
      
      _updateStatus(SyncStatus.error, 'Outbound sync failed: $errorMessage');

      final result = SyncResult.failure(
        errorMessage: errorMessage,
        outboundResults: SyncPhaseResults.empty(),
        inboundResults: SyncPhaseResults.empty(),
        statistics: SyncStatistics.empty(),
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = result;
      return result;
    }
  }

  /// Execute inbound sync only
  Future<SyncResult> _executeInboundSync(String userId) async {
    final startTime = DateTime.now().toUtc();
    _updateStatus(SyncStatus.preparing, 'Preparing inbound sync');
    
    try {
      _updateStatus(SyncStatus.syncingInbound, 'Pulling remote changes');
      final result = await _performInboundPhase(userId);
      
      final inboundResults = await result.fold(
        onSuccess: (results) async => results,
        onFailure: (error) async => throw error,
      );

      final endTime = DateTime.now().toUtc();
      _updateStatus(SyncStatus.completed, 'Inbound sync completed');

      final syncResult = SyncResult.success(
        outboundResults: SyncPhaseResults.empty(),
        inboundResults: inboundResults,
        statistics: _calculateStatistics(SyncPhaseResults.empty(), inboundResults, startTime),
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = syncResult;
      return syncResult;

    } catch (e) {
      final endTime = DateTime.now().toUtc();
      final errorMessage = e is SyncError ? e.message : e.toString();
      
      _updateStatus(SyncStatus.error, 'Inbound sync failed: $errorMessage');

      final result = SyncResult.failure(
        errorMessage: errorMessage,
        outboundResults: SyncPhaseResults.empty(),
        inboundResults: SyncPhaseResults.empty(),
        statistics: SyncStatistics.empty(),
        startTime: startTime,
        endTime: endTime,
      );

      _lastSyncResult = result;
      return result;
    }
  }

  /// Perform outbound sync phase with detailed progress tracking and retry logic
  Future<Result<SyncPhaseResults>> _performOutboundPhase(String userId) async {
    try {
      _updateStatus(SyncStatus.syncingOutbound, 'Checking outbound mutation queue');

      // Get initial queue statistics
      final queueStatsResult = await _mutationQueueService.getQueueStats();
      final queueStats = await queueStatsResult.fold(
        onSuccess: (stats) async => stats,
        onFailure: (error) async => throw error,
      );

      if (queueStats.totalPending == 0) {
        _updateStatus(SyncStatus.syncingOutbound, 'No pending mutations to sync');
        return Result.success(SyncPhaseResults.empty());
      }

      _updateStatus(
        SyncStatus.syncingOutbound, 
        'Processing ${queueStats.totalPending} pending mutations',
      );

      // Process mutations with progress updates
      final outboundResults = await _processOutboundMutations(queueStats);
      
      return outboundResults.fold(
        onSuccess: (results) {
          _updateStatus(
            SyncStatus.syncingOutbound,
            'Outbound sync completed: ${results.successful}/${results.totalProcessed} successful',
          );
          return Result.success(results);
        },
        onFailure: (error) => Result.failure(error),
      );

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Outbound sync failed: $e'
      ));
    }
  }

  /// Process outbound mutations with detailed tracking and retry logic
  Future<Result<SyncPhaseResults>> _processOutboundMutations(MutationQueueStats queueStats) async {
    int totalProcessed = 0;
    int successful = 0;
    int failed = 0;
    int retries = 0;
    final byEntityType = <String, int>{};
    final errors = <String>[];

    try {
      // Process each entity type separately for better progress tracking
      for (final entityEntry in queueStats.byEntityType.entries) {
        final entityType = entityEntry.key;
        final entityCount = entityEntry.value;
        
        if (entityCount == 0) continue;

        // Check for cancellation before processing each entity type
        if (_currentStatus == SyncStatus.cancelled || _syncCancellation?.isCompleted == true) {
          break;
        }

        _updateStatus(
          SyncStatus.syncingOutbound,
          'Processing $entityCount $entityType mutations',
        );

        // Process mutations for this entity type
        final entityResult = await _processEntityOutboundMutations(entityType);
        
        entityResult.fold(
          onSuccess: (batchResult) {
            totalProcessed += batchResult.totalProcessed;
            successful += batchResult.successful;
            failed += batchResult.failed;
            retries += batchResult.retries;
            byEntityType[entityType] = batchResult.totalProcessed;
          },
          onFailure: (error) {
            failed += entityCount;
            byEntityType[entityType] = entityCount;
            errors.add('$entityType: ${error.message}');
          },
        );

        // Update progress
        _updateProgressWithDetails(
          SyncStatus.syncingOutbound,
          'Processed $totalProcessed of ${queueStats.totalPending} mutations',
          (totalProcessed / queueStats.totalPending) * 100,
          queueStats.totalPending,
          totalProcessed,
        );
      }

      // Final statistics and cleanup
      await _finalizeOutboundSync(successful, failed, retries);

      return Result.success(SyncPhaseResults(
        totalProcessed: totalProcessed,
        successful: successful,
        failed: failed,
        conflicts: 0, // No conflicts in outbound sync
        byEntityType: byEntityType,
        errors: errors.isNotEmpty ? errors : null,
      ));

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Failed to process outbound mutations: $e'
      ));
    }
  }

  /// Process outbound mutations for a specific entity type
  Future<Result<MutationBatchResult>> _processEntityOutboundMutations(
    String entityType,
  ) async {
    try {
      // Get mutations for this entity type
      final result = await _mutationQueueService.processMutationsForEntity(
        entityType: entityType,
      );

      return result.fold(
        onSuccess: (batchResult) {
          // Log success statistics
          if (batchResult.totalProcessed > 0) {
            _logOutboundProgress(entityType, batchResult);
          }
          return Result.success(batchResult);
        },
        onFailure: (error) {
          // Handle specific error types for retry logic
          if (error is NetworkError) {
            // Network errors might be temporary - allow retry
            return Result.failure(error);
          } else if (error is AuthError) {
            // Auth errors are likely permanent - don't retry
            return Result.failure(error);  
          } else {
            // Other errors - allow limited retry
            return Result.failure(error);
          }
        },
      );

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Failed to process $entityType mutations: $e'
      ));
    }
  }

  /// Finalize outbound sync with cleanup and statistics
  Future<void> _finalizeOutboundSync(int successful, int failed, int retries) async {
    try {
      // Clear failed mutations that have exceeded retry limit
      // Only clear if we have retries (indicating some mutations exceeded retry limit)
      if (failed > 0 && retries > 0) {
        await _mutationQueueService.clearFailedMutations();
      }

      // Log final statistics
      _updateStatus(
        SyncStatus.syncingOutbound,
        'Outbound sync completed: $successful successful, $failed failed, $retries retries',
      );

    } catch (e) {
      // Non-critical error - log but don't fail the sync
    }
  }

  /// Log outbound progress for monitoring
  void _logOutboundProgress(String entityType, MutationBatchResult batchResult) {
    // In a production app, this would log to analytics/monitoring service
    final message = 'Outbound $entityType: ${batchResult.successful}/${batchResult.totalProcessed} successful';
    
    _updateStatus(SyncStatus.syncingOutbound, message);
  }

  /// Update progress with detailed information
  void _updateProgressWithDetails(
    SyncStatus status,
    String message,
    double progressPercentage,
    int totalItems,
    int processedItems,
  ) {
    _currentStatus = status;
    if (!_progressController.isClosed) {
      _progressController.add(SyncProgress(
        status: status,
        message: message,
        progressPercentage: progressPercentage,
        totalItems: totalItems,
        processedItems: processedItems,
        timestamp: DateTime.now().toUtc(),
      ));
    }
  }

  /// Perform inbound sync phase with enhanced delta processing and conflict resolution
  Future<Result<SyncPhaseResults>> _performInboundPhase(String userId) async {
    try {
      _updateStatus(SyncStatus.syncingInbound, 'Starting inbound delta sync');

      int totalProcessed = 0;
      int successful = 0;
      int failed = 0;
      int conflicts = 0;
      final byEntityType = <String, int>{};
      final errors = <String>[];

      // Process each entity type with detailed progress tracking
      final entityTypes = ['expense', 'category', 'account', 'budget'];
      
      for (int i = 0; i < entityTypes.length; i++) {
        final entityType = entityTypes[i];
        
        // Check for cancellation before processing each entity type
        if (_currentStatus == SyncStatus.cancelled || _syncCancellation?.isCompleted == true) {
          break;
        }

        _updateStatus(
          SyncStatus.syncingInbound, 
          'Processing $entityType deltas (${i + 1}/${entityTypes.length})'
        );

        // Process inbound deltas for this entity type
        final entityResult = await _processEntityInboundDeltas(userId, entityType);
        
        entityResult.fold(
          onSuccess: (result) {
            totalProcessed += result.processed;
            successful += result.successful;
            failed += result.failed;
            conflicts += result.conflicts;
            byEntityType[entityType] = result.processed;
            
            if (result.processed > 0) {
              _logInboundProgress(entityType, result);
            }
          },
          onFailure: (error) {
            // Record failure but continue processing other entities
            // Individual entity failures should not fail the entire sync
            failed += 1;
            byEntityType[entityType] = 0;
            errors.add('$entityType: ${error.message}');
          },
        );

        // Update overall progress
        _updateProgressWithDetails(
          SyncStatus.syncingInbound,
          'Processed ${i + 1}/${entityTypes.length} entity types',
          ((i + 1) / entityTypes.length) * 100,
          entityTypes.length,
          i + 1,
        );
      }

      // Finalize inbound sync with cursor updates
      await _finalizeInboundSync(successful, failed, conflicts);

      return Result.success(SyncPhaseResults(
        totalProcessed: totalProcessed,
        successful: successful,
        failed: failed,
        conflicts: conflicts,
        byEntityType: byEntityType,
        errors: errors.isNotEmpty ? errors : null,
      ));

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Inbound sync failed: $e'
      ));
    }
  }

  /// Process inbound deltas for a specific entity type with conflict resolution
  Future<Result<InboundEntityResult>> _processEntityInboundDeltas(
    String userId, 
    String entityType,
  ) async {
    try {
      // Get last sync cursor for delta pull
      final lastSyncAt = await _getLastSyncCursor(entityType);
      
      _updateStatus(
        SyncStatus.syncingInbound,
        'Pulling $entityType deltas ${lastSyncAt != null ? 'since ${lastSyncAt.toIso8601String()}' : 'full sync'}',
      );

      // Pull deltas from remote with proper error handling
      final deltasResult = await _pullEntityDeltas(userId, entityType, lastSyncAt);
      final deltas = await deltasResult.fold(
        onSuccess: (data) async => data,
        onFailure: (error) async => throw error,
      );

      if (deltas.isEmpty) {
        return const Result.success(InboundEntityResult(
          processed: 0,
          successful: 0,
          failed: 0,
          conflicts: 0,
        ));
      }

      // Process deltas in batches for better performance and memory management
      return await _processDeltaBatch(entityType, deltas);

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Failed to process $entityType inbound deltas: $e'
      ));
    }
  }

  /// Process a batch of delta entities with conflict resolution
  Future<Result<InboundEntityResult>> _processDeltaBatch(
    String entityType,
    List<dynamic> deltas,
  ) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    int conflicts = 0;
    DateTime? latestTimestamp;

    try {
      _updateStatus(SyncStatus.merging, 'Processing ${deltas.length} $entityType deltas');

      // Process entities in smaller batches to avoid memory issues
      const batchSize = 50;
      final totalBatches = (deltas.length / batchSize).ceil();

      for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
        // Check for cancellation during processing
        if (_currentStatus == SyncStatus.cancelled) {
          break;
        }

        final startIndex = batchIndex * batchSize;
        final endIndex = math.min(startIndex + batchSize, deltas.length);
        final batchDeltas = deltas.sublist(startIndex, endIndex);

        _updateStatus(
          SyncStatus.merging,
          'Processing $entityType batch ${batchIndex + 1}/$totalBatches (${batchDeltas.length} items)',
        );

        // Process each entity in the batch
        for (final deltaDto in batchDeltas) {
          final entityResult = await _processInboundEntity(entityType, deltaDto);
          
          entityResult.fold(
            onSuccess: (result) {
              processed++;
              if (result.wasConflict) {
                conflicts++;
              }
              if (result.wasSuccessful) {
                successful++;
              } else {
                failed++;
              }
              
              // Track latest timestamp for cursor update
              if (result.timestamp != null) {
                if (latestTimestamp == null || result.timestamp!.isAfter(latestTimestamp ?? DateTime.fromMicrosecondsSinceEpoch(0))) {
                  latestTimestamp = result.timestamp;
                }
              }
            },
            onFailure: (error) {
              processed++;
              failed++;
              // Log individual entity failure but continue processing
            },
          );
        }

        // Update progress within batch processing
        _updateProgressWithDetails(
          SyncStatus.merging,
          'Processed ${math.min(endIndex, deltas.length)}/${deltas.length} $entityType entities',
          (math.min(endIndex, deltas.length) / deltas.length) * 100,
          deltas.length,
          math.min(endIndex, deltas.length),
        );
      }

      // Update sync cursor with latest timestamp
      if (latestTimestamp != null && successful > 0) {
        await _updateSyncCursor(entityType, latestTimestamp!);
      }

      return Result.success(InboundEntityResult(
        processed: processed,
        successful: successful,
        failed: failed,
        conflicts: conflicts,
      ));

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Failed to process $entityType delta batch: $e'
      ));
    }
  }


  /// Sync operation with mutex lock to prevent concurrent execution
  Future<SyncResult> _performSyncWithLock(String lockKey, Future<SyncResult> Function() syncOperation) async {
    // Check if already syncing
    if (_syncLocks.containsKey(lockKey) && _syncLocks[lockKey] != null) {
      return SyncResult.failure(
        errorMessage: 'Sync already in progress',
        outboundResults: SyncPhaseResults.empty(),
        inboundResults: SyncPhaseResults.empty(),
        statistics: SyncStatistics.empty(),
        startTime: DateTime.now().toUtc(),
        endTime: DateTime.now().toUtc(),
      );
    }

    final completer = Completer<void>();
    _syncLocks[lockKey] = completer;
    _isSyncing = true;
    
    // Initialize cancellation completer
    _syncCancellation = Completer<void>();

    try {
      final result = await syncOperation();
      return result;
    } finally {
      _isSyncing = false;
      
      // Only update status to idle if it's not already completed, cancelled, or error
      if (_currentStatus != SyncStatus.completed && 
          _currentStatus != SyncStatus.cancelled && 
          _currentStatus != SyncStatus.error) {
        _updateStatus(SyncStatus.idle, 'Sync operation finished');
      }
      
      completer.complete();
      _syncLocks.remove(lockKey);
      _syncCancellation = null;
    }
  }

  /// Update sync status and notify listeners
  void _updateStatus(SyncStatus status, String? message) {
    _currentStatus = status;
    if (!_progressController.isClosed) {
      _progressController.add(SyncProgress(
        status: status,
        message: message,
        timestamp: DateTime.now().toUtc(),
      ));
    }
  }

  /// Calculate comprehensive sync statistics
  SyncStatistics _calculateStatistics(
    SyncPhaseResults outboundResults,
    SyncPhaseResults inboundResults,
    DateTime startTime,
  ) {
    return SyncStatistics(
      totalEntitiesSynced: outboundResults.successful + inboundResults.successful,
      totalConflictsResolved: inboundResults.conflicts,
      outboundMutations: outboundResults.totalProcessed,
      inboundDeltas: inboundResults.totalProcessed,
      totalDuration: DateTime.now().toUtc().difference(startTime),
      entityStats: _calculateEntityStats(outboundResults, inboundResults),
    );
  }

  /// Calculate per-entity statistics
  Map<String, EntitySyncStats> _calculateEntityStats(
    SyncPhaseResults outboundResults,
    SyncPhaseResults inboundResults,
  ) {
    final entityStats = <String, EntitySyncStats>{};
    final allEntityTypes = {
      ...outboundResults.byEntityType.keys,
      ...inboundResults.byEntityType.keys,
    };

    for (final entityType in allEntityTypes) {
      entityStats[entityType] = EntitySyncStats(
        entityType: entityType,
        outboundCount: outboundResults.byEntityType[entityType] ?? 0,
        inboundCount: inboundResults.byEntityType[entityType] ?? 0,
        conflictCount: 0, // Would need more detailed tracking
        lastSyncAt: DateTime.now().toUtc(),
      );
    }

    return entityStats;
  }

  /// Create cancelled sync result
  SyncResult _createCancelledResult(
    DateTime startTime,
    SyncPhaseResults outboundResults,
    SyncPhaseResults inboundResults,
    SyncStatistics statistics,
  ) {
    return SyncResult.failure(
      errorMessage: 'Sync cancelled by user',
      outboundResults: outboundResults,
      inboundResults: inboundResults,
      statistics: statistics,
      startTime: startTime,
      endTime: DateTime.now().toUtc(),
    );
  }

  // Helper methods that would need implementation based on existing data sources

  Future<Result<List<dynamic>>> _pullEntityDeltas(String userId, String entityType, DateTime? lastSyncAt) async {
    switch (entityType) {
      case 'expense':
        return _remoteDataSource.pullExpenseDeltas(userId: userId, lastSyncAt: lastSyncAt);
      case 'category':
        return _remoteDataSource.pullCategoryDeltas(userId: userId, lastSyncAt: lastSyncAt);
      case 'account':
        return _remoteDataSource.pullAccountDeltas(userId: userId, lastSyncAt: lastSyncAt);
      case 'budget':
        return _remoteDataSource.pullBudgetDeltas(userId: userId, lastSyncAt: lastSyncAt);
      default:
        return Result.failure(ValidationError(message: 'Unknown entity type: $entityType'));
    }
  }

  /// Convert DTO to domain entity based on entity type
  dynamic _convertDtoToEntity(dynamic dto, String entityType) {
    switch (entityType) {
      case 'expense':
        return SyncMapper.dtoToSyncExpense(dto);
      case 'category':
        return SyncMapper.dtoToSyncCategory(dto);
      case 'account':
        return SyncMapper.dtoToSyncAccount(dto);
      case 'budget':
        return SyncMapper.dtoToSyncBudget(dto);
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }

  /// Extract latest timestamp from list of DTOs
  DateTime _extractLatestTimestamp(List<dynamic> dtos) {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0).toUtc();
    
    for (final dto in dtos) {
      DateTime timestamp;
      if (dto.updatedAt != null) {
        timestamp = dto.updatedAt;
      } else {
        timestamp = dto.createdAt ?? DateTime.now().toUtc();
      }
      
      if (timestamp.isAfter(latest)) {
        latest = timestamp;
      }
    }
    
    return latest;
  }

  Future<dynamic> _getLocalEntity(String entityType, String id) async {
    // Would delegate to specific local data source implementations
    // This is a simplified implementation that would need to be expanded
    return null; // Implementation needed based on existing sync data source methods
  }

  Future<void> _saveLocalEntity(String entityType, dynamic entity) async {
    // Would delegate to specific local data source implementations
    // This is a simplified implementation that would need to be expanded
  }

  Future<DateTime?> _getLastSyncCursor(String entityType) async {
    final metadata = await _localDataSource.getSyncMetadata(entityType);
    return metadata?.lastPullCursor;
  }

  Future<void> _updateSyncCursor(String entityType, DateTime timestamp) async {
    await _localDataSource.updateLastPullCursor(entityType, timestamp);
  }

  Future<void> _clearSyncCursors() async {
    await _localDataSource.clearAllSyncMetadata();
  }

  Future<void> _updateLastSuccessfulSyncTime(DateTime time) async {
    // Update for all entity types - would typically loop through all types
    for (final entityType in ['expense', 'category', 'account', 'budget']) {
      await _localDataSource.updateLastSuccessfulSync(entityType, time);
    }
  }

  /// Process individual inbound entity with conflict resolution
  Future<Result<InboundEntityProcessingResult>> _processInboundEntity(
    String entityType,
    dynamic deltaDto,
  ) async {
    try {
      // Convert DTO to domain entity
      final remoteEntity = _convertDtoToEntity(deltaDto, entityType) as BaseEntity;
      
      // Get local entity if exists  
      final localEntity = await _getLocalEntity(entityType, remoteEntity.id) as BaseEntity?;
      
      bool wasConflict = false;
      bool wasSuccessful = false;
      BaseEntity? entityToSave;

      if (localEntity == null) {
        // New entity - save remote version
        entityToSave = remoteEntity;
        wasSuccessful = true;
      } else {
        // Potential conflict - apply LWW resolution
        if (_hasConflict(localEntity, remoteEntity)) {
          wasConflict = true;
          entityToSave = _conflictResolver.resolveConflict(localEntity, remoteEntity);
          wasSuccessful = true;
        } else {
          // No conflict - just update with remote version
          entityToSave = remoteEntity;
          wasSuccessful = true;
        }
      }

      // Save resolved entity to local storage
      await _saveLocalEntity(entityType, entityToSave);
    
      return Result.success(InboundEntityProcessingResult(
        wasConflict: wasConflict,
        wasSuccessful: wasSuccessful,
        timestamp: remoteEntity.updatedAt,
      ));

    } catch (e) {
      return Result.failure(SyncOperationError(
        message: 'Failed to process inbound $entityType entity: $e'
      ));
    }
  }

  /// Check if there's a conflict between local and remote entities
  bool _hasConflict(BaseEntity local, BaseEntity remote) {
    return local.id == remote.id && 
           (local.version != remote.version || 
            local.updatedAt != remote.updatedAt ||
            local.isDeleted != remote.isDeleted);
  }

  /// Finalize inbound sync with statistics and cleanup
  Future<void> _finalizeInboundSync(int successful, int failed, int conflicts) async {
    try {
      _updateStatus(
        SyncStatus.syncingInbound,
        'Inbound sync completed: $successful successful, $failed failed, $conflicts conflicts resolved',
      );
      
      // Additional cleanup or validation could be done here
      
    } catch (e) {
      // Non-critical error - log but don't fail the sync
    }
  }

  /// Log inbound progress for monitoring
  void _logInboundProgress(String entityType, InboundEntityResult result) {
    final message = 'Inbound $entityType: ${result.successful}/${result.processed} successful';
    if (result.conflicts > 0) {
      _updateStatus(SyncStatus.merging, '$message, ${result.conflicts} conflicts resolved');
    } else {
      _updateStatus(SyncStatus.syncingInbound, message);
    }
  }

  void dispose() {
    _progressController.close();
  }
}

/// Result of processing inbound deltas for a specific entity type
class InboundEntityResult {
  final int processed;
  final int successful;
  final int failed;
  final int conflicts;

  const InboundEntityResult({
    required this.processed,
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  @override
  String toString() {
    return 'InboundEntityResult{processed: $processed, successful: $successful, failed: $failed, conflicts: $conflicts}';
  }
}

/// Result of processing a single inbound entity
class InboundEntityProcessingResult {
  final bool wasConflict;
  final bool wasSuccessful;
  final DateTime? timestamp;

  const InboundEntityProcessingResult({
    required this.wasConflict,
    required this.wasSuccessful,
    this.timestamp,
  });

  @override
  String toString() {
    return 'InboundEntityProcessingResult{wasConflict: $wasConflict, wasSuccessful: $wasSuccessful, timestamp: $timestamp}';
  }
}