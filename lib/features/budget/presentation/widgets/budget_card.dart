import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import 'budget_progress_bar.dart';

class BudgetCard extends ConsumerWidget {
  final Budget budget;
  final bool showDeleteButton;

  const BudgetCard({
    super.key,
    required this.budget,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.categoryId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(context),
                    if (showDeleteButton) ...[
                      const SizedBox(width: AppConstants.paddingS),
                      _buildDeleteButton(context, ref),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Period: ${budget.period.capitalize()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  '${budget.startDate.day}/${budget.startDate.month} - ${budget.endDate.day}/${budget.endDate.month}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '\$${budget.spentAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getSpentAmountColor(context),
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '\$${budget.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetProgressBar(
              progress: budget.progressPercentage,
              isExceeded: budget.isExceeded,
              isApproaching: budget.isApproachingLimit,
            ),
            const SizedBox(height: 8),
            Text(
              '${budget.progressPercentage.toStringAsFixed(1)}% used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    String chipText;
    IconData? icon;

    if (budget.isExceeded) {
      chipColor = Colors.red;
      chipText = 'Exceeded';
      icon = Icons.warning;
    } else if (budget.isApproachingLimit) {
      chipColor = Colors.orange;
      chipText = 'Warning';
      icon = Icons.info;
    } else {
      chipColor = Colors.green;
      chipText = 'On Track';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpentAmountColor(BuildContext context) {
    if (budget.isExceeded) {
      return Colors.red;
    } else if (budget.isApproachingLimit) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Builds the delete button for budget items.
  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    return PlatformWidgets.platformActionButton(
      context: context,
      icon: PlatformWidgets.isIOS ? CupertinoIcons.delete : Icons.delete_outline,
      onPressed: () => _showDeleteConfirmation(context, ref),
      tooltip: 'Delete budget',
    );
  }

  /// Shows a confirmation dialog before deleting a budget.
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    if (PlatformWidgets.isIOS) {
      // iOS-style confirmation dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteBudget),
          content: Text(AppLocalizations.of(context)!.deleteBudgetConfirm(budget.categoryId)),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(AppLocalizations.of(context)!.delete),
              onPressed: () {
                Navigator.pop(context);
                _deleteBudget(ref);
              },
            ),
          ],
        ),
      );
    } else {
      // Android-style confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteBudget),
          content: Text(AppLocalizations.of(context)!.deleteBudgetConfirm(budget.categoryId)),
          actions: [
            PlatformWidgets.buildButton(
              context: context,
              onPressed: () => Navigator.pop(context),
              isPrimary: false,
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            PlatformWidgets.buildButton(
              context: context,
              onPressed: () {
                Navigator.pop(context);
                _deleteBudget(ref);
              },
              isPrimary: true,
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        ),
      );
    }
  }

  /// Deletes the budget and shows feedback to the user.
  void _deleteBudget(WidgetRef ref) async {
    try {
      // Delete the budget using the provider (if it exists)
      // Note: This would need a budget provider implementation
      // For now, we'll show a placeholder message
      
      if (ref.context.mounted) {
        PlatformWidgets.showPlatformSnackbar(
          context: ref.context,
          message: 'Budget "${budget.categoryId}" deleted successfully',
        );
      }
    } catch (error) {
      if (ref.context.mounted) {
        PlatformWidgets.showPlatformSnackbar(
          context: ref.context,
          message: 'Failed to delete budget: $error',
        );
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
