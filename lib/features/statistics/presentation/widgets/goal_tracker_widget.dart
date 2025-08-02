// This file defines the GoalTrackerWidget, which displays financial goal progress.
// It shows goal details, progress bars, and status indicators.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

/// A widget that displays financial goal progress with visual indicators.
class GoalTrackerWidget extends StatelessWidget {
  /// The goal data to display.
  final dynamic goal;

  /// Constructor with required goal data.
  const GoalTrackerWidget({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final title = goal.title as String? ?? 'Unknown Goal';
    final targetAmount = goal.targetAmount as double? ?? 0.0;
    final currentAmount = goal.currentAmount as double? ?? 0.0;
    final startDate = goal.startDate as DateTime? ?? DateTime.now();
    final targetDate = goal.targetDate as DateTime? ?? DateTime.now();
    final status = goal.status as String? ?? 'active';
    final category = goal.category as String?;

    final progress = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
    final daysRemaining = targetDate.difference(DateTime.now()).inDays;
    final isCompleted = status.toLowerCase() == 'completed';
    final isOverdue = daysRemaining < 0 && !isCompleted;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal header with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(status, isOverdue),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),

            // Category (if available)
            if (category != null && category.isNotEmpty) ...[
              Text(
                'Category: $category',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: AppConstants.paddingS),
            ],

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(progress),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingXS),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  '${CurrencyUtils.formatCurrency(currentAmount)} / ${CurrencyUtils.formatCurrency(targetAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),

            // Date information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Started',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      app_date_utils.DateUtils.formatDate(startDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isCompleted ? 'Completed' : 'Target',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      app_date_utils.DateUtils.formatDate(targetDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isOverdue ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // Days remaining or overdue indicator
            if (!isCompleted) ...[
              const SizedBox(height: AppConstants.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverdue
                        ? Colors.red.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.schedule,
                      size: 12,
                      color: isOverdue ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? '${daysRemaining.abs()} days overdue'
                          : '$daysRemaining days remaining',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the status chip with appropriate color and text.
  Widget _buildStatusChip(String status, bool isOverdue) {
    Color chipColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'paused':
        chipColor = Colors.orange;
        statusText = 'Paused';
        break;
      case 'active':
      default:
        if (isOverdue) {
          chipColor = Colors.red;
          statusText = 'Overdue';
        } else {
          chipColor = Colors.blue;
          statusText = 'Active';
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Gets the color for progress based on completion percentage.
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return Colors.green;
    } else if (progress >= 0.5) {
      return Colors.orange;
    } else if (progress >= 0.25) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}
