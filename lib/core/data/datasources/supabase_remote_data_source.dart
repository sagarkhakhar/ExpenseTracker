import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/domain/result.dart';
import '../../../core/domain/errors/sync_errors.dart';
import '../dtos/expense_dto.dart';
import '../dtos/category_dto.dart';
import '../dtos/account_dto.dart';
import '../dtos/budget_dto.dart';
import 'remote_data_source.dart';

/// Supabase implementation of RemoteDataSource
/// Provides upsert/pullDeltas with user scoping and idempotent operations
class SupabaseRemoteDataSource implements RemoteDataSource {
  final SupabaseClient _client;
  
  static const int _maxBatchSize = 200;
  static const String _expensesTable = 'expenses';
  static const String _categoriesTable = 'categories';
  static const String _accountsTable = 'accounts';
  static const String _budgetsTable = 'budgets';

  const SupabaseRemoteDataSource(this._client);

  @override
  Future<Result<List<ExpenseDto>>> pullExpenseDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from(_expensesTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: true)
          .limit(limit);

      if (lastSyncAt != null) {
        // TODO: Implement proper timestamp filtering when Supabase API is stable
        // For now, pull all records and filter in application logic
        // query = query.gte('updated_at', lastSyncAt.toUtc().toIso8601String());
      }

