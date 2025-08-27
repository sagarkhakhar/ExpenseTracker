import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../lib/core/data/datasources/local_data_source_impl.dart';
import '../../../../lib/core/data/entities/sync_metadata.dart';
import '../../../../lib/core/data/entities/mutation_queue_item.dart';

void main() {
  group('LocalDataSourceImpl', () {
    late LocalDataSourceImpl dataSource;

    setUpAll(() async {
      // Initialize Hive for tests with in-memory storage
      Hive.init('.');
      
      // Register adapters
      if (!Hive.isAdapterRegistered(100)) {
        Hive.registerAdapter(SyncMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(101)) {
        Hive.registerAdapter(MutationQueueItemAdapter());
      }
      if (!Hive.isAdapterRegistered(102)) {
        Hive.registerAdapter(MutationTypeAdapter());
      }
    });

    setUp(() async {
      dataSource = LocalDataSourceImpl();
      await dataSource.init();
    });

    tearDown(() async {
      await dataSource.clearAllSyncMetadata();
      await dataSource.clearMutationQueue();
      await dataSource.close();
    });

    group('Sync Metadata Operations', () {
      test('should set and get sync metadata', () async {
        // Arrange
        final metadata = SyncMetadata(
          entityType: 'expenses',
          lastPullCursor: DateTime.now(),
          syncVersion: 1,
        );

        // Act
        await dataSource.setSyncMetadata(metadata);
        final result = await dataSource.getSyncMetadata('expenses');

        // Assert
        expect(result, isNotNull);
        expect(result!.entityType, equals('expenses'));
        expect(result.syncVersion, equals(1));
      });

      test('should return null for non-existent sync metadata', () async {
        // Act
        final result = await dataSource.getSyncMetadata('non_existent');

        // Assert
        expect(result, isNull);
      });

      test('should update last pull cursor', () async {
        // Arrange
        const entityType = 'expenses';
        final cursor = DateTime.now();

        // Act
        await dataSource.updateLastPullCursor(entityType, cursor);
        final result = await dataSource.getSyncMetadata(entityType);

        // Assert
        expect(result, isNotNull);
        expect(result!.lastPullCursor, equals(cursor));
        expect(result.entityType, equals(entityType));
      });

      test('should update last successful sync', () async {
        // Arrange
        const entityType = 'expenses';
        final timestamp = DateTime.now();

        // Act
        await dataSource.updateLastSuccessfulSync(entityType, timestamp);
        final result = await dataSource.getSyncMetadata(entityType);

        // Assert
        expect(result, isNotNull);
        expect(result!.lastSuccessfulSync, equals(timestamp));
        expect(result.syncVersion, equals(1));
      });

      test('should clear specific sync metadata', () async {
        // Arrange
        final metadata1 = SyncMetadata(entityType: 'expenses', syncVersion: 1);
        final metadata2 = SyncMetadata(entityType: 'categories', syncVersion: 1);
        await dataSource.setSyncMetadata(metadata1);
        await dataSource.setSyncMetadata(metadata2);

        // Act
        await dataSource.clearSyncMetadata('expenses');

        // Assert
        final result1 = await dataSource.getSyncMetadata('expenses');
        final result2 = await dataSource.getSyncMetadata('categories');
        expect(result1, isNull);
        expect(result2, isNotNull);
      });

      test('should clear all sync metadata', () async {
        // Arrange
        final metadata1 = SyncMetadata(entityType: 'expenses', syncVersion: 1);
        final metadata2 = SyncMetadata(entityType: 'categories', syncVersion: 1);
        await dataSource.setSyncMetadata(metadata1);
        await dataSource.setSyncMetadata(metadata2);

        // Act
        await dataSource.clearAllSyncMetadata();

        // Assert
        final result1 = await dataSource.getSyncMetadata('expenses');
        final result2 = await dataSource.getSyncMetadata('categories');
        expect(result1, isNull);
        expect(result2, isNull);
      });
    });

    group('Mutation Queue Operations', () {
      test('should enqueue and get pending mutations', () async {
        // Arrange
        final mutation = MutationQueueItem(
          id: 'test-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {'amount': 100.0},
          createdAt: DateTime.now(),
        );

        // Act
        await dataSource.enqueueOperation(mutation);
        final mutations = await dataSource.getPendingMutations();

        // Assert
        expect(mutations, hasLength(1));
        expect(mutations.first.id, equals('test-id'));
        expect(mutations.first.operation, equals(MutationType.create));
      });

      test('should get pending mutations for specific entity', () async {
        // Arrange
        final expenseMutation = MutationQueueItem(
          id: 'expense-mutation',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {'amount': 100.0},
          createdAt: DateTime.now(),
        );
        final categoryMutation = MutationQueueItem(
          id: 'category-mutation',
          entityType: 'categories',
          entityId: 'category-1',
          operation: MutationType.update,
          data: {'name': 'Food'},
          createdAt: DateTime.now(),
        );

        await dataSource.enqueueOperation(expenseMutation);
        await dataSource.enqueueOperation(categoryMutation);

        // Act
        final expenseMutations = await dataSource.getPendingMutationsForEntity('expenses');

        // Assert
        expect(expenseMutations, hasLength(1));
        expect(expenseMutations.first.entityType, equals('expenses'));
      });

      test('should sort mutations by priority and creation time', () async {
        // Arrange
        final now = DateTime.now();
        final mutation1 = MutationQueueItem(
          id: 'low-priority-old',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: now.subtract(const Duration(minutes: 10)),
          priority: 0,
        );
        final mutation2 = MutationQueueItem(
          id: 'high-priority-new',
          entityType: 'expenses',
          entityId: 'expense-2',
          operation: MutationType.create,
          data: {},
          createdAt: now,
          priority: 10,
        );
        final mutation3 = MutationQueueItem(
          id: 'low-priority-new',
          entityType: 'expenses',
          entityId: 'expense-3',
          operation: MutationType.create,
          data: {},
          createdAt: now,
          priority: 0,
        );

        await dataSource.enqueueOperation(mutation1);
        await dataSource.enqueueOperation(mutation2);
        await dataSource.enqueueOperation(mutation3);

        // Act
        final mutations = await dataSource.getPendingMutations();

        // Assert
        expect(mutations, hasLength(3));
        // Should be ordered: high priority first, then by creation time (older first)
        expect(mutations[0].id, equals('high-priority-new'));
        expect(mutations[1].id, equals('low-priority-old'));
        expect(mutations[2].id, equals('low-priority-new'));
      });

      test('should dequeue single mutation', () async {
        // Arrange
        final mutation = MutationQueueItem(
          id: 'test-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {'amount': 100.0},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(mutation);

        // Act
        await dataSource.dequeueMutation('test-id');
        final mutations = await dataSource.getPendingMutations();

        // Assert
        expect(mutations, isEmpty);
      });

      test('should dequeue multiple mutations', () async {
        // Arrange
        final mutation1 = MutationQueueItem(
          id: 'id1',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        final mutation2 = MutationQueueItem(
          id: 'id2',
          entityType: 'expenses',
          entityId: 'expense-2',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(mutation1);
        await dataSource.enqueueOperation(mutation2);

        // Act
        await dataSource.dequeueMutations(['id1', 'id2']);
        final mutations = await dataSource.getPendingMutations();

        // Assert
        expect(mutations, isEmpty);
      });

      test('should increment retry count', () async {
        // Arrange
        final mutation = MutationQueueItem(
          id: 'test-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(mutation);

        // Act
        await dataSource.incrementRetryCount('test-id');
        final mutations = await dataSource.getPendingMutations();

        // Assert
        expect(mutations.first.retryCount, equals(1));
      });

      test('should get pending mutation count', () async {
        // Arrange
        final mutation1 = MutationQueueItem(
          id: 'id1',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        final mutation2 = MutationQueueItem(
          id: 'id2',
          entityType: 'expenses',
          entityId: 'expense-2',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(mutation1);
        await dataSource.enqueueOperation(mutation2);

        // Act
        final count = await dataSource.getPendingMutationCount();

        // Assert
        expect(count, equals(2));
      });

      test('should get pending mutation count for entity', () async {
        // Arrange
        final expenseMutation = MutationQueueItem(
          id: 'expense-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        final categoryMutation = MutationQueueItem(
          id: 'category-id',
          entityType: 'categories',
          entityId: 'category-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(expenseMutation);
        await dataSource.enqueueOperation(categoryMutation);

        // Act
        final count = await dataSource.getPendingMutationCountForEntity('expenses');

        // Assert
        expect(count, equals(1));
      });

      test('should schedule mutation for future processing', () async {
        // Arrange
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 1));
        final mutation = MutationQueueItem(
          id: 'scheduled-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: now,
        );
        await dataSource.enqueueOperation(mutation);

        // Act
        await dataSource.scheduleMutation('scheduled-id', future);
        final readyMutations = await dataSource.getReadyMutations();

        // Assert - should not be ready now
        expect(readyMutations, isEmpty);
      });

      test('should clear mutations for specific entity type', () async {
        // Arrange
        final expenseMutation = MutationQueueItem(
          id: 'expense-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        final categoryMutation = MutationQueueItem(
          id: 'category-id',
          entityType: 'categories',
          entityId: 'category-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.enqueueOperation(expenseMutation);
        await dataSource.enqueueOperation(categoryMutation);

        // Act
        await dataSource.clearMutationsForEntity('expenses');

        // Assert
        final expenseCount = await dataSource.getPendingMutationCountForEntity('expenses');
        final categoryCount = await dataSource.getPendingMutationCountForEntity('categories');
        expect(expenseCount, equals(0));
        expect(categoryCount, equals(1));
      });
    });

    group('Utility Operations', () {
      test('should get storage stats', () async {
        // Arrange
        final metadata = SyncMetadata(entityType: 'expenses', syncVersion: 1);
        final mutation = MutationQueueItem(
          id: 'test-id',
          entityType: 'expenses',
          entityId: 'expense-1',
          operation: MutationType.create,
          data: {},
          createdAt: DateTime.now(),
        );
        await dataSource.setSyncMetadata(metadata);
        await dataSource.enqueueOperation(mutation);

        // Act
        final stats = await dataSource.getStorageStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['syncMetadata']['count'], equals(1));
        expect(stats['mutationQueue']['count'], equals(1));
        expect(stats['mutationQueue']['pendingCount'], equals(1));
      });

      test('should validate data integrity', () async {
        // Act
        final isValid = await dataSource.validateDataIntegrity();

        // Assert
        expect(isValid, isTrue);
      });

      test('should perform cleanup without errors', () async {
        // Act & Assert - should not throw
        await expectLater(
          dataSource.performCleanup(),
          completes,
        );
      });
    });
  });
}