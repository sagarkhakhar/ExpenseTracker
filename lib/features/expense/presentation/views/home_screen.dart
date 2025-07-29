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
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../l10n/app_localizations.dart';

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
            builder: (context) => _screens[index],
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
                  PlatformWidgets.platformActionButton(
                    context: context,
                    icon: PlatformWidgets.isIOS
                        ? CupertinoIcons.search
                        : Icons.filter_list,
                    tooltip: localizations.overview,
                    onPressed: () {
                      // TODO: Implement filter functionality
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
              // Summary cards showing financial overview
              ref.watch(expenseStatsNotifierProvider).when(
                data: (stats) => ExpenseSummaryCard(stats: stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading stats: $error'),
              ),
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
                onExpenseTap: (expense) => _navigateToEditExpense(context, expense),
              ),
            ],
          ),
        );
      },
    );
  }
}
