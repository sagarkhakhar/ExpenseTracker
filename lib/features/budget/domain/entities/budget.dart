import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final String categoryId;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double spentAmount;
  final double alertThreshold;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
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

  Budget copyWith({
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
    return Budget(
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

  double get progressPercentage => amount > 0 ? (spentAmount / amount) * 100 : 0.0;

  bool get isApproachingLimit => progressPercentage >= alertThreshold && progressPercentage < 100.0;

  bool get isExceeded => progressPercentage >= 100.0;

  bool get isWithinLimit => progressPercentage < alertThreshold;

  @override
  List<Object?> get props => [
        id,
        categoryId,
        amount,
        period,
        startDate,
        endDate,
        spentAmount,
        alertThreshold,
        isActive,
        createdAt,
        updatedAt,
      ];
} 