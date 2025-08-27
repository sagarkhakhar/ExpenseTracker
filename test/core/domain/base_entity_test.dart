import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/domain/base_entity.dart';
import 'package:expense_tracker/core/domain/entities/expense_sync.dart';

void main() {
  group('BaseEntity', () {
    late SyncBaseEntity entity1;
    late SyncBaseEntity entity2;

    setUp(() {
      final now = DateTime.now().toUtc();
      entity1 = SyncBaseEntity(
        id: '1',
        createdAt: now,
        updatedAt: now,
        version: 1,
        deviceId: 'device1',
        lastEditor: 'user1',
      );
      
      entity2 = SyncBaseEntity(
        id: '2',
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
        version: 2,
        deviceId: 'device2',
        lastEditor: 'user2',
      );
    });

    test('should compare entities correctly for LWW', () {
      // Higher version should be newer
      expect(entity2.isNewerThan(entity1), isTrue);
      expect(entity1.isNewerThan(entity2), isFalse);
      
      // Same version, later timestamp should be newer
      final sameVersionEntity = SyncBaseEntity(
        id: '3',
        createdAt: entity1.createdAt,
        updatedAt: entity1.updatedAt.add(const Duration(seconds: 1)),
        version: 1,
        deviceId: 'device3',
        lastEditor: 'user3',
      );
      
      expect(sameVersionEntity.isNewerThan(entity1), isTrue);
    });

    test('should identify tombstones correctly', () {
      expect(entity1.isTombstone, isFalse);
      
      final tombstone = entity1.copyWithSyncMetadata(isDeleted: true);
      expect(tombstone.isTombstone, isTrue);
    });

    test('should create tombstone correctly', () {
      final tombstone = entity1.toTombstone(
        deviceId: 'device1',
        lastEditor: 'user1',
      );
      
      expect(tombstone.isDeleted, isTrue);
      expect(tombstone.version, equals(entity1.version + 1));
      expect(tombstone.deviceId, equals('device1'));
      expect(tombstone.lastEditor, equals('user1'));
    });

    test('should support copyWithSyncMetadata', () {
      final updated = entity1.copyWithSyncMetadata(
        version: 5,
        deviceId: 'newDevice',
        lastEditor: 'newUser',
      );
      
      expect(updated.version, equals(5));
      expect(updated.deviceId, equals('newDevice'));
      expect(updated.lastEditor, equals('newUser'));
      // Other fields should remain the same
      expect(updated.id, equals(entity1.id));
      expect(updated.createdAt, equals(entity1.createdAt));
    });

    test('should have meaningful toString', () {
      final string = entity1.toString();
      
      expect(string, contains('SyncBaseEntity'));
      expect(string, contains('version: 1'));
      expect(string, contains('deleted: false'));
    });
  });

  group('EntityUtils', () {
    test('should generate valid UUIDs', () {
      final id1 = EntityUtils.generateId();
      final id2 = EntityUtils.generateId();
      
      expect(EntityUtils.isValidId(id1), isTrue);
      expect(EntityUtils.isValidId(id2), isTrue);
      expect(id1, isNot(equals(id2))); // Should be unique
    });

    test('should validate UUID format correctly', () {
      expect(EntityUtils.isValidId('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(EntityUtils.isValidId('invalid-uuid'), isFalse);
      expect(EntityUtils.isValidId(''), isFalse);
    });

    test('should create sync metadata correctly', () {
      final metadata = EntityUtils.createSyncMetadata(
        deviceId: 'device1',
        lastEditor: 'user1',
      );
      
      expect(metadata['deviceId'], equals('device1'));
      expect(metadata['lastEditor'], equals('user1'));
      expect(metadata['version'], equals(1));
      expect(metadata['isDeleted'], isFalse);
      expect(EntityUtils.isValidId(metadata['id']), isTrue);
    });

    test('should compare entities for sync ordering', () {
      final highPriority = TestEntity(syncPriority: 2, createdAt: DateTime.now());
      final lowPriority = TestEntity(syncPriority: 1, createdAt: DateTime.now());
      
      final comparison = EntityUtils.compareForSync(highPriority, lowPriority);
      expect(comparison, lessThan(0)); // High priority should come first
    });
  });
}

/// Test entity for testing BaseEntity functionality
class TestEntity extends BaseEntity {
  const TestEntity({
    required this.syncPriority,
    required super.createdAt,
  }) : super(
          id: 'test-id',
          updatedAt: createdAt,
          version: 1,
        );

  @override
  final int syncPriority;

  @override
  BaseEntity copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return TestEntity(
      syncPriority: syncPriority,
      createdAt: createdAt,
    );
  }
}