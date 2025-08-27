import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:expense_tracker/core/data/repositories/sync_repository_impl.dart';
import 'package:expense_tracker/core/data/repositories/sync_repository.dart';
import 'package:expense_tracker/core/data/datasources/local_data_source.dart';
import 'package:expense_tracker/core/data/datasources/remote_data_source.dart';
import 'package:expense_tracker/core/data/services/mutation_queue_service.dart';
import 'package:expense_tracker/core/data/mappers/sync_mapper.dart';
import 'package:expense_tracker/core/data/entities/sync_metadata.dart';
import 'package:expense_tracker/core/data/entities/mutation_queue_item.dart';
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';
import 'package:expense_tracker/core/domain/entities/sync_category.dart';
import 'package:expense_tracker/core/domain/entities/sync_account.dart';
import 'package:expense_tracker/core/domain/entities/sync_budget.dart';
import 'package:expense_tracker/core/domain/base_entity.dart';
import 'package:expense_tracker/core/domain/result.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';
import 'package:expense_tracker/core/data/dtos/category_dto.dart';
import 'package:expense_tracker/core/data/dtos/account_dto.dart';
import 'package:expense_tracker/core/data/dtos/budget_dto.dart';

import 'sync_repository_test.mocks.dart';

@GenerateMocks([
  LocalDataSource,
  RemoteDataSource,
  MutationQueueService,
  SyncMapper,
])
void main() {
  late SyncRepositoryImpl syncRepository;
  late MockLocalDataSource mockLocalDataSource;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockMutationQueueService mockMutationQueueService;
  late MockSyncMapper mockSyncMapper;

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockRemoteDataSource = MockRemoteDataSource();
    mockMutationQueueService = MockMutationQueueService();
    mockSyncMapper = MockSyncMapper();

    syncRepository = SyncRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      mutationQueueService: mockMutationQueueService,
      syncMapper: mockSyncMapper,
    );
  });

  group('SyncRepositoryImpl', () {
    group('Conflict Resolution Strategy', () {
      test('should return lastWriteWins strategy', () {
        expect(syncRepository.conflictResolutionStrategy, 
               ConflictResolutionStrategy.lastWriteWins);
      });
    });

    group('LWW Conflict Resolution', () {
      test('should resolve conflict with newer version wins', () async {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 2),
        );

        // Act
        final result = await syncRepository.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense));
        expect(result.version, equals(2));
      });

      test('should resolve conflict with same version but newer timestamp wins', () async {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 2),
        );

        // Act
        final result = await syncRepository.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense));
      });

      test('should prefer server on exact ties', () async {
        // Arrange
        final timestamp = DateTime.utc(2023, 1, 1);
        
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: timestamp,
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: timestamp,
        );

        // Act
        final result = await syncRepository.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense)); // Server wins ties
      });

      test('should keep local when local is newer', () async {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 2),
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
        );

        // Act
        final result = await syncRepository.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(localExpense));
      });

      test('should throw error for non-BaseEntity types', () async {
        // Act & Assert
        expect(
          () => syncRepository.resolveConflict('local', 'remote'),
          throwsArgumentError,
        );
      });
    });

    group('Expense Sync Operations', () {
      test('pushExpenseChanges should push changes and return server entities', () async {
        // Arrange
        final expenses = [_createTestExpense(id: 'test-1')];
        final expenseDtos = [_createTestExpenseDto(id: 'test-1')];
        final serverDtos = [_createTestExpenseDto(id: 'test-1', version: 2)];
        final serverExpenses = [_createTestExpense(id: 'test-1', version: 2)];

        when(mockSyncMapper.expenseToDto(any)).thenReturn(expenseDtos.first);
        when(mockRemoteDataSource.batchUpsertExpenses(expenseDtos))
            .thenAnswer((_) async => Result.success(serverDtos));
        when(mockSyncMapper.dtoToExpense(any)).thenReturn(serverExpenses.first);

        // Act
        final result = await syncRepository.pushExpenseChanges(expenses);

        // Assert
        expect(result, equals(serverExpenses));
        verify(mockSyncMapper.expenseToDto(expenses.first)).called(1);
        verify(mockRemoteDataSource.batchUpsertExpenses(expenseDtos)).called(1);
        verify(mockSyncMapper.dtoToExpense(serverDtos.first)).called(1);
      });

      test('pushExpenseChanges should handle remote errors', () async {
        // Arrange
        final expenses = [_createTestExpense(id: 'test-1')];
        final expenseDtos = [_createTestExpenseDto(id: 'test-1')];
        
        when(mockSyncMapper.expenseToDto(any)).thenReturn(expenseDtos.first);
        when(mockRemoteDataSource.batchUpsertExpenses(expenseDtos))
            .thenAnswer((_) async => Result.failure(NetworkError('Connection failed')));

        // Act & Assert
        expect(
          () => syncRepository.pushExpenseChanges(expenses),
          throwsException,
        );
      });

      test('pullExpenseChanges should pull and merge remote changes', () async {
        // Arrange
        final lastSync = DateTime.utc(2023, 1, 1);
        final metadata = SyncMetadata(
          entityType: 'expenses',
          lastSyncAt: lastSync,
          version: 1,
        );
        final remoteDtos = [_createTestExpenseDto(id: 'test-1', version: 2)];
        final remoteExpenses = [_createTestExpense(id: 'test-1', version: 2)];
        final localExpense = _createTestExpense(id: 'test-1', version: 1);

        when(mockLocalDataSource.getSyncMetadata('expenses'))
            .thenAnswer((_) async => metadata);
        when(mockRemoteDataSource.pullExpenseDeltas(cursor: lastSync))
            .thenAnswer((_) async => Result.success(remoteDtos));
        when(mockSyncMapper.dtoToExpense(any)).thenReturn(remoteExpenses.first);
        when(mockLocalDataSource.getExpenseById('test-1'))
            .thenAnswer((_) async => localExpense);
        when(mockLocalDataSource.insertOrUpdateExpense(any))
            .thenAnswer((_) async {});

        // Act
        final result = await syncRepository.pullExpenseChanges(lastSync: lastSync);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.version, equals(2)); // Remote wins (newer version)
        verify(mockLocalDataSource.insertOrUpdateExpense(any)).called(1);
      });

      test('syncExpenses should perform full bidirectional sync', () async {
        // Arrange
        final lastSync = DateTime.utc(2023, 1, 1);
        final pendingMutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expenses',
            entityId: 'exp-1',
            operation: MutationOperation.upsert,
            priority: 0,
            createdAt: DateTime.now().toUtc(),
            attemptCount: 0,
            data: {},
          ),
        ];
        final localExpense = _createTestExpense(id: 'exp-1');
        final serverExpenses = [_createTestExpense(id: 'exp-1', version: 2)];

        // Mock local changes to push
        when(mockLocalDataSource.getPendingMutations())
            .thenAnswer((_) async => pendingMutations);
        when(mockLocalDataSource.getExpenseById('exp-1'))
            .thenAnswer((_) async => localExpense);

        // Mock push operation
        when(mockSyncMapper.expenseToDto(any)).thenReturn(_createTestExpenseDto());
        when(mockRemoteDataSource.batchUpsertExpenses(any))
            .thenAnswer((_) async => Result.success([_createTestExpenseDto(version: 2)]));
        when(mockSyncMapper.dtoToExpense(any)).thenReturn(serverExpenses.first);

        // Mock pull operation
        when(mockLocalDataSource.getSyncMetadata('expenses'))
            .thenAnswer((_) async => null);
        when(mockRemoteDataSource.pullExpenseDeltas(cursor: lastSync))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));

        // Mock cursor update
        when(mockLocalDataSource.updateSyncCursor('expenses', any))
            .thenAnswer((_) async {});

        // Act
        final result = await syncRepository.syncExpenses(lastSync: lastSync);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.pushedToRemote, hasLength(1));
        expect(result.errors, isEmpty);
        verify(mockLocalDataSource.updateSyncCursor('expenses', any)).called(1);
      });
    });

    group('Full Sync Operation', () {
      test('performFullSync should sync all entity types concurrently', () async {
        // Arrange
        final lastSync = DateTime.utc(2023, 1, 1);
        
        // Mock empty results for all entity types
        _mockEmptyPendingMutations();
        _mockEmptyRemoteDeltas();
        _mockCursorUpdates();

        // Act
        final result = await syncRepository.performFullSync(lastSync: lastSync);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.totalSynced, equals(0));
        expect(result.allErrors, isEmpty);
        
        // Verify all entity types were synced
        verify(mockLocalDataSource.updateSyncCursor('expenses', any)).called(1);
        verify(mockLocalDataSource.updateSyncCursor('categories', any)).called(1);
        verify(mockLocalDataSource.updateSyncCursor('accounts', any)).called(1);
        verify(mockLocalDataSource.updateSyncCursor('budgets', any)).called(1);
      });
    });

    group('Sync Timestamp Management', () {
      test('getLastSyncTimestamp should return global sync timestamp', () async {
        // Arrange
        final timestamp = DateTime.utc(2023, 1, 1);
        final metadata = SyncMetadata(
          entityType: '_global',
          lastSyncAt: timestamp,
          version: 1,
        );
        
        when(mockLocalDataSource.getSyncMetadata('_global'))
            .thenAnswer((_) async => metadata);

        // Act
        final result = await syncRepository.getLastSyncTimestamp();

        // Assert
        expect(result, equals(timestamp));
      });

      test('updateLastSyncTimestamp should update global sync cursor', () async {
        // Arrange
        final timestamp = DateTime.utc(2023, 1, 1);
        
        when(mockLocalDataSource.updateSyncCursor('_global', timestamp))
            .thenAnswer((_) async {});

        // Act
        await syncRepository.updateLastSyncTimestamp(timestamp);

        // Assert
        verify(mockLocalDataSource.updateSyncCursor('_global', timestamp)).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle push errors gracefully in syncExpenses', () async {
        // Arrange
        final pendingMutations = [
          MutationQueueItem(
            id: 'mut-1',
            entityType: 'expenses',
            entityId: 'exp-1',
            operation: MutationOperation.upsert,
            priority: 0,
            createdAt: DateTime.now().toUtc(),
            attemptCount: 0,
            data: {},
          ),
        ];
        final localExpense = _createTestExpense(id: 'exp-1');

        when(mockLocalDataSource.getPendingMutations())
            .thenAnswer((_) async => pendingMutations);
        when(mockLocalDataSource.getExpenseById('exp-1'))
            .thenAnswer((_) async => localExpense);
        when(mockSyncMapper.expenseToDto(any)).thenReturn(_createTestExpenseDto());
        when(mockRemoteDataSource.batchUpsertExpenses(any))
            .thenAnswer((_) async => Result.failure(NetworkError('Push failed')));

        // Mock successful pull
        when(mockLocalDataSource.getSyncMetadata('expenses'))
            .thenAnswer((_) async => null);
        when(mockRemoteDataSource.pullExpenseDeltas(cursor: null))
            .thenAnswer((_) async => const Result.success(<ExpenseDto>[]));

        // Act
        final result = await syncRepository.syncExpenses();

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.operation, equals(SyncOperation.push));
        expect(result.pushedToRemote, isEmpty);
      });

      test('should handle pull errors gracefully in syncExpenses', () async {
        // Arrange
        when(mockLocalDataSource.getPendingMutations())
            .thenAnswer((_) async => <MutationQueueItem>[]);
        when(mockLocalDataSource.getSyncMetadata('expenses'))
            .thenAnswer((_) async => null);
        when(mockRemoteDataSource.pullExpenseDeltas(cursor: null))
            .thenAnswer((_) async => Result.failure(NetworkError('Pull failed')));

        // Act
        final result = await syncRepository.syncExpenses();

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.operation, equals(SyncOperation.pull));
        expect(result.pulledFromRemote, isEmpty);
      });
    });
  });
}

