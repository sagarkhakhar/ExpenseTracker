import '../entities/sync_account.dart';
import '../result.dart';

/// Repository interface for sync-enabled account operations
abstract class IAccountRepository {
  
  // ==================== LOCAL OPERATIONS ====================
  
  /// Get all accounts from local storage (active only)
  Future<Result<List<SyncAccount>>> getAllAccounts();
  
  /// Get account by ID from local storage
  Future<Result<SyncAccount?>> getAccountById(String id);
  
  /// Create new account (local first, queued for sync)
  Future<Result<String>> createAccount(SyncAccount account);
  
  /// Update existing account (local first, queued for sync)
  Future<Result<void>> updateAccount(SyncAccount account);
  
  /// Delete account (soft delete, queued for sync)
  Future<Result<void>> deleteAccount(String id);
  
  // ==================== QUERY OPERATIONS ====================
  
  /// Get accounts by type (cash, bank, credit, etc.)
  Future<Result<List<SyncAccount>>> getAccountsByType(AccountType type);
  
  /// Search accounts by name
  Future<Result<List<SyncAccount>>> searchAccounts(String query);
  
  /// Get accounts with balance above threshold
  Future<Result<List<SyncAccount>>> getAccountsByMinBalance(double minBalance);
  
  /// Get accounts modified since timestamp (for sync)
  Future<Result<List<SyncAccount>>> getAccountsModifiedSince(DateTime timestamp);
  
  /// Get deleted accounts (tombstones for sync)
  Future<Result<List<SyncAccount>>> getDeletedAccounts();
  
  // ==================== BALANCE OPERATIONS ====================
  
  /// Update account balance (atomic operation)
  Future<Result<void>> updateAccountBalance({
    required String accountId,
    required double newBalance,
  });
  
  /// Adjust account balance by amount (+ or -)
  Future<Result<double>> adjustAccountBalance({
    required String accountId,
    required double adjustment,
  });
  
  /// Get total balance across all accounts
  Future<Result<double>> getTotalBalance();
  
  /// Get total balance by account type
  Future<Result<Map<AccountType, double>>> getBalanceByType();
  
  // ==================== SYNC OPERATIONS ====================
  
  /// Push local changes to remote
  Future<Result<List<SyncAccount>>> pushLocalChanges(List<SyncAccount> accounts);
  
  /// Pull remote changes and merge with local
  Future<Result<List<SyncAccount>>> pullRemoteChanges({DateTime? cursor});
  
  /// Perform bidirectional sync
  Future<Result<SyncResult>> syncAccounts({DateTime? lastSync});
  
  /// Get pending sync items count
  Future<Result<int>> getPendingSyncCount();
  
  // ==================== BATCH OPERATIONS ====================
  
  /// Bulk create accounts
  Future<Result<List<String>>> createAccounts(List<SyncAccount> accounts);
  
  /// Bulk update accounts
  Future<Result<void>> updateAccounts(List<SyncAccount> accounts);
  
  /// Initialize default accounts if not present
  Future<Result<void>> initializeDefaultAccounts();
  
  // ==================== STREAM OPERATIONS ====================
  
  /// Watch all accounts for real-time updates
  Stream<Result<List<SyncAccount>>> watchAllAccounts();
  
  /// Watch account by ID for real-time updates
  Stream<Result<SyncAccount?>> watchAccountById(String id);
  
  /// Watch total balance changes
  Stream<Result<double>> watchTotalBalance();
}

/// Sync result for account operations
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