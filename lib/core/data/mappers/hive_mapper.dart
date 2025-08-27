import '../../domain/entities/sync_expense.dart';
import '../../domain/entities/sync_category.dart';
import '../../domain/entities/sync_account.dart';
import '../../domain/entities/sync_budget.dart';
import '../../../features/expense/data/models/expense_model.dart';
import '../../../features/expense/domain/entities/expense.dart';

/// Utility class for mapping between Hive models and sync entities
/// Handles conversions for local storage operations
class HiveMapper {
  
  // ==================== EXPENSE MAPPINGS ====================
  
  /// Convert legacy ExpenseModel to SyncExpense
  static SyncExpense expenseModelToSync(
    ExpenseModel model, {
    required String deviceId,
    required String lastEditor,
    String? receiptPhotoId,
    String? accountId,
    String? categoryId,
  }) {
    return SyncExpense.create(
      title: model.title,
      description: model.description,
      amount: model.amount,
      category: model.category,
      type: model.type,
      date: model.date,
      deviceId: deviceId,
      lastEditor: lastEditor,
      metadata: model.metadata,
      isRecurring: model.isRecurring,
      recurringFrequency: model.recurringFrequency,
      nextOccurrence: model.nextOccurrence,
      endDate: model.endDate,
      receiptPhotoId: receiptPhotoId,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  /// Convert SyncExpense to legacy ExpenseModel
  static ExpenseModel syncToExpenseModel(SyncExpense syncExpense) {
    return ExpenseModel(
      id: syncExpense.id,
      title: syncExpense.title,
      description: syncExpense.description,
      amount: syncExpense.amount,
      category: syncExpense.category,
      type: syncExpense.type,
      date: syncExpense.date,
      createdAt: syncExpense.createdAt,
      updatedAt: syncExpense.updatedAt,
      metadata: syncExpense.metadata,
      isRecurring: syncExpense.isRecurring,
      recurringFrequency: syncExpense.recurringFrequency,
      nextOccurrence: syncExpense.nextOccurrence,
      endDate: syncExpense.endDate,
    );
  }

  /// Convert legacy Expense entity to ExpenseModel for Hive storage
  static ExpenseModel expenseToModel(Expense expense) {
    return ExpenseModel.fromEntity(expense);
  }

  /// Convert ExpenseModel to legacy Expense entity
  static Expense modelToExpense(ExpenseModel model) {
    return model.toEntity();
  }

  // ==================== SYNC ENTITY STORAGE ====================
  
  /// These methods handle direct Hive storage of sync entities
  /// The sync entities themselves are Hive objects with proper annotations
  
  /// Prepare SyncExpense for Hive storage
  /// (No conversion needed - SyncExpense has @HiveType annotation)
  static SyncExpense prepareExpenseForHive(SyncExpense expense) {
    return expense; // Direct storage
  }

  /// Prepare SyncCategory for Hive storage
  /// (No conversion needed - SyncCategory has @HiveType annotation)
  static SyncCategory prepareCategoryForHive(SyncCategory category) {
    return category; // Direct storage
  }

  /// Prepare SyncAccount for Hive storage
  /// (No conversion needed - SyncAccount has @HiveType annotation)
  static SyncAccount prepareAccountForHive(SyncAccount account) {
    return account; // Direct storage
  }

  /// Prepare SyncBudget for Hive storage
  /// (No conversion needed - SyncBudget has @HiveType annotation)
  static SyncBudget prepareBudgetForHive(SyncBudget budget) {
    return budget; // Direct storage
  }

  // ==================== BATCH OPERATIONS ====================
  
  /// Convert multiple ExpenseModels to SyncExpense list
  static List<SyncExpense> expenseModelsToSync(
    List<ExpenseModel> models, {
    required String deviceId,
    required String lastEditor,
  }) {
    return models.map((model) => expenseModelToSync(
      model,
      deviceId: deviceId,
      lastEditor: lastEditor,
    )).toList();
  }

  /// Convert multiple SyncExpense to ExpenseModel list
  static List<ExpenseModel> syncToExpenseModels(List<SyncExpense> expenses) {
    return expenses.map(syncToExpenseModel).toList();
  }

  /// Convert multiple legacy Expense entities to ExpenseModel list
  static List<ExpenseModel> expensesToModels(List<Expense> expenses) {
    return expenses.map(expenseToModel).toList();
  }

  /// Convert multiple ExpenseModel to legacy Expense list
  static List<Expense> modelsToExpenses(List<ExpenseModel> models) {
    return models.map(modelToExpense).toList();
  }

  // ==================== MIGRATION UTILITIES ====================
  
  /// Convert legacy data structure to sync-enabled structure
  /// This is useful for migrating existing Hive data to sync format
  static Map<String, dynamic> migrateLegacyToSync({
    required List<ExpenseModel> legacyExpenses,
    required String deviceId,
    required String lastEditor,
  }) {
    final syncExpenses = expenseModelsToSync(
      legacyExpenses,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );

    return {
      'migratedCount': syncExpenses.length,
      'syncExpenses': syncExpenses,
      'migrationTimestamp': DateTime.now().toUtc(),
    };
  }

  /// Validate that a sync entity can be stored in Hive
  static bool canStoreInHive(dynamic entity) {
    // Check if entity has proper Hive annotations
    if (entity is SyncExpense) return true;
    if (entity is SyncCategory) return true;
    if (entity is SyncAccount) return true;
    if (entity is SyncBudget) return true;
    return false;
  }

  /// Get storage type identifier for Hive box selection
  static String getHiveBoxName(Type entityType) {
    switch (entityType) {
      case SyncExpense:
        return 'sync_expenses';
      case SyncCategory:
        return 'sync_categories';
      case SyncAccount:
        return 'sync_accounts';
      case SyncBudget:
        return 'sync_budgets';
      default:
        throw ArgumentError('Unsupported entity type for Hive storage: $entityType');
    }
  }
}