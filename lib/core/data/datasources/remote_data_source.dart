import '../../../core/domain/result.dart';
import '../dtos/expense_dto.dart';
import '../dtos/category_dto.dart';
import '../dtos/account_dto.dart';
import '../dtos/budget_dto.dart';

/// Remote data source interface for Supabase operations
/// Handles upsert/pullDeltas with user scoping and idempotent operations
abstract class RemoteDataSource {
  /// Pull expense deltas from remote with pagination
  Future<Result<List<ExpenseDto>>> pullExpenseDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  });

  /// Pull category deltas from remote with pagination  
  Future<Result<List<CategoryDto>>> pullCategoryDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  });

  /// Pull account deltas from remote with pagination
  Future<Result<List<AccountDto>>> pullAccountDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  });

  /// Pull budget deltas from remote with pagination
  Future<Result<List<BudgetDto>>> pullBudgetDeltas({
    required String userId,
    DateTime? lastSyncAt,
    int limit = 100,
  });

  /// Upsert expenses to remote (batch operation)
  Future<Result<List<ExpenseDto>>> upsertExpenses(
    List<ExpenseDto> expenses,
    String userId,
  );

  /// Upsert categories to remote (batch operation)
  Future<Result<List<CategoryDto>>> upsertCategories(
    List<CategoryDto> categories,
    String userId,
  );

  /// Upsert accounts to remote (batch operation)
  Future<Result<List<AccountDto>>> upsertAccounts(
    List<AccountDto> accounts,
    String userId,
  );

  /// Upsert budgets to remote (batch operation)
  Future<Result<List<BudgetDto>>> upsertBudgets(
    List<BudgetDto> budgets,
    String userId,
  );

  /// Test connectivity and authentication
  Future<Result<bool>> testConnection();

  /// Get server timestamp for sync coordination
  Future<Result<DateTime>> getServerTimestamp();
}