import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/core/data/repositories/lww_conflict_resolver.dart';
import '../../../../lib/core/data/repositories/sync_repository.dart';
import '../../../../lib/core/domain/entities/sync_expense.dart';
import '../../../../lib/core/domain/base_entity.dart';
import '../../../../lib/features/expense/domain/entities/expense.dart';

void main() {
  late LWWConflictResolver conflictResolver;

  setUp(() {
    conflictResolver = LWWConflictResolver();
  });

  group('LWWConflictResolver', () {
    group('resolveConflict', () {
      test('should resolve conflict with higher version wins', () {
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
        final result = conflictResolver.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense));
        expect(result.version, equals(2));
      });

      test('should resolve conflict with same version but newer timestamp wins', () {
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
        final result = conflictResolver.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense));
        expect(result.updatedAt, equals(DateTime.utc(2023, 1, 2)));
      });

      test('should prefer server (remote) on exact ties', () {
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
        final result = conflictResolver.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(remoteExpense)); // Server wins ties
      });

      test('should keep local when local has higher version', () {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 1),
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 2),
        );

        // Act
        final result = conflictResolver.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(localExpense));
        expect(result.version, equals(2));
      });

      test('should keep local when same version but local timestamp is newer', () {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 2),
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
        );

        // Act
        final result = conflictResolver.resolveConflict(localExpense, remoteExpense);

        // Assert
        expect(result, equals(localExpense));
        expect(result.updatedAt, equals(DateTime.utc(2023, 1, 2)));
      });
    });

    group('tombstone handling', () {
      test('should apply remote tombstone when local is not deleted', () {
        // Arrange
        final localExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
          isDeleted: false,
        );
        
        final remoteTombstone = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 2),
          isDeleted: true,
        );

        // Act
        final result = conflictResolver.resolveConflict(localExpense, remoteTombstone);

        // Assert
        expect(result, equals(remoteTombstone));
        expect(result.isDeleted, isTrue);
      });

      test('should keep local tombstone when it is newer than remote entity', () {
        // Arrange
        final localTombstone = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 2),
          isDeleted: true,
        );
        
        final remoteExpense = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
          isDeleted: false,
        );

        // Act
        final result = conflictResolver.resolveConflict(localTombstone, remoteExpense);

        // Assert
        expect(result, equals(localTombstone));
        expect(result.isDeleted, isTrue);
      });

      test('should apply LWW to both tombstones', () {
        // Arrange
        final localTombstone = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
          isDeleted: true,
        );
        
        final remoteTombstone = _createTestExpense(
          id: 'test-id',
          version: 2,
          updatedAt: DateTime.utc(2023, 1, 2),
          isDeleted: true,
        );

        // Act
        final result = conflictResolver.resolveConflict(localTombstone, remoteTombstone);

        // Assert
        expect(result, equals(remoteTombstone));
        expect(result.version, equals(2));
        expect(result.isDeleted, isTrue);
      });
    });

    group('hasConflict', () {
      test('should detect conflict when versions differ', () {
        // Arrange
        final local = _createTestExpense(id: 'test-id', version: 1);
        final remote = _createTestExpense(id: 'test-id', version: 2);

        // Act & Assert
        expect(conflictResolver.hasConflict(local, remote), isTrue);
      });

      test('should detect conflict when timestamps differ', () {
        // Arrange
        final local = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 1),
        );
        final remote = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: DateTime.utc(2023, 1, 2),
        );

        // Act & Assert
        expect(conflictResolver.hasConflict(local, remote), isTrue);
      });

      test('should not detect conflict when entities are identical', () {
        // Arrange
        final timestamp = DateTime.utc(2023, 1, 1);
        final local = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: timestamp,
        );
        final remote = _createTestExpense(
          id: 'test-id',
          version: 1,
          updatedAt: timestamp,
        );

        // Act & Assert
        expect(conflictResolver.hasConflict(local, remote), isFalse);
      });
    });

    group('shouldSync', () {
      test('should sync all entities when no lastSyncTime provided', () {
        // Arrange
        final entity = _createTestExpense(updatedAt: DateTime.utc(2023, 1, 1));

        // Act & Assert
        expect(conflictResolver.shouldSync(entity), isTrue);
      });

      test('should sync entity modified after last sync', () {
        // Arrange
        final lastSync = DateTime.utc(2023, 1, 1);
        final entity = _createTestExpense(updatedAt: DateTime.utc(2023, 1, 2));

        // Act & Assert
        expect(conflictResolver.shouldSync(entity, lastSyncTime: lastSync), isTrue);
      });

      test('should not sync entity modified before last sync', () {
        // Arrange
        final lastSync = DateTime.utc(2023, 1, 2);
        final entity = _createTestExpense(updatedAt: DateTime.utc(2023, 1, 1));

        // Act & Assert
        expect(conflictResolver.shouldSync(entity, lastSyncTime: lastSync), isFalse);
      });
    });

    group('sortBySyncPriority', () {
      test('should sort by priority (higher first) then by creation time', () {
        // Arrange
        final entities = [
          _createTestExpense(id: '1', createdAt: DateTime.utc(2023, 1, 3), syncPriority: 0),
          _createTestExpense(id: '2', createdAt: DateTime.utc(2023, 1, 1), syncPriority: 1),
          _createTestExpense(id: '3', createdAt: DateTime.utc(2023, 1, 2), syncPriority: 0),
          _createTestExpense(id: '4', createdAt: DateTime.utc(2023, 1, 4), syncPriority: 2),
        ];

        // Act
        final sorted = conflictResolver.sortBySyncPriority(entities);

        // Assert
        expect(sorted.map((e) => e.id).toList(), equals(['4', '2', '3', '1']));
      });
    });

    group('filterOldTombstones', () {
      test('should remove old tombstones but keep recent ones and all non-tombstones', () {
        // Arrange
        final now = DateTime.now().toUtc();
        final oldDate = now.subtract(Duration(days: 60));
        final recentDate = now.subtract(Duration(days: 15));
        
        final entities = [
          _createTestExpense(id: '1', updatedAt: oldDate, isDeleted: true),    // Old tombstone - remove
          _createTestExpense(id: '2', updatedAt: recentDate, isDeleted: true), // Recent tombstone - keep
          _createTestExpense(id: '3', updatedAt: oldDate, isDeleted: false),   // Old entity - keep
          _createTestExpense(id: '4', updatedAt: recentDate, isDeleted: false), // Recent entity - keep
        ];

        // Act
        final filtered = conflictResolver.filterOldTombstones(entities);

        // Assert
        expect(filtered.length, equals(3));
        expect(filtered.map((e) => e.id).toList(), equals(['2', '3', '4']));
      });
    });

    group('createConflictRecord', () {
      test('should create proper conflict record', () {
        // Arrange
        final local = _createTestExpense(id: 'test-id', version: 1);
        final remote = _createTestExpense(id: 'test-id', version: 2);
        final resolved = remote;

        // Act
        final conflict = conflictResolver.createConflictRecord(local, remote, resolved);

        // Assert
        expect(conflict.entityId, equals('test-id'));
        expect(conflict.localEntity, equals(local));
        expect(conflict.remoteEntity, equals(remote));
        expect(conflict.resolvedEntity, equals(resolved));
        expect(conflict.resolutionStrategy, equals(ConflictResolutionStrategy.lastWriteWins));
      });
    });

    group('validateEntity', () {
      test('should pass validation for valid entity', () {
        // Arrange
        final entity = _createTestExpense();

        // Act & Assert
        expect(() => conflictResolver.validateEntity(entity), returnsNormally);
      });

      test('should throw error for empty ID', () {
        // Arrange
        final entity = _createTestExpense(id: '');

        // Act & Assert
        expect(() => conflictResolver.validateEntity(entity), throwsArgumentError);
      });

      test('should throw error for zero or negative version', () {
        // Arrange
        final entity = _createTestExpense(version: 0);

        // Act & Assert
        expect(() => conflictResolver.validateEntity(entity), throwsArgumentError);
      });

      test('should throw error for future timestamp', () {
        // Arrange
        final futureTime = DateTime.now().toUtc().add(Duration(hours: 1));
        final entity = _createTestExpense(updatedAt: futureTime);

        // Act & Assert
        expect(() => conflictResolver.validateEntity(entity), throwsArgumentError);
      });
    });
  });
}