      final response = await query;
      
      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(expenses);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to pull expense deltas: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error pulling expense deltas: $e'),
      );
    }
  }

  @override
  Future<Result<List<CategoryDto>>> pullCategoryDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from(_categoriesTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: true)
          .limit(limit);

      if (lastSyncAt != null) {
        // TODO: Implement proper timestamp filtering when Supabase API is stable
        // For now, pull all records and filter in application logic
        // query = query.gte('updated_at', lastSyncAt.toUtc().toIso8601String());
      }

      final response = await query;
      
      final categories = (response as List<dynamic>)
          .map((json) => CategoryDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(categories);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to pull category deltas: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error pulling category deltas: $e'),
      );
    }
  }

  @override
  Future<Result<List<AccountDto>>> pullAccountDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from(_accountsTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: true)
          .limit(limit);

      if (lastSyncAt != null) {
        // TODO: Implement proper timestamp filtering when Supabase API is stable
        // For now, pull all records and filter in application logic
        // query = query.gte('updated_at', lastSyncAt.toUtc().toIso8601String());
      }

      final response = await query;
      
      final accounts = (response as List<dynamic>)
          .map((json) => AccountDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(accounts);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to pull account deltas: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error pulling account deltas: $e'),
      );
    }
  }

  @override
  Future<Result<List<BudgetDto>>> pullBudgetDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from(_budgetsTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: true)
          .limit(limit);

      if (lastSyncAt != null) {
        // TODO: Implement proper timestamp filtering when Supabase API is stable
        // For now, pull all records and filter in application logic
        // query = query.gte('updated_at', lastSyncAt.toUtc().toIso8601String());
      }

      final response = await query;
      
      final budgets = (response as List<dynamic>)
          .map((json) => BudgetDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(budgets);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to pull budget deltas: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error pulling budget deltas: $e'),
      );
    }
  }

  @override
  Future<Result<List<ExpenseDto>>> upsertExpenses(
    List<ExpenseDto> expenses,
    String userId,
  ) async {
    if (expenses.isEmpty) return const Result.success([]);
    
    try {
      // Ensure user scoping and batch size limits
      final batchedExpenses = _batchItems(expenses, _maxBatchSize);
      final results = <ExpenseDto>[];

      for (final batch in batchedExpenses) {
        // Add user_id to each expense for server-side validation
        final expensesWithUserId = batch.map((expense) => {
          ...expense.toJson(),
          'user_id': userId,
        }).toList();

        final response = await _client
            .from(_expensesTable)
            .upsert(expensesWithUserId, onConflict: 'id')
            .select();

        final batchResults = (response as List<dynamic>)
            .map((json) => ExpenseDto.fromJson(json as Map<String, dynamic>))
            .toList();
        
        results.addAll(batchResults);
      }

      return Result.success(results);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to upsert expenses: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error upserting expenses: $e'),
      );
    }
  }

  @override
  Future<Result<List<CategoryDto>>> upsertCategories(
    List<CategoryDto> categories,
    String userId,
  ) async {
    if (categories.isEmpty) return const Result.success([]);
    
    try {
      final batchedCategories = _batchItems(categories, _maxBatchSize);
      final results = <CategoryDto>[];

      for (final batch in batchedCategories) {
        final categoriesWithUserId = batch.map((category) => {
          ...category.toJson(),
          'user_id': userId,
        }).toList();

        final response = await _client
            .from(_categoriesTable)
            .upsert(categoriesWithUserId, onConflict: 'id')
            .select();

        final batchResults = (response as List<dynamic>)
            .map((json) => CategoryDto.fromJson(json as Map<String, dynamic>))
            .toList();
        
        results.addAll(batchResults);
      }

      return Result.success(results);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to upsert categories: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error upserting categories: $e'),
      );
    }
  }

  @override
  Future<Result<List<AccountDto>>> upsertAccounts(
    List<AccountDto> accounts,
    String userId,
  ) async {
    if (accounts.isEmpty) return const Result.success([]);
    
    try {
      final batchedAccounts = _batchItems(accounts, _maxBatchSize);
      final results = <AccountDto>[];

      for (final batch in batchedAccounts) {
        final accountsWithUserId = batch.map((account) => {
          ...account.toJson(),
          'user_id': userId,
        }).toList();

        final response = await _client
            .from(_accountsTable)
            .upsert(accountsWithUserId, onConflict: 'id')
            .select();

        final batchResults = (response as List<dynamic>)
            .map((json) => AccountDto.fromJson(json as Map<String, dynamic>))
            .toList();
        
        results.addAll(batchResults);
      }

      return Result.success(results);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to upsert accounts: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error upserting accounts: $e'),
      );
    }
  }

  @override
  Future<Result<List<BudgetDto>>> upsertBudgets(
    List<BudgetDto> budgets,
    String userId,
  ) async {
    if (budgets.isEmpty) return const Result.success([]);
    
    try {
      final batchedBudgets = _batchItems(budgets, _maxBatchSize);
      final results = <BudgetDto>[];

      for (final batch in batchedBudgets) {
        final budgetsWithUserId = batch.map((budget) => {
          ...budget.toJson(),
          'user_id': userId,
        }).toList();

        final response = await _client
            .from(_budgetsTable)
            .upsert(budgetsWithUserId, onConflict: 'id')
            .select();

        final batchResults = (response as List<dynamic>)
            .map((json) => BudgetDto.fromJson(json as Map<String, dynamic>))
            .toList();
        
        results.addAll(batchResults);
      }

      return Result.success(results);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to upsert budgets: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error upserting budgets: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> testConnection() async {
    try {
      // Simple query to test connectivity and auth
      await _client.from('categories').select('count').limit(1).single();
      return const Result.success(true);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Connection test failed: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Connection test failed: $e'),
      );
    }
  }

  @override
  Future<Result<DateTime>> getServerTimestamp() async {
    try {
      final response = await _client.rpc('get_server_timestamp');
      final timestampStr = response as String;
      final timestamp = DateTime.parse(timestampStr).toUtc();
      return Result.success(timestamp);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to get server timestamp: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error getting server timestamp: $e'),
      );
    }
  }

  @override
  Future<Result<void>> batchUpsertExpenses(List<Map<String, dynamic>> expensesData) async {
    try {
      if (expensesData.isEmpty) return const Result.success(null);
      
      final batchedData = _batchItems(expensesData, _maxBatchSize);
      
      for (final batch in batchedData) {
        await _client
            .from(_expensesTable)
            .upsert(batch, onConflict: 'id');
      }
      
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to batch upsert expenses: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error batch upserting expenses: $e'),
      );
    }
  }

  @override
  Future<Result<void>> batchUpsertCategories(List<Map<String, dynamic>> categoriesData) async {
    try {
      if (categoriesData.isEmpty) return const Result.success(null);
      
      final batchedData = _batchItems(categoriesData, _maxBatchSize);
      
      for (final batch in batchedData) {
        await _client
            .from(_categoriesTable)
            .upsert(batch, onConflict: 'id');
      }
      
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to batch upsert categories: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error batch upserting categories: $e'),
      );
    }
  }

  @override
  Future<Result<void>> batchUpsertAccounts(List<Map<String, dynamic>> accountsData) async {
    try {
      if (accountsData.isEmpty) return const Result.success(null);
      
      final batchedData = _batchItems(accountsData, _maxBatchSize);
      
      for (final batch in batchedData) {
        await _client
            .from(_accountsTable)
            .upsert(batch, onConflict: 'id');
      }
      
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to batch upsert accounts: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error batch upserting accounts: $e'),
      );
    }
  }

  @override
  Future<Result<void>> batchUpsertBudgets(List<Map<String, dynamic>> budgetsData) async {
    try {
      if (budgetsData.isEmpty) return const Result.success(null);
      
      final batchedData = _batchItems(budgetsData, _maxBatchSize);
      
      for (final batch in batchedData) {
        await _client
            .from(_budgetsTable)
            .upsert(batch, onConflict: 'id');
      }
      
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(
        SupabaseError(message: 'Failed to batch upsert budgets: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        NetworkError(message: 'Unexpected error batch upserting budgets: $e'),
      );
    }
  }

  /// Split items into batches of specified size
  List<List<T>> _batchItems<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }
}