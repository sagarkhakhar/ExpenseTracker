import 'package:hive/hive.dart';

part 'financial_goal.g.dart';

@HiveType(typeId: 10)
enum GoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  paused,
}

@HiveType(typeId: 11)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime targetDate;

  @HiveField(6)
  final String? category;

  @HiveField(7)
  GoalStatus status;

  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.targetDate,
    this.category,
    this.status = GoalStatus.active,
  });

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  bool get isCompleted => status == GoalStatus.completed;
  bool get isActive => status == GoalStatus.active;
  bool get isPaused => status == GoalStatus.paused;

  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  FinancialGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? category,
    GoalStatus? status,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialGoal &&
        other.id == id &&
        other.title == title &&
        other.targetAmount == targetAmount &&
        other.currentAmount == currentAmount &&
        other.startDate == startDate &&
        other.targetDate == targetDate &&
        other.category == category &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      targetAmount,
      currentAmount,
      startDate,
      targetDate,
      category,
      status,
    );
  }

  @override
  String toString() {
    return 'FinancialGoal(id: $id, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, targetDate: $targetDate, category: $category, status: $status)';
  }
}
