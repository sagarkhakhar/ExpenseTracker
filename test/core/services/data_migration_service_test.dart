import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/core/services/data_migration_service.dart';
import 'package:expense_tracker/core/data/services/mutation_queue_service.dart';

// Create a mock mutation queue service
class MockMutationQueueService extends Mock implements MutationQueueService {}

void main() {
  group('DataMigrationService', () {
    late DataMigrationService migrationService;
    late MockMutationQueueService mockMutationQueueService;

    setUp(() {
      mockMutationQueueService = MockMutationQueueService();
      migrationService = DataMigrationService(
        mutationQueueService: mockMutationQueueService,
      );
    });

    test('performMigration should handle empty data gracefully', () async {
      const userId = 'test-user-123';

      final result = await migrationService.performMigration(userId);
      
      expect(result.isSuccess, isTrue);
      final migrationResult = result.data!;
      expect(migrationResult.userId, equals(userId));
      expect(migrationResult.totalItems, equals(0));
      expect(migrationResult.migratedItems, equals(0));
      expect(migrationResult.isSuccess, isTrue);
    });

    test('MigrationCount should store counts correctly', () {
      const count = MigrationCount(total: 5, migrated: 3);
      
      expect(count.total, equals(5));
      expect(count.migrated, equals(3));
    });

    test('DataMigrationResult should determine success correctly', () {
      // Success case
      final successResult = DataMigrationResult(
        userId: 'user-1',
        totalItems: 5,
        migratedItems: 5,
        completedAt: DateTime.now(),
      );
      
      expect(successResult.isSuccess, isTrue);

      // Success case with empty errors
      final successWithEmptyErrors = DataMigrationResult(
        userId: 'user-1',
        totalItems: 5,
        migratedItems: 5,
        errors: [],
        completedAt: DateTime.now(),
      );
      
      expect(successWithEmptyErrors.isSuccess, isTrue);

      // Failure case
      final failureResult = DataMigrationResult(
        userId: 'user-1',
        totalItems: 5,
        migratedItems: 3,
        errors: ['Error 1', 'Error 2'],
        completedAt: DateTime.now(),
      );
      
      expect(failureResult.isSuccess, isFalse);
    });

    test('DataMigrationResult should have proper string representation', () {
      final result = DataMigrationResult(
        userId: 'test-user',
        totalItems: 10,
        migratedItems: 8,
        errors: ['error1'],
        completedAt: DateTime.now(),
      );
      
      final string = result.toString();
      expect(string, contains('test-user'));
      expect(string, contains('totalItems: 10'));
      expect(string, contains('migratedItems: 8'));
      expect(string, contains('error1'));
    });
  });
}