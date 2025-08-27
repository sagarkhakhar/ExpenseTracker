import 'package:equatable/equatable.dart';
import '../base_entity.dart';

/// Expense types
enum ExpenseType {
  expense,
  income,
}

/// Sync-enabled Expense entity with BaseEntity fields
/// This uses composition rather than inheritance to avoid Hive complexity
class ExpenseSync extends Equatable {
  const ExpenseSync({
    required this.baseEntity,
    required this.businessData,
  });

  /// Base entity with sync fields
  final BaseEntity baseEntity;
  
  /// Business data
  final ExpenseBusinessData businessData;

  @override
  List<Object?> get props => [baseEntity, businessData];

  /// Get base entity fields
  String get id => baseEntity.id;
  DateTime get createdAt => baseEntity.createdAt;
  DateTime get updatedAt => baseEntity.updatedAt;
  int get version => baseEntity.version;
  bool get isDeleted => baseEntity.isDeleted;
  String? get deviceId => baseEntity.deviceId;
  String? get lastEditor => baseEntity.lastEditor;

  /// Get business fields
  String get title => businessData.title;
  String get description => businessData.description;
  double get amount => businessData.amount;
  String get category => businessData.category;
  ExpenseType get type => businessData.type;
  DateTime get date => businessData.date;
  Map<String, dynamic>? get metadata => businessData.metadata;
  bool get isRecurring => businessData.isRecurring;
  String? get recurringFrequency => businessData.recurringFrequency;
  DateTime? get nextOccurrence => businessData.nextOccurrence;
  DateTime? get endDate => businessData.endDate;
  String? get receiptPhotoId => businessData.receiptPhotoId;
  String? get accountId => businessData.accountId;
  String? get categoryId => businessData.categoryId;

  /// Business logic methods
  bool get isExpense => type == ExpenseType.expense;
  bool get isIncome => type == ExpenseType.income;
  double get signedAmount => isExpense ? -amount : amount;
  bool get hasPhotos => receiptPhotoId != null;

  /// Sync-related methods
  bool isNewerThan(ExpenseSync other) => baseEntity.isNewerThan(other.baseEntity);
  bool get isTombstone => baseEntity.isTombstone;
  int get syncPriority => isDeleted ? 2 : 1;

  /// Create copy with updated sync metadata
  ExpenseSync copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return ExpenseSync(
      baseEntity: baseEntity.copyWithSyncMetadata(
        updatedAt: updatedAt,
        version: version,
        isDeleted: isDeleted,
        deviceId: deviceId,
        lastEditor: lastEditor,
      ),
      businessData: businessData,
    );
  }

  /// Create copy with updated business data
  ExpenseSync copyWithBusinessData({
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
  }) {
    return ExpenseSync(
      baseEntity: baseEntity,
      businessData: businessData.copyWith(
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
      ),
    );
  }

  /// Create new expense with sync metadata
  factory ExpenseSync.create({
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
    return ExpenseSync(
      baseEntity: SyncBaseEntity.create(
        deviceId: deviceId,
        lastEditor: lastEditor,
      ),
      businessData: ExpenseBusinessData(
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
      ),
    );
  }

  /// Convert to map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'type': type.name,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'nextOccurrence': nextOccurrence?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'receiptPhotoId': receiptPhotoId,
      'accountId': accountId,
      'categoryId': categoryId,
      'version': version,
      'isDeleted': isDeleted,
      'deviceId': deviceId,
      'lastEditor': lastEditor,
    };
  }
}

/// Business data for expenses (no sync fields)
class ExpenseBusinessData extends Equatable {
  const ExpenseBusinessData({
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
  });

  final String title;
  final String description;
  final double amount;
  final String category;
  final ExpenseType type;
  final DateTime date;
  final Map<String, dynamic>? metadata;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime? nextOccurrence;
  final DateTime? endDate;
  final String? receiptPhotoId;
  final String? accountId;
  final String? categoryId;

  @override
  List<Object?> get props => [
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

  ExpenseBusinessData copyWith({
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
  }) {
    return ExpenseBusinessData(
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
    );
  }
}

/// Concrete implementation of BaseEntity for sync
class SyncBaseEntity extends BaseEntity {
  const SyncBaseEntity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.version,
    super.isDeleted = false,
    super.deviceId,
    super.lastEditor,
  });

  factory SyncBaseEntity.create({
    required String deviceId,
    required String lastEditor,
  }) {
    final now = EntityUtils.now();
    return SyncBaseEntity(
      id: EntityUtils.generateId(),
      createdAt: now,
      updatedAt: now,
      version: 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  @override
  BaseEntity copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return SyncBaseEntity(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deviceId: deviceId ?? this.deviceId,
      lastEditor: lastEditor ?? this.lastEditor,
    );
  }
}