// Helper methods for creating test data
SyncExpense _createTestExpense({
  String? id,
  int version = 1,
  DateTime? updatedAt,
}) {
  return SyncExpense(
    id: id ?? EntityUtils.generateId(),
    createdAt: DateTime.utc(2023, 1, 1),
    updatedAt: updatedAt ?? DateTime.utc(2023, 1, 1),
    version: version,
    isDeleted: false,
    deviceId: 'test-device',
    lastEditor: 'test-user',
    amount: 100.0,
    description: 'Test expense',
    categoryId: 'cat-1',
    accountId: 'acc-1',
    date: DateTime.utc(2023, 1, 1),
  );
}

ExpenseDto _createTestExpenseDto({
  String? id,
  int version = 1,
  DateTime? updatedAt,
}) {
  return ExpenseDto(
    id: id ?? EntityUtils.generateId(),
    createdAt: DateTime.utc(2023, 1, 1),
    updatedAt: updatedAt ?? DateTime.utc(2023, 1, 1),
    version: version,
    isDeleted: false,
    deviceId: 'test-device',
    lastEditor: 'test-user',
    amount: 100.0,
    description: 'Test expense',
    categoryId: 'cat-1',
    accountId: 'acc-1',
    date: DateTime.utc(2023, 1, 1),
    userId: 'user-1',
  );
}

