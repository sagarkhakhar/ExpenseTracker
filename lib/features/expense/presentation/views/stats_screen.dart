import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_pie_chart.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../shared/widgets/platform_widgets.dart';

class SmartTipsCard extends ConsumerWidget {
  const SmartTipsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(smartTipsNotifierProvider);
    final localizations = AppLocalizations.of(context)!;
    List<String> localizeTips(List<String> tipKeys) {
      return tipKeys.map((key) {
        if (key.startsWith('tipCategorySpike:')) {
          final cat = key.split(':').length > 1 ? key.split(':')[1] : '';
          return localizations.tipCategorySpike(cat);
        }
        switch (key) {
          case 'tipHighSpending':
            return localizations.tipHighSpending;
          case 'tipNoIncome':
            return localizations.tipNoIncome;
          case 'tipNegativeBalance':
            return localizations.tipNegativeBalance;
          case 'tipFewExpenses':
            return localizations.tipFewExpenses;
          case 'tipAllGood':
            return localizations.tipAllGood;
          default:
            return key;
        }
      }).toList();
    }

    return Semantics(
      label: localizations.smartTips,
      header: true,
      child: tipsAsync.when(
        data: (tipKeys) {
          final tips = localizeTips(tipKeys);
          return PlatformWidgets.isIOS
              ? Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingL),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                      vertical: AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.lightbulb,
                            color: CupertinoColors.activeBlue,
                            size: 28,
                            semanticLabel: localizations.smartTips,
                          ),
                          const SizedBox(width: 8),
                          Text(localizations.smartTips,
                              style: AppTextStyles.heading3),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      ...tips.map((tip) => Semantics(
                            label: tip,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppConstants.paddingXS),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('\u2022 ', style: AppTextStyles.caption),
                                  Expanded(child: Text(tip)),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                )
              : Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingL),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusL)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingL,
                        vertical: AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                              semanticLabel: localizations.smartTips,
                            ),
                            const SizedBox(width: 8),
                            Text(localizations.smartTips,
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingS),
                        ...tips.map((tip) => Semantics(
                              label: tip,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppConstants.paddingXS),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('\u2022 ',
                                        style: AppTextStyles.caption),
                                    Expanded(child: Text(tip)),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Semantics(
          label: localizations.noData,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(expenseStatsNotifierProvider);
    return PlatformWidgets.buildScaffold(
      context: context,
      appBar: PlatformWidgets.buildAppBar(
        context: context,
        title: localizations.stats,
      ),
      body: statsAsync.when(
        data: (stats) {
          final expenseBreakdown =
              stats['categoryExpenseBreakdown'] as Map<String, double>? ?? {};
          final incomeBreakdown =
              stats['categoryIncomeBreakdown'] as Map<String, double>? ?? {};
          final dailyTotals =
              stats['dailyTotals'] as Map<DateTime, Map<String, double>>? ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SmartTipsCard(),
                ExpenseTrendChart(
                  dailyTotals: dailyTotals,
                  title: localizations.dailyTrend,
                ),
                const SizedBox(height: AppConstants.paddingXL),
                ExpenseSummaryCard(stats: stats),
                const SizedBox(height: AppConstants.paddingL),
                ExpensePieChart(
                  categoryBreakdown: expenseBreakdown,
                  title: localizations.expensesByCategory,
                ),
                const SizedBox(height: AppConstants.paddingXL),
                ExpensePieChart(
                  categoryBreakdown: incomeBreakdown,
                  title: localizations.incomeByCategory,
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: PlatformWidgets.buildLoadingIndicator(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PlatformWidgets.isIOS
                    ? CupertinoIcons.exclamationmark_triangle
                    : Icons.error_outline,
                size: 64,
                color: Colors.red,
                semanticLabel: localizations.errorLoadingExpenses,
              ),
              const SizedBox(height: 16),
              Text(localizations.errorLoadingExpenses),
              const SizedBox(height: 8),
              Text(e.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
