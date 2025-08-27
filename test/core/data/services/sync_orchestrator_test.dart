import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';

import 'sync_orchestrator_test.mocks.dart';

@GenerateMocks([
  LocalDataSource,
  RemoteDataSource,
  MutationQueueService,
  LWWConflictResolver,
  SyncMapper,
])
void main() {
  group('SyncOrchestratorImpl', () {
    late SyncOrchestratorImpl syncOrchestrator;
    late MockLocalDataSource mockLocalDataSource;
    late MockRemoteDataSource mockRemoteDataSource;
    late MockMutationQueueService mockMutationQueueService;
    late MockLWWConflictResolver mockConflictResolver;
    late MockSyncMapper mockSyncMapper;

    setUp(() {
      mockLocalDataSource = MockLocalDataSource();
      mockRemoteDataSource = MockRemoteDataSource();
      mockMutationQueueService = MockMutationQueueService();
      mockConflictResolver = MockLWWConflictResolver();
      mockSyncMapper = MockSyncMapper();

      syncOrchestrator = SyncOrchestratorImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        mutationQueueService: mockMutationQueueService,
        conflictResolver: mockConflictResolver,
        syncMapper: mockSyncMapper,
      );
    });

    tearDown(() {
      syncOrchestrator.dispose();
    });

    group('Initialization and Status', () {
      test('should initialize with idle status', () {
        expect(syncOrchestrator.currentStatus, SyncStatus.idle);
        expect(syncOrchestrator.isSyncing, false);
        expect(syncOrchestrator.lastSyncResult, isNull);
      });

      test('should provide sync progress stream', () {
        expect(syncOrchestrator.syncProgress, isA<Stream<SyncProgress>>());
      });
    });

    group('Connectivity Testing', () {
      test('should return true when remote connection succeeds', () async {
        when(mockRemoteDataSource.testConnection())
            .thenAnswer((_) async => const Result.success(true));

        final result = await syncOrchestrator.testConnectivity();
        
        expect(result, true);
        verify(mockRemoteDataSource.testConnection()).called(1);
      });

      test('should return false when remote connection fails', () async {
        when(mockRemoteDataSource.testConnection())
            .thenAnswer((_) async => const Result.failure(NetworkError(message: 'No connection')));

        final result = await syncOrchestrator.testConnectivity();
        
        expect(result, false);
        verify(mockRemoteDataSource.testConnection()).called(1);
      });

      test('should return false when remote connection throws exception', () async {
        when(mockRemoteDataSource.testConnection())
            .thenThrow(Exception('Connection error'));

        final result = await syncOrchestrator.testConnectivity();
        
        expect(result, false);
        verify(mockRemoteDataSource.testConnection()).called(1);
      });
    });

    group('Outbound Sync', () {
      test('should complete successfully when no mutations are pending', () async {
        // Setup: No pending mutations
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.success(MutationQueueStats(
              totalPending: 0,
              readyToProcess: 0,
              byEntityType: {},
            )));

        final result = await syncOrchestrator.performOutboundSync();

        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 0);
        expect(result.inboundResults.totalProcessed, 0);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should process pending mutations successfully', () async {
        // Setup: Pending mutations exist
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.success(MutationQueueStats(
              totalPending: 5,
              readyToProcess: 5,
              byEntityType: {'expense': 3, 'category': 2},
            )));

        when(mockMutationQueueService.processPendingMutations())
            .thenAnswer((_) async => const Result.success(MutationBatchResult(
              totalProcessed: 5,
              successful: 5,
              failed: 0,
              retries: 0,
            )));

        final result = await syncOrchestrator.performOutboundSync();

        expect(result.success, true);
        expect(result.outboundResults.totalProcessed, 5);
        expect(result.outboundResults.successful, 5);
        expect(result.outboundResults.failed, 0);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should handle outbound sync failure', () async {
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.failure(StorageError(message: 'Storage error')));

        final result = await syncOrchestrator.performOutboundSync();

        expect(result.success, false);
        expect(result.errorMessage, contains('Storage error'));
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });
    });

    group('Inbound Sync', () {
      test('should complete successfully when no deltas are available', () async {
        // Setup: No remote deltas
        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));
        when(mockRemoteDataSource.pullCategoryDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullAccountDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullBudgetDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));

        // Setup: Sync metadata
        when(mockLocalDataSource.getSyncMetadata())
            .thenAnswer((_) async => null);

        final result = await syncOrchestrator.performInboundSync();

        expect(result.success, true);
        expect(result.inboundResults.totalProcessed, 0);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
      });

      test('should handle inbound sync failure', () async {
        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.failure(NetworkError(message: 'Network error')));

        final result = await syncOrchestrator.performInboundSync();

        expect(result.success, false);
        expect(result.errorMessage, contains('Network error'));
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });
    });

    group('Full Sync', () {
      test('should complete full bidirectional sync successfully', () async {
        // Setup outbound phase
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.success(MutationQueueStats(
              totalPending: 0,
              readyToProcess: 0,
              byEntityType: {},
            )));

        // Setup inbound phase  
        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));
        when(mockRemoteDataSource.pullCategoryDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullAccountDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullBudgetDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));

        when(mockLocalDataSource.getSyncMetadata())
            .thenAnswer((_) async => null);
        when(mockLocalDataSource.updateLastSuccessfulSync(any))
            .thenAnswer((_) async {});

        final result = await syncOrchestrator.performFullSync();

        expect(result.success, true);
        expect(syncOrchestrator.currentStatus, SyncStatus.completed);
        expect(syncOrchestrator.lastSyncResult, isNotNull);
        
        verify(mockLocalDataSource.updateLastSuccessfulSync(any)).called(1);
      });

      test('should handle failure in outbound phase of full sync', () async {
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.failure(StorageError(message: 'Storage error')));

        final result = await syncOrchestrator.performFullSync();

        expect(result.success, false);
        expect(result.errorMessage, contains('Storage error'));
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });
    });

    group('Sync Cancellation', () {
      test('should cancel sync operation', () async {
        // Start a long-running sync operation
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async {
              // Simulate delay
              await Future.delayed(const Duration(milliseconds: 100));
              return const Result.success(MutationQueueStats(
                totalPending: 0,
                readyToProcess: 0,
                byEntityType: {},
              ));
            });

        // Start sync and immediately cancel
        final syncFuture = syncOrchestrator.performFullSync();
        await syncOrchestrator.cancelSync();
        
        expect(syncOrchestrator.currentStatus, SyncStatus.cancelled);
        expect(syncOrchestrator.isSyncing, false);
      });
    });

    group('Concurrent Sync Prevention', () {
      test('should prevent concurrent sync operations', () async {
        // Setup first sync to take some time
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return const Result.success(MutationQueueStats(
                totalPending: 0,
                readyToProcess: 0,
                byEntityType: {},
              ));
            });

        when(mockLocalDataSource.getSyncMetadata()).thenAnswer((_) async => null);
        when(mockLocalDataSource.updateLastSuccessfulSync(any)).thenAnswer((_) async {});

        // Mock inbound calls
        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));
        when(mockRemoteDataSource.pullCategoryDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullAccountDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullBudgetDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));

        // Start first sync
        final firstSync = syncOrchestrator.performFullSync();
        
        // Attempt second sync immediately
        final secondSync = syncOrchestrator.performFullSync();

        final results = await Future.wait([firstSync, secondSync]);
        
        // First sync should succeed, second should fail due to concurrent access
        expect(results[0].success, true);
        expect(results[1].success, false);
        expect(results[1].errorMessage, contains('already in progress'));
      });
    });

    group('Status Updates', () {
      test('should emit status updates during sync operation', () async {
        final statusUpdates = <SyncStatus>[];
        
        // Listen to status updates
        final subscription = syncOrchestrator.syncProgress.listen((progress) {
          statusUpdates.add(progress.status);
        });

        // Setup simple sync
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.success(MutationQueueStats(
              totalPending: 0,
              readyToProcess: 0,
              byEntityType: {},
            )));

        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));
        when(mockRemoteDataSource.pullCategoryDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullAccountDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullBudgetDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));

        when(mockLocalDataSource.getSyncMetadata()).thenAnswer((_) async => null);
        when(mockLocalDataSource.updateLastSuccessfulSync(any)).thenAnswer((_) async {});

        await syncOrchestrator.performFullSync();
        
        // Should have received status updates
        expect(statusUpdates, isNotEmpty);
        expect(statusUpdates, contains(SyncStatus.preparing));
        expect(statusUpdates, contains(SyncStatus.syncingOutbound));
        expect(statusUpdates, contains(SyncStatus.syncingInbound));
        expect(statusUpdates, contains(SyncStatus.finalizing));
        expect(statusUpdates, contains(SyncStatus.completed));
        
        await subscription.cancel();
      });
    });

    group('Full Resync', () {
      test('should perform full resync by clearing cursors', () async {
        // Setup mocks
        when(mockLocalDataSource.clearAllSyncCursors()).thenAnswer((_) async {});
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.success(MutationQueueStats(
              totalPending: 0,
              readyToProcess: 0,
              byEntityType: {},
            )));

        when(mockRemoteDataSource.pullExpenseDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));
        when(mockRemoteDataSource.pullCategoryDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullAccountDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));
        when(mockRemoteDataSource.pullBudgetDeltas(userId: anyNamed('userId'), lastSyncAt: any))
            .thenAnswer((_) async => const Result.success([]));

        when(mockLocalDataSource.getSyncMetadata()).thenAnswer((_) async => null);
        when(mockLocalDataSource.updateLastSuccessfulSync(any)).thenAnswer((_) async {});

        final result = await syncOrchestrator.performFullResync();

        expect(result.success, true);
        verify(mockLocalDataSource.clearAllSyncCursors()).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle unexpected errors gracefully', () async {
        when(mockMutationQueueService.getQueueStats())
            .thenThrow(Exception('Unexpected error'));

        final result = await syncOrchestrator.performOutboundSync();

        expect(result.success, false);
        expect(result.errorMessage, contains('Unexpected error'));
        expect(syncOrchestrator.currentStatus, SyncStatus.error);
      });

      test('should preserve error details in sync result', () async {
        const errorMessage = 'Specific sync error';
        when(mockMutationQueueService.getQueueStats())
            .thenAnswer((_) async => const Result.failure(SyncOperationError(message: errorMessage)));

        final result = await syncOrchestrator.performOutboundSync();

        expect(result.success, false);
        expect(result.errorMessage, contains(errorMessage));
        expect(result.startTime, isNotNull);
        expect(result.endTime, isNotNull);
        expect(result.duration, isA<Duration>());
      });
    });
  });
}