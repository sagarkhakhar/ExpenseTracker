/// Sync operation status for UI and state management
enum SyncStatus {
  /// No sync operation in progress
  idle,
  
  /// Preparing for sync operation
  preparing,
  
  /// Processing outbound mutations (local → remote)
  syncingOutbound,
  
  /// Processing inbound deltas (remote → local)
  syncingInbound,
  
  /// Merging conflicts and updating local storage
  merging,
  
  /// Finalizing sync and updating cursors
  finalizing,
  
  /// Sync completed successfully
  completed,
  
  /// Sync failed with recoverable error
  error,
  
  /// Sync was cancelled by user or system
  cancelled,
}

/// Detailed sync progress information
class SyncProgress {
  final SyncStatus status;
  final String? message;
  final double? progressPercentage;
  final int? totalItems;
  final int? processedItems;
  final DateTime timestamp;

  const SyncProgress({
    required this.status,
    this.message,
    this.progressPercentage,
    this.totalItems,
    this.processedItems,
    required this.timestamp,
  });

  SyncProgress copyWith({
    SyncStatus? status,
    String? message,
    double? progressPercentage,
    int? totalItems,
    int? processedItems,
    DateTime? timestamp,
  }) {
    return SyncProgress(
      status: status ?? this.status,
      message: message ?? this.message,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SyncProgress{status: $status, message: $message, progress: $progressPercentage%, processed: $processedItems/$totalItems, timestamp: $timestamp}';
  }
}