// Helper method to create test expenses
SyncExpense _createTestExpense({
  String? id,
  int version = 1,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
  int syncPriority = 0,
}) {
  final now = DateTime.utc(2023, 1, 1);
  
  final expense = SyncExpense(
    id: id ?? EntityUtils.generateId(),
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    version: version,
    isDeleted: isDeleted,
    deviceId: 'test-device',
    lastEditor: 'test-user',
    // Required business fields
    title: 'Test Expense',
    description: 'Test expense description', 
    amount: 100.0,
    category: 'Test Category',
    type: ExpenseType.expense,
    date: now,
    categoryId: 'cat-1',
    accountId: 'acc-1',
  );
  
  // Return a test entity that can override syncPriority
  return _TestExpense.fromExpense(expense, syncPriority);
}

// Test entity that can override syncPriority
class _TestExpense extends SyncExpense {
  final int _syncPriority;
  
  _TestExpense.fromExpense(SyncExpense expense, this._syncPriority) : super(
    id: expense.id,
    createdAt: expense.createdAt,
    updatedAt: expense.updatedAt,
    version: expense.version,
    isDeleted: expense.isDeleted,
    deviceId: expense.deviceId,
    lastEditor: expense.lastEditor,
    title: expense.title,
    description: expense.description,
    amount: expense.amount,
    category: expense.category,
    type: expense.type,
    date: expense.date,
    categoryId: expense.categoryId,
    accountId: expense.accountId,
    metadata: expense.metadata,
    isRecurring: expense.isRecurring,
    recurringFrequency: expense.recurringFrequency,
    nextOccurrence: expense.nextOccurrence,
    endDate: expense.endDate,
    receiptPhotoId: expense.receiptPhotoId,
  );
  
  @override
  int get syncPriority => _syncPriority;
}