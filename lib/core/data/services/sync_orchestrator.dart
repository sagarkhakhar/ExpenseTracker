import 'dart:async';
import '../../domain/sync_result.dart';
import '../../domain/sync_status.dart';

/// Orchestrates bidirectional synchronization between local and remote data sources
/// 
/// Manages the complete sync flow:
/// 1. Drain outbound mutations from local queue to remote
/// 2. Pull inbound deltas from remote  
/// 3. Resolve conflicts using LWW strategy
/// 4. Update local storage with merged results
/// 5. Advance sync cursors
abstract class SyncOrchestrator {
  
  /// Perform a complete bidirectional sync operation
  /// This includes both outbound and inbound sync phases
  Future<SyncResult> performFullSync({String? userId});

  /// Perform only outbound sync (local changes → remote)
  /// Drains mutation queue and uploads to remote storage
  Future<SyncResult> performOutboundSync({String? userId});

  /// Perform only inbound sync (remote changes → local)
  /// Pulls deltas from remote and merges into local storage  
  Future<SyncResult> performInboundSync({String? userId});

  /// Stream of sync status updates for UI integration
  Stream<SyncProgress> get syncProgress;

  /// Current sync status
  SyncStatus get currentStatus;

  /// Cancel any running sync operation
  Future<void> cancelSync();

  /// Check if sync is currently in progress
  bool get isSyncing;

  /// Get the last sync result
  SyncResult? get lastSyncResult;

  /// Force a full resync (ignores cursors)
  Future<SyncResult> performFullResync({String? userId});

  /// Test connectivity before attempting sync
  Future<bool> testConnectivity();
}