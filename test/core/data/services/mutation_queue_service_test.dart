import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../lib/core/data/services/mutation_queue_service.dart';
import '../../../../lib/core/data/entities/mutation_queue_item.dart';
import '../../../../lib/core/data/datasources/local_data_source.dart';
import '../../../../lib/core/data/datasources/remote_data_source.dart';
import '../../../../lib/core/domain/result.dart';
import '../../../../lib/core/domain/errors/sync_errors.dart';

class MockLocalDataSource extends Mock implements LocalDataSource {}
class MockRemoteDataSource extends Mock implements RemoteDataSource {}

void main() {
  late MutationQueueService service;
  late MockLocalDataSource mockLocalDataSource;
  late MockRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(MutationQueueItem(
      id: 'test-id',
      entityType: 'test-entity',
      entityId: 'test-entity-id',
      operation: MutationType.create,
      data: {},
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockRemoteDataSource = MockRemoteDataSource();
    service = MutationQueueService(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('MutationQueueService', () {
    group('enqueueOperation', () {
      test('should enqueue operation successfully', () async {
        // Arrange
        when(() => mockLocalDataSource.enqueueOperation(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.enqueueOperation(
          entityType: 'expense',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {'amount': 100.0, 'description': 'Test expense'},
        );

        // Assert
        expect(result.isSuccess, true);
        verify(() => mockLocalDataSource.enqueueOperation(any())).called(1);
      });

      test('should return error when enqueueing fails', () async {
        // Arrange
        when(() => mockLocalDataSource.enqueueOperation(any()))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await service.enqueueOperation(
          entityType: 'expense',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {'amount': 100.0},
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<StorageError>());
      });
    });

    group('processPendingMutations', () {
      test('should return empty result when no mutations pending', () async {
        // Arrange
        when(() => mockLocalDataSource.getReadyMutations(limit: any(named: 'limit')))
            .thenAnswer((_) async => []);

        // Act
        final result = await service.processPendingMutations();

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, 0);
        expect(batchResult.successful, 0);
        expect(batchResult.failed, 0);
        expect(batchResult.retries, 0);
      });

      test('should process expense mutations successfully', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expense',
            entityId: 'expense-1',
            operation: MutationType.create,
            data: {'id': 'expense-1', 'amount': 100.0, 'description': 'Test'},
            createdAt: DateTime.now().toUtc(),
          ),
          MutationQueueItem(
            id: 'mut-2',
            entityType: 'expense',
            entityId: 'expense-2',
            operation: MutationType.update,
            data: {'id': 'expense-2', 'amount': 200.0, 'description': 'Updated'},
            createdAt: DateTime.now().toUtc(),
          ),
        ];

        when(() => mockLocalDataSource.getReadyMutations(limit: any(named: 'limit')))
            .thenAnswer((_) async => mutations);

        when(() => mockRemoteDataSource.batchUpsertExpenses(any()))
            .thenAnswer((_) async => const Result.success(null));

        when(() => mockLocalDataSource.dequeueMutations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.processPendingMutations();

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, 2);
        expect(batchResult.successful, 2);
        expect(batchResult.failed, 0);
        expect(batchResult.retries, 0);

        verify(() => mockRemoteDataSource.batchUpsertExpenses(any())).called(1);
        verify(() => mockLocalDataSource.dequeueMutations(['mut-1', 'mut-2'])).called(1);
      });

      test('should handle mixed entity types in batch', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expense',
            entityId: 'expense-1',
            operation: MutationType.create,
            data: {'id': 'expense-1', 'amount': 100.0},
            createdAt: DateTime.now().toUtc(),
          ),
          MutationQueueItem(
            id: 'mut-2',
            entityType: 'category',
            entityId: 'category-1',
            operation: MutationType.create,
            data: {'id': 'category-1', 'name': 'Food'},
            createdAt: DateTime.now().toUtc(),
          ),
        ];

        when(() => mockLocalDataSource.getReadyMutations(limit: any(named: 'limit')))
            .thenAnswer((_) async => mutations);

        when(() => mockRemoteDataSource.batchUpsertExpenses(any()))
            .thenAnswer((_) async => const Result.success(null));
        when(() => mockRemoteDataSource.batchUpsertCategories(any()))
            .thenAnswer((_) async => const Result.success(null));

        when(() => mockLocalDataSource.dequeueMutations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.processPendingMutations();

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, 2);
        expect(batchResult.successful, 2);

        verify(() => mockRemoteDataSource.batchUpsertExpenses(any())).called(1);
        verify(() => mockRemoteDataSource.batchUpsertCategories(any())).called(1);
      });

      test('should handle network errors with retry', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expense',
            entityId: 'expense-1',
            operation: MutationType.create,
            data: {'id': 'expense-1', 'amount': 100.0},
            createdAt: DateTime.now().toUtc(),
            retryCount: 0,
          ),
        ];

        when(() => mockLocalDataSource.getReadyMutations(limit: any(named: 'limit')))
            .thenAnswer((_) async => mutations);

        when(() => mockRemoteDataSource.batchUpsertExpenses(any()))
            .thenAnswer((_) async => const Result.failure(NetworkError(message: 'Connection failed')));

        when(() => mockLocalDataSource.incrementRetryCount(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.scheduleMutation(any(), any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.getPendingMutations())
            .thenAnswer((_) async => mutations);

        // Act
        final result = await service.processPendingMutations();

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, 1);
        expect(batchResult.successful, 0);
        expect(batchResult.retries, 1);

        verify(() => mockLocalDataSource.incrementRetryCount('mut-1')).called(1);
        verify(() => mockLocalDataSource.scheduleMutation('mut-1', any())).called(1);
      });

      test('should respect batch size limit', () async {
        // Arrange
        const batchSize = 2;
        final mutations = List.generate(5, (i) => MutationQueueItem(
          id: 'mut-$i',
          entityType: 'expense',
          entityId: 'expense-$i',
          operation: MutationType.create,
          data: {'id': 'expense-$i', 'amount': 100.0 * i},
          createdAt: DateTime.now().toUtc(),
        ));

        when(() => mockLocalDataSource.getReadyMutations(limit: batchSize))
            .thenAnswer((_) async => mutations.take(batchSize).toList());

        when(() => mockRemoteDataSource.batchUpsertExpenses(any()))
            .thenAnswer((_) async => const Result.success(null));

        when(() => mockLocalDataSource.dequeueMutations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.processPendingMutations(batchSize: batchSize);

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, batchSize);
        expect(batchResult.successful, batchSize);

        verify(() => mockLocalDataSource.getReadyMutations(limit: batchSize)).called(1);
      });
    });

    group('processMutationsForEntity', () {
      test('should process mutations for specific entity type', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'category',
            entityId: 'category-1',
            operation: MutationType.create,
            data: {'id': 'category-1', 'name': 'Food'},
            createdAt: DateTime.now().toUtc(),
          ),
        ];

        when(() => mockLocalDataSource.getPendingMutationsForEntity(
          'category',
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => mutations);

        when(() => mockRemoteDataSource.batchUpsertCategories(any()))
            .thenAnswer((_) async => const Result.success(null));

        when(() => mockLocalDataSource.dequeueMutations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.processMutationsForEntity(
          entityType: 'category',
        );

        // Assert
        expect(result.isSuccess, true);
        final batchResult = result.data!;
        expect(batchResult.totalProcessed, 1);
        expect(batchResult.successful, 1);

        verify(() => mockRemoteDataSource.batchUpsertCategories(any())).called(1);
      });
    });

    group('getQueueStats', () {
      test('should return queue statistics', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expense',
            entityId: 'expense-1',
            operation: MutationType.create,
            data: {},
            createdAt: DateTime.now().toUtc(),
          ),
          MutationQueueItem(
            id: 'mut-2',
            entityType: 'category',
            entityId: 'category-1',
            operation: MutationType.create,
            data: {},
            createdAt: DateTime.now().toUtc(),
          ),
        ];

        when(() => mockLocalDataSource.getPendingMutationCount())
            .thenAnswer((_) async => 2);
        when(() => mockLocalDataSource.getReadyMutations())
            .thenAnswer((_) async => mutations);

        // Act
        final result = await service.getQueueStats();

        // Assert
        expect(result.isSuccess, true);
        final stats = result.data!;
        expect(stats.totalPending, 2);
        expect(stats.readyToProcess, 2);
        expect(stats.byEntityType['expense'], 1);
        expect(stats.byEntityType['category'], 1);
      });
    });

    group('clearFailedMutations', () {
      test('should clear mutations that exceeded retry limit', () async {
        // Arrange
        final mutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expense',
            entityId: 'expense-1',
            operation: MutationType.create,
            data: {},
            createdAt: DateTime.now().toUtc(),
            retryCount: 5, // Exceeded limit
          ),
          MutationQueueItem(
            id: 'mut-2',
            entityType: 'expense',
            entityId: 'expense-2',
            operation: MutationType.create,
            data: {},
            createdAt: DateTime.now().toUtc(),
            retryCount: 1, // Under limit
          ),
        ];

        when(() => mockLocalDataSource.getPendingMutations())
            .thenAnswer((_) async => mutations);
        when(() => mockLocalDataSource.dequeueMutations(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.clearFailedMutations();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 1); // One mutation cleared

        verify(() => mockLocalDataSource.dequeueMutations(['mut-1'])).called(1);
      });
    });
  });
}