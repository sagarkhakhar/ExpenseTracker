import 'package:hive/hive.dart';
import '../../domain/entities/budget.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 4)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String period;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime endDate;

  @HiveField(6)
  final double spentAmount;

  @HiveField(7)
  final double alertThreshold;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.spentAmount = 0.0,
    this.alertThreshold = 80.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: budget.period,
      startDate: budget.startDate,
      endDate: budget.endDate,
      spentAmount: budget.spentAmount,
      alertThreshold: budget.alertThreshold,
      isActive: budget.isActive,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
    );
  }

  Budget toEntity() {
    return Budget(
      id: id,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      spentAmount: spentAmount,
      alertThreshold: alertThreshold,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? spentAmount,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spentAmount: spentAmount ?? this.spentAmount,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
