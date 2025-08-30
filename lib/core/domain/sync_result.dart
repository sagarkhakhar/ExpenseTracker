import '../data/services/mutation_queue_service.dart';

/// Result of a sync operation with detailed statistics
class SyncResult {
  final bool success;
  final String? errorMessage;
  final SyncPhaseResults outboundResults;
  final SyncPhaseResults inboundResults;
  final SyncStatistics statistics;
  final DateTime startTime;
  final DateTime endTime;

  const SyncResult({
    required this.success,
    this.errorMessage,
    required this.outboundResults,
    required this.inboundResults,
    required this.statistics,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  /// Convenience getter for success status
  bool get isSuccess => success;

  /// Create a successful sync result
  factory SyncResult.success({
    required SyncPhaseResults outboundResults,
    required SyncPhaseResults inboundResults,
    required SyncStatistics statistics,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return SyncResult(
      success: true,
      outboundResults: outboundResults,
      inboundResults: inboundResults,
      statistics: statistics,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Create a failed sync result
  factory SyncResult.failure({
    required String errorMessage,
    required SyncPhaseResults outboundResults,
    required SyncPhaseResults inboundResults,
    required SyncStatistics statistics,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return SyncResult(
      success: false,
      errorMessage: errorMessage,
      outboundResults: outboundResults,
      inboundResults: inboundResults,
      statistics: statistics,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  String toString() {
    return 'SyncResult{success: $success, errorMessage: $errorMessage, duration: ${duration.inSeconds}s, outbound: $outboundResults, inbound: $inboundResults}';
  }
}

/// Results from a specific sync phase (outbound or inbound)
class SyncPhaseResults {
  final int totalProcessed;
  final int successful;
  final int failed;
  final int conflicts;
  final Map<String, int> byEntityType;
  final List<String>? errors;

  const SyncPhaseResults({
    required this.totalProcessed,
    required this.successful,
    required this.failed,
    required this.conflicts,
    required this.byEntityType,
    this.errors,
  });

  /// Create empty results for no-op phase
  factory SyncPhaseResults.empty() {
    return const SyncPhaseResults(
      totalProcessed: 0,
      successful: 0,
      failed: 0,
      conflicts: 0,
      byEntityType: {},
    );
  }

  /// Create results from mutation batch result
  factory SyncPhaseResults.fromMutationBatch(
    MutationBatchResult batchResult,
    Map<String, int> byEntityType,
  ) {
    return SyncPhaseResults(
      totalProcessed: batchResult.totalProcessed,
      successful: batchResult.successful,
      failed: batchResult.failed,
      conflicts: 0, // Conflicts handled at inbound level
      byEntityType: byEntityType,
    );
  }

  @override
  String toString() {
    return 'SyncPhaseResults{totalProcessed: $totalProcessed, successful: $successful, failed: $failed, conflicts: $conflicts}';
  }
}

/// Overall sync statistics
class SyncStatistics {
  final int totalEntitiesSynced;
  final int totalConflictsResolved;
  final int outboundMutations;
  final int inboundDeltas;
  final Duration totalDuration;
  final DateTime? lastSuccessfulSync;
  final Map<String, EntitySyncStats> entityStats;

  const SyncStatistics({
    required this.totalEntitiesSynced,
    required this.totalConflictsResolved,
    required this.outboundMutations,
    required this.inboundDeltas,
    required this.totalDuration,
    this.lastSuccessfulSync,
    required this.entityStats,
  });

  /// Create empty statistics
  factory SyncStatistics.empty() {
    return const SyncStatistics(
      totalEntitiesSynced: 0,
      totalConflictsResolved: 0,
      outboundMutations: 0,
      inboundDeltas: 0,
      totalDuration: Duration.zero,
      entityStats: {},
    );
  }

  @override
  String toString() {
    return 'SyncStatistics{totalSynced: $totalEntitiesSynced, conflicts: $totalConflictsResolved, outbound: $outboundMutations, inbound: $inboundDeltas, duration: ${totalDuration.inSeconds}s}';
  }
}

/// Statistics for a specific entity type
class EntitySyncStats {
  final String entityType;
  final int outboundCount;
  final int inboundCount;
  final int conflictCount;
  final DateTime? lastSyncAt;

  const EntitySyncStats({
    required this.entityType,
    required this.outboundCount,
    required this.inboundCount,
    required this.conflictCount,
    this.lastSyncAt,
  });

  @override
  String toString() {
    return 'EntitySyncStats{type: $entityType, outbound: $outboundCount, inbound: $inboundCount, conflicts: $conflictCount}';
  }
}