// Helper methods for mocking common scenarios
extension SyncRepositoryTestHelpers on MockLocalDataSource {
  void mockEmptyPendingMutations() {
    when(getPendingMutations())
        .thenAnswer((_) async => <MutationQueueItem>[]);
  }

  void mockCursorUpdates() {
    when(updateSyncCursor(any, any)).thenAnswer((_) async {});
    when(getSyncMetadata(any)).thenAnswer((_) async => null);
  }
}

extension RemoteDataSourceTestHelpers on MockRemoteDataSource {
  void mockEmptyRemoteDeltas() {
    when(pullExpenseDeltas(cursor: any)).thenAnswer(
      (_) async => const Result.success(<ExpenseDto>[]),
    );
    when(pullCategoryDeltas(cursor: any)).thenAnswer(
      (_) async => const Result.success(<CategoryDto>[]),
    );
    when(pullAccountDeltas(cursor: any)).thenAnswer(
      (_) async => const Result.success(<AccountDto>[]),
    );
    when(pullBudgetDeltas(cursor: any)).thenAnswer(
      (_) async => const Result.success(<BudgetDto>[]),
    );
  }
}

void _mockEmptyPendingMutations() {
  // This would be used in the main test setup
}

void _mockEmptyRemoteDeltas() {
  // This would be used in the main test setup
}

void _mockCursorUpdates() {
  // This would be used in the main test setup
}