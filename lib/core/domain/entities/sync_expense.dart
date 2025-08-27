import 'package:hive/hive.dart';
import '../base_entity.dart';
import '../../../features/expense/domain/entities/expense.dart';

part 'sync_expense.g.dart';

/// Sync-enabled Expense entity with BaseEntity fields
/// This extends BaseEntity to support offline-first synchronization
@HiveType(typeId: 20) // New type ID to avoid conflicts
class SyncExpense extends BaseEntity {
  /// Business logic fields
  @HiveField(0)
  final String title;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final ExpenseType type;
  
  @HiveField(5)
  final DateTime date;
  
  @HiveField(6)
  final Map<String, dynamic>? metadata;
  
  @HiveField(7)
  final bool isRecurring;
  
  @HiveField(8)
  final String? recurringFrequency;
  
  @HiveField(9)
  final DateTime? nextOccurrence;
  
  @HiveField(10)
  final DateTime? endDate;

  /// Receipt photo ID (optional foreign key)
  @HiveField(11)
  final String? receiptPhotoId;

  /// Account ID (optional foreign key) 
  @HiveField(12)
  final String? accountId;

  /// Category ID (foreign key to sync categories)
  @HiveField(13)
  final String? categoryId;

  /// BaseEntity sync fields
  @override
  @HiveField(14)
  final String id;
  
  @override
  @HiveField(15)
  final DateTime createdAt;
  
  @override
  @HiveField(16)
  final DateTime updatedAt;
  
  @override
  @HiveField(17)
  final int version;
  
  @override
  @HiveField(18)
  final bool isDeleted;
  
  @override
  @HiveField(19)
  final String? deviceId;
  
  @override
  @HiveField(20)
  final String? lastEditor;

  const SyncExpense({
    // Business fields
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.metadata,
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextOccurrence,
    this.endDate,
    this.receiptPhotoId,
    this.accountId,
    this.categoryId,
    // BaseEntity fields
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.isDeleted = false,
    this.deviceId,
    this.lastEditor,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          version: version,
          isDeleted: isDeleted,
          deviceId: deviceId,
          lastEditor: lastEditor,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        title,
        description,
        amount,
        category,
        type,
        date,
        metadata,
        isRecurring,
        recurringFrequency,
        nextOccurrence,
        endDate,
        receiptPhotoId,
        accountId,
        categoryId,
      ];

  @override
  SyncExpense copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return copyWith(
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// Create a copy with updated fields
  SyncExpense copyWith({
    String? title,
    String? description,
    double? amount,
    String? category,
    ExpenseType? type,
    DateTime? date,
    Map<String, dynamic>? metadata,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? nextOccurrence,
    DateTime? endDate,
    String? receiptPhotoId,
    String? accountId,
    String? categoryId,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return SyncExpense(
      // Business fields
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      metadata: metadata ?? this.metadata,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: endDate ?? this.endDate,
      receiptPhotoId: receiptPhotoId ?? this.receiptPhotoId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      // BaseEntity fields
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deviceId: deviceId ?? this.deviceId,
      lastEditor: lastEditor ?? this.lastEditor,
    );
  }

  /// Factory constructor from legacy Expense
  factory SyncExpense.fromLegacy(
    Expense expense, {
    required String deviceId,
    required String lastEditor,
    String? receiptPhotoId,
    String? accountId,
    String? categoryId,
  }) {
    return SyncExpense(
      // Business fields from legacy
      title: expense.title,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      type: expense.type,
      date: expense.date,
      metadata: expense.metadata,
      isRecurring: expense.isRecurring,
      recurringFrequency: expense.recurringFrequency,
      nextOccurrence: expense.nextOccurrence,
      endDate: expense.endDate,
      // New foreign key fields
      receiptPhotoId: receiptPhotoId,
      accountId: accountId,
      categoryId: categoryId,
      // Sync fields
      id: expense.id,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      version: 1, // Start with version 1 for legacy data
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// Create new expense with sync metadata
  factory SyncExpense.create({
    required String title,
    required String description,
    required double amount,
    required String category,
    required ExpenseType type,
    required DateTime date,
    required String deviceId,
    required String lastEditor,
    Map<String, dynamic>? metadata,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? nextOccurrence,
    DateTime? endDate,
    String? receiptPhotoId,
    String? accountId,
    String? categoryId,
  }) {
    final now = EntityUtils.now();
    return SyncExpense(
      // Business fields
      title: title,
      description: description,
      amount: amount,
      category: category,
      type: type,
      date: date,
      metadata: metadata,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      nextOccurrence: nextOccurrence,
      endDate: endDate,
      receiptPhotoId: receiptPhotoId,
      accountId: accountId,
      categoryId: categoryId,
      // Sync fields
      id: EntityUtils.generateId(),
      createdAt: now,
      updatedAt: now,
      version: 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// Convert to legacy Expense for backward compatibility
  Expense toLegacy() {
    return Expense(
      id: id,
      title: title,
      description: description,
      amount: amount,
      category: category,
      type: type,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      nextOccurrence: nextOccurrence,
      endDate: endDate,
    );
  }

  /// Business logic methods
  bool get isExpense => type == ExpenseType.expense;
  bool get isIncome => type == ExpenseType.income;
  double get signedAmount => isExpense ? -amount : amount;
  bool get hasPhotos => receiptPhotoId != null;

  @override
  int get syncPriority => isDeleted ? 2 : 1; // Deleted items sync first, then regular
}