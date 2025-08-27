import 'package:hive/hive.dart';
import '../base_entity.dart';

part 'sync_budget.g.dart';

/// Budget period types
@HiveType(typeId: 24)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  
  @HiveField(1)
  monthly,
  
  @HiveField(2)
  quarterly,
  
  @HiveField(3)
  yearly,
  
  @HiveField(4)
  custom, // Use startDate and endDate
}

/// Sync-enabled Budget entity with BaseEntity fields  
@HiveType(typeId: 25)
class SyncBudget extends BaseEntity {
  /// Business logic fields
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final double amount; // Budget limit
  
  @HiveField(2)
  final String? categoryId; // Optional category to budget for
  
  @HiveField(3)
  final BudgetPeriod period;
  
  @HiveField(4)
  final DateTime? startDate; // For custom periods
  
  @HiveField(5)
  final DateTime? endDate; // For custom periods
  
  @HiveField(6)
  final String? description;
  
  @HiveField(7)
  final bool isActive;

  /// BaseEntity sync fields
  @override
  @HiveField(8)
  final String id;
  
  @override
  @HiveField(9)
  final DateTime createdAt;
  
  @override
  @HiveField(10)
  final DateTime updatedAt;
  
  @override
  @HiveField(11)
  final int version;
  
  @override
  @HiveField(12)
  final bool isDeleted;
  
  @override
  @HiveField(13)
  final String? deviceId;
  
  @override
  @HiveField(14)
  final String? lastEditor;

  const SyncBudget({
    // Business fields
    required this.name,
    required this.amount,
    this.categoryId,
    required this.period,
    this.startDate,
    this.endDate,
    this.description,
    this.isActive = true,
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
        name,
        amount,
        categoryId,
        period,
        startDate,
        endDate,
        description,
        isActive,
      ];

  @override
  SyncBudget copyWithSyncMetadata({
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

  SyncBudget copyWith({
    String? name,
    double? amount,
    String? categoryId,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return SyncBudget(
      // Business fields
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
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

  /// Create new budget with sync metadata
  factory SyncBudget.create({
    required String name,
    required double amount,
    required BudgetPeriod period,
    required String deviceId,
    required String lastEditor,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool isActive = true,
  }) {
    final now = EntityUtils.now();
    return SyncBudget(
      name: name,
      amount: amount,
      categoryId: categoryId,
      period: period,
      startDate: startDate,
      endDate: endDate,
      description: description,
      isActive: isActive,
      id: EntityUtils.generateId(),
      createdAt: now,
      updatedAt: now,
      version: 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// Get the effective date range for this budget period
  DateTimeRange getEffectiveDateRange([DateTime? referenceDate]) {
    referenceDate ??= DateTime.now();
    
    switch (period) {
      case BudgetPeriod.custom:
        return DateTimeRange(
          start: startDate ?? referenceDate,
          end: endDate ?? referenceDate.add(const Duration(days: 30)),
        );
        
      case BudgetPeriod.weekly:
        final startOfWeek = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59),
        );
        
      case BudgetPeriod.monthly:
        return DateTimeRange(
          start: DateTime(referenceDate.year, referenceDate.month, 1),
          end: DateTime(referenceDate.year, referenceDate.month + 1, 0, 23, 59, 59),
        );
        
      case BudgetPeriod.quarterly:
        final quarter = ((referenceDate.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        return DateTimeRange(
          start: DateTime(referenceDate.year, startMonth, 1),
          end: DateTime(referenceDate.year, startMonth + 3, 0, 23, 59, 59),
        );
        
      case BudgetPeriod.yearly:
        return DateTimeRange(
          start: DateTime(referenceDate.year, 1, 1),
          end: DateTime(referenceDate.year, 12, 31, 23, 59, 59),
        );
    }
  }

  @override
  int get syncPriority => 0; // Normal priority for budgets
}

/// Helper class for date ranges
class DateTimeRange {
  const DateTimeRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end) || 
           date.isAtSameMomentAs(start) || 
           date.isAtSameMomentAs(end);
  }

  Duration get duration => end.difference(start);

  @override
  String toString() => 'DateTimeRange(${start.toIso8601String()} - ${end.toIso8601String()})';
}