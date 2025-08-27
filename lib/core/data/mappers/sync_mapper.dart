import '../../domain/entities/sync_expense.dart';
import '../../domain/entities/sync_category.dart';
import '../../domain/entities/sync_account.dart';
import '../../domain/entities/sync_budget.dart';
import '../../../features/expense/domain/entities/expense.dart';
import '../dtos/expense_dto.dart';
import '../dtos/category_dto.dart';
import '../dtos/account_dto.dart';
import '../dtos/budget_dto.dart';

/// Utility class for mapping between different entity representations
/// Handles conversions between sync entities, DTOs, and legacy entities
class SyncMapper {
  
  // ==================== EXPENSE MAPPINGS ====================
  
  /// Convert legacy Expense to SyncExpense
  static SyncExpense expenseToSync(
    Expense expense, {
    required String deviceId,
    required String lastEditor,
    String? receiptPhotoId,
    String? accountId,
    String? categoryId,
  }) {
    return SyncExpense.create(
      title: expense.title,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      type: expense.type,
      date: expense.date,
      deviceId: deviceId,
      lastEditor: lastEditor,
      metadata: expense.metadata,
      isRecurring: expense.isRecurring,
      recurringFrequency: expense.recurringFrequency,
      nextOccurrence: expense.nextOccurrence,
      endDate: expense.endDate,
      receiptPhotoId: receiptPhotoId,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  /// Convert SyncExpense to legacy Expense
  static Expense syncToExpense(SyncExpense syncExpense) {
    return Expense(
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

  /// Convert SyncExpense to ExpenseDto for JSON serialization
  static ExpenseDto syncExpenseToDto(SyncExpense syncExpense) {
    return ExpenseDto.fromEntity(syncExpense);
  }

  /// Convert ExpenseDto to SyncExpense
  static SyncExpense dtoToSyncExpense(ExpenseDto dto, {String? categoryName}) {
    return dto.toEntity();
  }

  // ==================== CATEGORY MAPPINGS ====================

  /// Convert SyncCategory to CategoryDto
  static CategoryDto syncCategoryToDto(SyncCategory category) {
    return CategoryDto.fromEntity(category);
  }

  /// Convert CategoryDto to SyncCategory
  static SyncCategory dtoToSyncCategory(CategoryDto dto) {
    return dto.toEntity();
  }

  // ==================== ACCOUNT MAPPINGS ====================

  /// Convert SyncAccount to AccountDto
  static AccountDto syncAccountToDto(SyncAccount account) {
    return AccountDto.fromEntity(account);
  }

  /// Convert AccountDto to SyncAccount
  static SyncAccount dtoToSyncAccount(AccountDto dto) {
    return dto.toEntity();
  }

  // ==================== BUDGET MAPPINGS ====================

  /// Convert SyncBudget to BudgetDto
  static BudgetDto syncBudgetToDto(SyncBudget budget) {
    return BudgetDto.fromEntity(budget);
  }

  /// Convert BudgetDto to SyncBudget
  static SyncBudget dtoToSyncBudget(BudgetDto dto) {
    return dto.toEntity();
  }

  // ==================== BATCH MAPPINGS ====================

  /// Convert multiple SyncExpense to ExpenseDto list
  static List<ExpenseDto> syncExpensesToDtos(List<SyncExpense> expenses) {
    return expenses.map(syncExpenseToDto).toList();
  }

  /// Convert multiple ExpenseDto to SyncExpense list
  static List<SyncExpense> dtosToSyncExpenses(List<ExpenseDto> dtos) {
    return dtos.map(dtoToSyncExpense).toList();
  }

  /// Convert multiple SyncCategory to CategoryDto list
  static List<CategoryDto> syncCategoriesToDtos(List<SyncCategory> categories) {
    return categories.map(syncCategoryToDto).toList();
  }

  /// Convert multiple CategoryDto to SyncCategory list
  static List<SyncCategory> dtosToSyncCategories(List<CategoryDto> dtos) {
    return dtos.map(dtoToSyncCategory).toList();
  }

  /// Convert multiple SyncAccount to AccountDto list
  static List<AccountDto> syncAccountsToDtos(List<SyncAccount> accounts) {
    return accounts.map(syncAccountToDto).toList();
  }

  /// Convert multiple AccountDto to SyncAccount list
  static List<SyncAccount> dtosToSyncAccounts(List<AccountDto> dtos) {
    return dtos.map(dtoToSyncAccount).toList();
  }

  /// Convert multiple SyncBudget to BudgetDto list
  static List<BudgetDto> syncBudgetsToDtos(List<SyncBudget> budgets) {
    return budgets.map(syncBudgetToDto).toList();
  }

  /// Convert multiple BudgetDto to SyncBudget list
  static List<SyncBudget> dtosToSyncBudgets(List<BudgetDto> dtos) {
    return dtos.map(dtoToSyncBudget).toList();
  }

  // ==================== JSON CONVERSION UTILITIES ====================

  /// Convert entity to JSON map (via DTO)
  static Map<String, dynamic> expenseToJson(SyncExpense expense) {
    return syncExpenseToDto(expense).toJson();
  }

  /// Convert JSON map to entity (via DTO)
  static SyncExpense expenseFromJson(Map<String, dynamic> json) {
    return dtoToSyncExpense(ExpenseDto.fromJson(json));
  }

  /// Convert category to JSON map (via DTO)
  static Map<String, dynamic> categoryToJson(SyncCategory category) {
    return syncCategoryToDto(category).toJson();
  }

  /// Convert JSON map to category (via DTO)
  static SyncCategory categoryFromJson(Map<String, dynamic> json) {
    return dtoToSyncCategory(CategoryDto.fromJson(json));
  }

  /// Convert account to JSON map (via DTO)
  static Map<String, dynamic> accountToJson(SyncAccount account) {
    return syncAccountToDto(account).toJson();
  }

  /// Convert JSON map to account (via DTO)
  static SyncAccount accountFromJson(Map<String, dynamic> json) {
    return dtoToSyncAccount(AccountDto.fromJson(json));
  }

  /// Convert budget to JSON map (via DTO)
  static Map<String, dynamic> budgetToJson(SyncBudget budget) {
    return syncBudgetToDto(budget).toJson();
  }

  /// Convert JSON map to budget (via DTO)
  static SyncBudget budgetFromJson(Map<String, dynamic> json) {
    return dtoToSyncBudget(BudgetDto.fromJson(json));
  }
}