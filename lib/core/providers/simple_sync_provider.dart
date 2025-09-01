import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../debug/supabase_diagnostic.dart';

/// Simple sync service for expenses directly to Supabase
class SimpleSyncService {
  final SupabaseClient _client;
  
  SimpleSyncService(this._client);
  
  /// Sync a single expense to Supabase
  Future<bool> syncExpenseToSupabase(ExpenseModel expense) async {
    try {
      debugPrint('🔄 Syncing expense ${expense.id} to Supabase...');
      debugPrint('   Client ready: ${_client != null}');
      debugPrint('   User ID: ${_client.auth.currentUser?.id ?? 'anonymous'}');
      
      // Test connection first
      await SupabaseDiagnostic.testConnection();
      await SupabaseDiagnostic.testExpenseTableAccess();
      
      // Convert integer IDs to proper UUIDs for Supabase compatibility
      final supabaseId = _ensureValidUUID(expense.id);
      debugPrint('   Original ID: ${expense.id}, Supabase ID: $supabaseId');
      
      // Convert expense to Supabase format
      final expenseData = {
        'id': supabaseId,
        'title': expense.title,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'type': expense.type.name,
        'created_at': expense.createdAt.toIso8601String(),
        'updated_at': expense.updatedAt.toIso8601String(),
        'user_id': _client.auth.currentUser?.id ?? 'anonymous',
      };
      
      debugPrint('   Data to sync: ${expenseData.toString()}');
      
      // Upsert to Supabase expenses table
      final result = await _client
          .from('expenses')
          .upsert(expenseData);
          
      debugPrint('   Upsert result: $result');
      debugPrint('✅ Successfully synced expense ${expense.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to sync expense ${expense.id}: $e');
      
      // Additional diagnostic info on failure
      debugPrint('   Client initialized: ${_client != null}');
      debugPrint('   Auth state: ${_client.auth.currentUser?.id ?? 'No user'}');
      return false;
    }
  }
  
  /// Test Supabase connectivity
  Future<bool> testConnectivity() async {
    try {
      await _client.from('expenses').select('count').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ Supabase connectivity test failed: $e');
      return false;
    }
  }
  
  /// Convert legacy integer IDs to UUIDs for Supabase compatibility
  /// If the ID is already a valid UUID, return it as-is
  /// If it's an integer string, generate a deterministic UUID based on it
  String _ensureValidUUID(String id) {
    // Check if it's already a valid UUID format
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    
    if (uuidRegex.hasMatch(id)) {
      // Already a valid UUID, return as-is
      return id;
    }
    
    // For legacy integer IDs, create a deterministic UUID
    // This ensures the same integer ID always maps to the same UUID
    const uuid = Uuid();
    
    // Parse integer and create a deterministic seed
    final intId = int.tryParse(id);
    if (intId != null) {
      // Create a namespace-based UUID using the integer
      // This ensures consistency across syncs
      final namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // Standard namespace UUID
      final name = 'expense_$intId';
      return uuid.v5(namespace, name);
    }
    
    // If all else fails, generate a new random UUID
    // This shouldn't happen but provides a fallback
    return uuid.v4();
  }
}

/// Provider for Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the simple sync service
final simpleSyncServiceProvider = Provider<SimpleSyncService>((ref) {
  final client = ref.read(supabaseClientProvider);
  return SimpleSyncService(client);
});

/// Provider to test sync connectivity
final syncConnectivityProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.read(simpleSyncServiceProvider);
  return syncService.testConnectivity();
});