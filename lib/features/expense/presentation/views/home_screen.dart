// This file defines the HomeScreen, which is the main navigation hub of the app.
// It manages the bottom navigation tabs and provides access to the overview and statistics screens.
// This demonstrates proper navigation structure and platform-specific UI adaptation.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_list.dart';
import '../widgets/add_expense_fab.dart';
import 'stats_screen.dart';
import 'add_expense_screen.dart';
import 'filter_screen.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/presentation/widgets/budget_card.dart';
import '../../../export/presentation/views/export_screen.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';

/// The main screen of the app that contains the bottom navigation and manages tabs.
/// This screen acts as a container for the overview and statistics tabs.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Current active tab index (0 = Overview, 1 = Statistics)
  int _currentIndex = 0;

  // List of screens to display in the bottom navigation
  final List<Widget> _screens = [
    const ExpenseOverviewTab(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Platform-specific navigation structure
    if (PlatformWidgets.isIOS) {
      // iOS uses CupertinoTabScaffold for native tab navigation
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                  PlatformWidgets.isIOS ? CupertinoIcons.home : Icons.home),
              label: localizations.overview,
            ),
            BottomNavigationBarItem(
              icon: Icon(PlatformWidgets.isIOS
                  ? CupertinoIcons.chart_bar
                  : Icons.bar_chart),
              label: localizations.stats,
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => CupertinoPageScaffold(
              navigationBar: index == 0
                  ? CupertinoNavigationBar(
                      middle: Text(localizations.appTitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => const FilterScreen(),
                                ),
                              );
                            },
                            child: const Icon(CupertinoIcons.search),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => const ExportScreen(),
                                ),
                              );
                            },
                            child: const Icon(CupertinoIcons.square_arrow_up),
                          ),
                        ],
                      ),
                    )
                  : null,
              child: _screens[index],
            ),
          );
        },
      );
    } else {
      // Android uses Scaffold with bottom navigation bar
      return PlatformWidgets.buildScaffold(
        context: context,
        appBar: _currentIndex == 0
            ? PlatformWidgets.buildAppBar(
                context: context,
                title: localizations.appTitle,
                actions: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SyncStatusIndicator(),
                  ),
                  PlatformWidgets.platformActionButton(
                    context: context,
                    icon: PlatformWidgets.isIOS
                        ? CupertinoIcons.search
                        : Icons.filter_list,
                    tooltip: 'Filter Expenses',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FilterScreen(),
                        ),
                      );
                    },
                  ),
                  PlatformWidgets.platformActionButton(
                    context: context,
                    icon: PlatformWidgets.isIOS
                        ? CupertinoIcons.square_arrow_up
                        : Icons.file_download,
                    tooltip: 'Export Data',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              )
            : null,
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNavigationBar(localizations),
        floatingActionButton: _currentIndex == 0 ? const AddExpenseFAB() : null,
      );
    }
  }

  /// Builds the bottom navigation bar for Android platform.
  /// This provides tab switching functionality for the overview and statistics screens.
  Widget _buildBottomNavigationBar(AppLocalizations localizations) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(PlatformWidgets.isIOS ? CupertinoIcons.home : Icons.home),
          label: localizations.overview,
        ),
        BottomNavigationBarItem(
          icon: Icon(PlatformWidgets.isIOS
              ? CupertinoIcons.chart_bar
              : Icons.bar_chart),
          label: localizations.stats,
        ),
      ],
    );
  }
}

/// The overview tab that displays the main expense list and summary cards.
/// This is the primary screen users interact with to view and manage their expenses.
class ExpenseOverviewTab extends ConsumerWidget {
  const ExpenseOverviewTab({super.key});

  /// Navigates to the edit expense screen with the selected expense.
  /// Handles the navigation logic for editing expenses.
  void _navigateToEditExpense(BuildContext context, Expense expense) {
    if (PlatformWidgets.isIOS) {
      // iOS-style navigation with slide transition
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AddExpenseScreen(expense: expense),
          fullscreenDialog: false,
        ),
      );
    } else {
      // Android-style navigation with material transition
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(expense: expense),
          fullscreenDialog: false,
        ),
      );
    }
  }

  /// Deletes an expense and ensures proper refresh of the overview list.
  /// Handles the deletion process for the main expense list.
  void _deleteExpense(Expense expense, WidgetRef ref) async {
    try {
      // Delete the expense using the provider
      await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
      
      // Force refresh the provider to ensure immediate UI update
      ref.invalidate(expenseNotifierProvider);
      
      // Show success feedback to the user
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Expense "${expense.title}" deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Show error feedback to the user
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // Watch the expenses provider to rebuild when data changes
    final expensesAsync = ref.watch(expenseNotifierProvider);

    return expensesAsync.when(
      // Loading state: show a loading indicator
      loading: () => Center(
        child: PlatformWidgets.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      ),
      // Error state: show error message with retry option
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localizations.errorLoadingExpenses),
            const SizedBox(height: AppConstants.paddingM),
            PlatformWidgets.buildButton(
              context: context,
              onPressed: () {
                // Retry loading expenses
                ref.refresh(expenseNotifierProvider);
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
      // Data state: show the expense list and summary
      data: (expenses) {
        if (expenses.isEmpty) {
          // Empty state: show message encouraging user to add first expense
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PlatformWidgets.isIOS
                      ? CupertinoIcons.money_dollar_circle
                      : Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  localizations.noExpenses,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  localizations.addFirstExpense,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        // Normal state: show expense list with summary cards
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards showing financial overview - optimized with lazy loading
              _buildOptimizedSummaryCard(ref),
              const SizedBox(height: AppConstants.paddingL),

              // Budget alerts section
              _buildBudgetAlertsSection(context, ref),
              const SizedBox(height: AppConstants.paddingL),

              // Title for the expense list
              Text(
                localizations.overview,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.paddingM),

              // List of all expenses
              ExpenseList(
                expenses: expenses,
                onExpenseTap: (expense) =>
                    _navigateToEditExpense(context, expense),
                onExpenseDelete: (expense) => _deleteExpense(expense, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build optimized summary card with lazy loading
  Widget _buildOptimizedSummaryCard(WidgetRef ref) {
    return ref.watch(expenseStatsNotifierProvider).when(
          data: (stats) => ExpenseSummaryCard(stats: stats),
          loading: () =>
              const SizedBox(height: 100), // Reduced loading indicator
          error: (error, stack) =>
              const SizedBox.shrink(), // Hide errors initially
        );
  }

  /// Builds the budget alerts section showing budgets that need attention.
  Widget _buildBudgetAlertsSection(BuildContext context, WidgetRef ref) {
    return ref.watch(budgetsWithAlertsProvider).when(
          data: (budgetsWithAlerts) {
            if (budgetsWithAlerts.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Alerts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${budgetsWithAlerts.length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                ...budgetsWithAlerts.map((budget) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BudgetCard(budget: budget),
                    )),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
  }
}
