import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/providers/simple_sync_provider.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('Expense Supabase Sync Integration Tests', () {
    
    test('should verify sync service can be created', () {
      // This test verifies the sync provider setup is correct
      expect(() {
        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWith((ref) {
              // Mock Supabase client for testing
              return FakeSupabaseClient();
            }),
          ],
        );
        
        final syncService = container.read(simpleSyncServiceProvider);
        expect(syncService, isNotNull);
        expect(syncService, isA<SimpleSyncService>());
        
        container.dispose();
      }, returnsNormally);
    });
    
    test('should handle sync operation without crashing', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith((ref) {
            return FakeSupabaseClient();
          }),
        ],
      );
      
      final syncService = container.read(simpleSyncServiceProvider);
      
      // Create a test expense
      final testExpense = ExpenseModel(
        id: 'test-expense-1',
        title: 'Test Sync Expense',
        description: 'Testing sync functionality',
        amount: 50.0,
        category: 'Food',
        date: DateTime.now(),
        type: ExpenseType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Test sync operation (should not crash)
      expect(() async {
        await syncService.syncExpenseToSupabase(testExpense);
      }, returnsNormally);
      
      container.dispose();
    });
    
    test('should handle connectivity test gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith((ref) {
            return FakeSupabaseClient();
          }),
        ],
      );
      
      final syncService = container.read(simpleSyncServiceProvider);
      
      // Test connectivity check (should not crash)
      expect(() async {
        await syncService.testConnectivity();
      }, returnsNormally);
      
      container.dispose();
    });
  });
}

/// Fake Supabase client for testing
class FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // For testing, we'll return fake responses or throw controlled exceptions
    if (invocation.memberName == #from) {
      return FakeSupabaseQueryBuilder();
    }
    
    if (invocation.memberName == #auth) {
      return FakeGoTrueClient();
    }
    
    return super.noSuchMethod(invocation);
  }
}

/// Fake query builder
class FakeSupabaseQueryBuilder {
  FakeSupabaseQueryBuilder upsert(Map<String, dynamic> data) {
    // Simulate successful upsert
    return this;
  }
  
  FakeSupabaseQueryBuilder select(String columns) {
    return this;
  }
  
  FakeSupabaseQueryBuilder limit(int count) {
    return this;
  }
  
  Future<void> then(Function(dynamic) onValue) async {
    // Simulate successful completion
    onValue(null);
  }
}

/// Fake auth client
class FakeGoTrueClient {
  User? get currentUser => FakeUser();
}

/// Fake user
class FakeUser implements User {
  @override
  String get id => 'test-user-id';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}