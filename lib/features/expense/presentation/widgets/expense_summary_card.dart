import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A summary card widget showing total expenses, income, balance, and category breakdown.
class ExpenseSummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const ExpenseSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final totalExpenses = stats['totalExpenses'] ?? 0.0;
    final totalIncome = stats['totalIncome'] ?? 0.0;
    final balance = stats['balance'] ?? 0.0;
    final categoryBreakdown =
        stats['categoryBreakdown'] as Map<String, double>? ?? {};

    return Semantics(
      // TODO: Add a more descriptive summary label to ARB if needed
      label: '${localizations.expense}, ${localizations.income}, Balance',
      child: PlatformWidgets.isIOS
          ? Container(
              margin: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: localizations.expense,
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                totalExpenses),
                            color: AppConstants.errorColor,
                            semanticsLabel: '${localizations.expense}: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(totalExpenses)}',
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: localizations.income,
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                totalIncome),
                            color: AppConstants.successColor,
                            semanticsLabel: '${localizations.income}: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(totalIncome)}',
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Balance',
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                balance),
                            color: AppConstants.primaryColor,
                            semanticsLabel: 'Balance: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(balance)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text('By Category', style: AppTextStyles.body2),
                    const SizedBox(height: AppConstants.paddingXS),
                    Wrap(
                      spacing: AppConstants.paddingS,
                      runSpacing: AppConstants.paddingXS,
                      children: categoryBreakdown.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingM,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${entry.key}: ${CurrencyUtils.formatCurrency(entry.value)}',
                            style: AppTextStyles.caption,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            )
          : Card(
              margin: const EdgeInsets.all(AppConstants.paddingM),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: localizations.expense,
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                totalExpenses),
                            color: AppConstants.errorColor,
                            semanticsLabel: '${localizations.expense}: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(totalExpenses)}',
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: localizations.income,
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                totalIncome),
                            color: AppConstants.successColor,
                            semanticsLabel: '${localizations.income}: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(totalIncome)}',
                          ),
                        ),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Balance',
                            value: CurrencyUtils.formatAbbreviatedCurrency(
                                balance),
                            color: AppConstants.primaryColor,
                            semanticsLabel: 'Balance: '
                                '${CurrencyUtils.formatAbbreviatedCurrency(balance)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text('By Category', style: AppTextStyles.body2),
                    const SizedBox(height: AppConstants.paddingXS),
                    Wrap(
                      spacing: AppConstants.paddingS,
                      runSpacing: AppConstants.paddingXS,
                      children: categoryBreakdown.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingM,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor
                                .withAlpha((0.1 * 255).toInt()),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: Text(
                            '${entry.key}: ${CurrencyUtils.formatCurrency(entry.value)}',
                            style: AppTextStyles.caption,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A tile for displaying a summary value and label with semantics.
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? semanticsLabel;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Semantics(
          label: semanticsLabel ?? value,
          child: Text(value,
              style: AppTextStyles.heading3.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
