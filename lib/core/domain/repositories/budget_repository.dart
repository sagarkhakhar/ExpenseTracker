import '../entities/sync_budget.dart';
import '../result.dart';

/// Repository interface for sync-enabled budget operations
abstract class IBudgetRepository {
  
  // ==================== LOCAL OPERATIONS ====================
  
  /// Get all budgets from local storage (active only)
  Future<Result<List<SyncBudget>>> getAllBudgets();
  
  /// Get budget by ID from local storage
  Future<Result<SyncBudget?>> getBudgetById(String id);
  
  /// Create new budget (local first, queued for sync)
  Future<Result<String>> createBudget(SyncBudget budget);
  
  /// Update existing budget (local first, queued for sync)
  Future<Result<void>> updateBudget(SyncBudget budget);
  
  /// Delete budget (soft delete, queued for sync)
  Future<Result<void>> deleteBudget(String id);
  
  // ==================== QUERY OPERATIONS ====================
  
  /// Get budgets by period (monthly, weekly, yearly)
  Future<Result<List<SyncBudget>>> getBudgetsByPeriod(BudgetPeriod period);
  
  /// Get budgets by category
  Future<Result<List<SyncBudget>>> getBudgetsByCategory(String categoryId);
  
  /// Get active budgets for current period
  Future<Result<List<SyncBudget>>> getActiveBudgets();
  
  /// Get budgets by date range
  Future<Result<List<SyncBudget>>> getBudgetsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Search budgets by name
  Future<Result<List<SyncBudget>>> searchBudgets(String query);
  
  /// Get budgets modified since timestamp (for sync)
  Future<Result<List<SyncBudget>>> getBudgetsModifiedSince(DateTime timestamp);
  
  /// Get deleted budgets (tombstones for sync)
  Future<Result<List<SyncBudget>>> getDeletedBudgets();
  
  // ==================== BUDGET TRACKING ====================
  
  /// Get budget utilization (spent vs allocated)
  Future<Result<BudgetUtilization>> getBudgetUtilization(String budgetId);
  
  /// Get all budget utilizations
  Future<Result<List<BudgetUtilization>>> getAllBudgetUtilizations();
  
  /// Get budgets exceeding threshold (e.g., 80% spent)
  Future<Result<List<SyncBudget>>> getBudgetsNearLimit(double threshold);
  
  /// Get total budget vs actual spending summary
  Future<Result<BudgetSummary>> getBudgetSummary({
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // ==================== SYNC OPERATIONS ====================
  
  /// Push local changes to remote
  Future<Result<List<SyncBudget>>> pushLocalChanges(List<SyncBudget> budgets);
  
  /// Pull remote changes and merge with local
  Future<Result<List<SyncBudget>>> pullRemoteChanges({DateTime? cursor});
  
  /// Perform bidirectional sync
  Future<Result<SyncResult>> syncBudgets({DateTime? lastSync});
  
  /// Get pending sync items count
  Future<Result<int>> getPendingSyncCount();
  
  // ==================== BATCH OPERATIONS ====================
  
  /// Bulk create budgets
  Future<Result<List<String>>> createBudgets(List<SyncBudget> budgets);
  
  /// Bulk update budgets
  Future<Result<void>> updateBudgets(List<SyncBudget> budgets);
  
  // ==================== STREAM OPERATIONS ====================
  
  /// Watch all budgets for real-time updates
  Stream<Result<List<SyncBudget>>> watchAllBudgets();
  
  /// Watch budget by ID for real-time updates
  Stream<Result<SyncBudget?>> watchBudgetById(String id);
  
  /// Watch budget utilizations for real-time updates
  Stream<Result<List<BudgetUtilization>>> watchBudgetUtilizations();
}

/// Budget utilization data
class BudgetUtilization {
  const BudgetUtilization({
    required this.budgetId,
    required this.budgetName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.utilizationPercentage,
    required this.isOverBudget,
  });

  final String budgetId;
  final String budgetName;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double utilizationPercentage;
  final bool isOverBudget;

  @override
  String toString() => 'BudgetUtilization('
      'name: $budgetName, '
      'spent: \$${spentAmount.toStringAsFixed(2)}, '
      'budget: \$${budgetAmount.toStringAsFixed(2)}, '
      'utilization: ${utilizationPercentage.toStringAsFixed(1)}%)';
}

/// Overall budget summary
class BudgetSummary {
  const BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallUtilization,
    required this.budgetsCount,
    required this.overBudgetCount,
  });

  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double overallUtilization;
  final int budgetsCount;
  final int overBudgetCount;

  bool get isOverBudget => totalSpent > totalBudget;
  bool get hasOverBudgetItems => overBudgetCount > 0;

  @override
  String toString() => 'BudgetSummary('
      'budget: \$${totalBudget.toStringAsFixed(2)}, '
      'spent: \$${totalSpent.toStringAsFixed(2)}, '
      'utilization: ${overallUtilization.toStringAsFixed(1)}%)';
}

/// Sync result for budget operations
class SyncResult {
  const SyncResult({
    required this.pushedCount,
    required this.pulledCount,
    required this.conflictsResolved,
    required this.errors,
    this.lastSyncTime,
  });

  final int pushedCount;
  final int pulledCount;
  final int conflictsResolved;
  final List<String> errors;
  final DateTime? lastSyncTime;
  
  bool get isSuccessful => errors.isEmpty;
  int get totalSynced => pushedCount + pulledCount;
}