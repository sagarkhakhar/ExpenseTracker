import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/sync_orchestrator.dart';
import '../data/services/sync_orchestrator_impl.dart';
import '../data/services/mutation_queue_service.dart';
import '../data/datasources/supabase_remote_data_source.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../data/repositories/lww_conflict_resolver.dart';
import '../data/datasources/local_data_source_impl.dart';
import '../data/mappers/sync_mapper.dart';
import '../domain/sync_result.dart';
import '../domain/sync_status.dart';
import '../services/authentication_service.dart';

/// Provider for Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the remote data source (Supabase)
final remoteDataSourceProvider = Provider<SupabaseRemoteDataSource>((ref) {
  final client = ref.read(supabaseClientProvider);
  return SupabaseRemoteDataSource(client);
});

/// Provider for the local data source
final localDataSourceProvider = Provider<LocalDataSourceImpl>((ref) {
  return LocalDataSourceImpl();
});

/// Provider for the mutation queue service
final mutationQueueServiceProvider = Provider<MutationQueueService>((ref) {
  final localDataSource = ref.read(localDataSourceProvider);
  final remoteDataSource = ref.read(remoteDataSourceProvider);
  return MutationQueueService(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

/// Provider for the sync mapper
final syncMapperProvider = Provider<SyncMapper>((ref) {
  return SyncMapper();
});

/// Provider for the sync repository
final syncRepositoryProvider = Provider<SyncRepositoryImpl>((ref) {
  final remoteDataSource = ref.read(remoteDataSourceProvider);
  final localDataSource = ref.read(localDataSourceProvider);
  final mutationQueueService = ref.read(mutationQueueServiceProvider);
  final syncMapper = ref.read(syncMapperProvider);
  
  return SyncRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    mutationQueueService: mutationQueueService,
    syncMapper: syncMapper,
  );
});

/// Provider for the sync orchestrator
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final remoteDataSource = ref.read(remoteDataSourceProvider);
  final localDataSource = ref.read(localDataSourceProvider);
  final mutationQueueService = ref.read(mutationQueueServiceProvider);
  final syncMapper = ref.read(syncMapperProvider);
  
  return SyncOrchestratorImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    mutationQueueService: mutationQueueService,
    conflictResolver: LWWConflictResolverImpl(),
    syncMapper: syncMapper,
  );
});

/// Provider to trigger outbound sync (fire and forget)
final outboundSyncProvider = FutureProvider<SyncResult>((ref) async {
  final orchestrator = ref.read(syncOrchestratorProvider);
  final authService = ref.read(authenticationServiceProvider);
  
  final userId = authService.currentUserId ?? 'anonymous';
  
  return orchestrator.performOutboundSync(userId: userId);
});

/// Provider to check sync connectivity
final syncConnectivityProvider = FutureProvider<bool>((ref) async {
  final orchestrator = ref.read(syncOrchestratorProvider);
  return orchestrator.testConnectivity();
});

/// Provider for current sync status
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, AsyncValue<SyncStatus>>((ref) {
  return SyncStatusNotifier(ref);
});

/// Provider for last sync time
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for manual sync operations
final manualSyncProvider = StateNotifierProvider<ManualSyncNotifier, AsyncValue<SyncResult?>>((ref) {
  return ManualSyncNotifier(ref);
});

/// Sync Status Notifier
class SyncStatusNotifier extends StateNotifier<AsyncValue<SyncStatus>> {
  final Ref _ref;
  
  SyncStatusNotifier(this._ref) : super(const AsyncValue.data(SyncStatus.offline)) {
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    state = const AsyncValue.loading();
    
    try {
      final orchestrator = _ref.read(syncOrchestratorProvider);
      final isConnected = await orchestrator.testConnectivity();
      
      if (isConnected) {
        state = const AsyncValue.data(SyncStatus.synced);
      } else {
        state = const AsyncValue.data(SyncStatus.offline);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void updateStatus(SyncStatus status) {
    state = AsyncValue.data(status);
  }

  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}

/// Manual Sync Notifier
class ManualSyncNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  final Ref _ref;
  
  ManualSyncNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> performManualSync() async {
    if (state is AsyncLoading) return; // Already syncing

    state = const AsyncValue.loading();
    
    // Update sync status to syncing
    _ref.read(syncStatusProvider.notifier).updateStatus(SyncStatus.syncing);

    try {
      final orchestrator = _ref.read(syncOrchestratorProvider);
      final authService = _ref.read(authenticationServiceProvider);
      
      final userId = authService.currentUserId ?? 'anonymous';
      
      final result = await orchestrator.performFullSync(userId: userId);
      
      state = AsyncValue.data(result);
      
      // Update sync status based on result
      if (result.isSuccess) {
        _ref.read(syncStatusProvider.notifier).updateStatus(SyncStatus.synced);
        _ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
      } else {
        _ref.read(syncStatusProvider.notifier).updateStatus(SyncStatus.error);
      }
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _ref.read(syncStatusProvider.notifier).setError(error, stackTrace);
    }
  }
}