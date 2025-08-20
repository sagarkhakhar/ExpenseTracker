// This file defines the FinancialGoal entity, which represents financial goals and targets in the app.
// It is used throughout the statistics feature for goal tracking and progress monitoring.
// This demonstrates proper entity design with value objects and business logic.

import 'package:hive/hive.dart';

part 'financial_goal.g.dart';

/// Enum representing the current status of a financial goal.
/// Used to track whether a goal is active, completed, or temporarily paused.
@HiveType(typeId: 10)
enum GoalStatus {
  /// Goal is currently active and being tracked
  @HiveField(0)
  active,
  /// Goal has been successfully completed
  @HiveField(1)
  completed,
  /// Goal is temporarily paused/suspended
  @HiveField(2)
  paused,
}

/// The FinancialGoal entity represents a financial target or savings goal.
/// It tracks progress towards a target amount within a specified timeframe.
/// This entity includes business logic for calculating progress and status.
@HiveType(typeId: 11)
class FinancialGoal extends HiveObject {
  /// Unique identifier for this financial goal (UUID string)
  @HiveField(0)
  final String id;

  /// Human-readable title for the goal (e.g., 'Emergency Fund', 'Vacation Fund')
  @HiveField(1)
  final String title;

  /// The target amount to reach (must be positive)
  @HiveField(2)
  final double targetAmount;

  /// Current progress amount towards the goal (can be updated)
  @HiveField(3)
  double currentAmount;

  /// When the goal was started/created
  @HiveField(4)
  final DateTime startDate;

  /// Target date to achieve this goal
  @HiveField(5)
  final DateTime targetDate;

  /// Optional category for grouping goals (e.g., 'savings', 'investment')
  @HiveField(6)
  final String? category;

  /// Current status of the goal (active, completed, or paused)
  @HiveField(7)
  GoalStatus status;

  /// Constructor for FinancialGoal. Most fields are required for a complete goal definition.
  /// Status defaults to active when not specified.
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

  /// Calculates the progress percentage towards the target (0-100+).
  /// Returns 0 if target amount is 0 to avoid division by zero.
  /// Can exceed 100% if current amount surpasses the target.
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  /// Returns true if the goal has been marked as completed.
  bool get isCompleted => status == GoalStatus.completed;
  
  /// Returns true if the goal is currently active and being tracked.
  bool get isActive => status == GoalStatus.active;
  
  /// Returns true if the goal is temporarily paused.
  bool get isPaused => status == GoalStatus.paused;

  /// Returns true if the target date has passed and the goal is not completed.
  /// Useful for showing overdue warnings in the UI.
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  /// Calculates the number of days remaining until the target date.
  /// Returns 0 if the target date has already passed.
  /// Useful for showing countdown timers and urgency indicators.
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Creates a copy of this financial goal with the specified fields replaced.
  /// This follows the immutability pattern for safer state management.
  /// Only non-null parameters will replace the existing values.
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

  /// Equality operator for comparing two FinancialGoal instances.
  /// Two goals are considered equal if all their fields match.
  /// This is important for proper state management and UI updates.
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

  /// Hash code implementation that considers all fields.
  /// Required when overriding the equality operator.
  /// Used by collections like Set and Map for efficient lookups.
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

  /// String representation of this financial goal for debugging purposes.
  /// Includes all important fields to help with development and logging.
  @override
  String toString() {
    return 'FinancialGoal(id: $id, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, targetDate: $targetDate, category: $category, status: $status)';
  }
}
