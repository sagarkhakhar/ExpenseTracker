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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ExpenseOverviewTab(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (PlatformWidgets.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.home, semanticLabel: 'Home'),
              activeIcon:
                  const Icon(CupertinoIcons.house_fill, semanticLabel: 'Home'),
              label: localizations.overview,
            ),
            BottomNavigationBarItem(
              icon:
                  const Icon(CupertinoIcons.chart_bar, semanticLabel: 'Stats'),
              activeIcon: const Icon(CupertinoIcons.chart_bar_fill,
                  semanticLabel: 'Stats'),
              label: localizations.stats,
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) {
              if (index == 0) {
                return CupertinoPageScaffold(
                  navigationBar: PlatformWidgets.buildAppBar(
                    context: context,
                    title: localizations.appTitle,
                    actions: [
                      PlatformWidgets.platformActionButton(
                        context: context,
                        icon: CupertinoIcons.search,
                        tooltip: localizations.overview,
                        onPressed: () {
                          // TODO: Implement filter functionality
                        },
                      ),
                    ],
                  ) as ObstructingPreferredSizeWidget?,
                  child: const SafeArea(child: ExpenseOverviewTab()),
                );
              } else {
                return CupertinoPageScaffold(
                  navigationBar: PlatformWidgets.buildAppBar(
                    context: context,
                    title: localizations.stats,
                  ) as ObstructingPreferredSizeWidget?,
                  child: const SafeArea(child: StatsScreen()),
                );
              }
            },
          );
        },
      );
    } else {
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

  Widget _buildBottomNavigationBar(AppLocalizations localizations) {
    if (PlatformWidgets.isIOS) {
      return CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.home, semanticLabel: 'Home'),
            activeIcon:
                const Icon(CupertinoIcons.house_fill, semanticLabel: 'Home'),
            label: localizations.overview,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chart_bar, semanticLabel: 'Stats'),
            activeIcon: const Icon(CupertinoIcons.chart_bar_fill,
                semanticLabel: 'Stats'),
            label: localizations.stats,
          ),
        ],
      );
    } else {
      return BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined, semanticLabel: 'Home'),
            activeIcon: const Icon(Icons.home, semanticLabel: 'Home'),
            label: localizations.overview,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics_outlined, semanticLabel: 'Stats'),
            activeIcon: const Icon(Icons.analytics, semanticLabel: 'Stats'),
            label: localizations.stats,
          ),
        ],
      );
    }
  }
}

class ExpenseOverviewTab extends ConsumerWidget {
  const ExpenseOverviewTab({super.key});

  void _editExpense(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      PlatformWidgets.isIOS
          ? CupertinoPageRoute(
              builder: (_) => AddExpenseScreen(expense: expense),
            )
          : MaterialPageRoute(
              builder: (_) => AddExpenseScreen(expense: expense),
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final statsAsync = ref.watch(expenseStatsNotifierProvider);

    if (PlatformWidgets.isIOS) {
      // Use slivers for iOS
      return PlatformWidgets.buildRefreshSliverIndicator(
        onRefresh: () async {
          ref.invalidate(expenseNotifierProvider);
        },
        slivers: expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.center,
                    child: _buildEmptyState(localizations),
                  ),
                ),
              ];
            }
            return [
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => ExpenseSummaryCard(stats: stats),
                  loading: () => const CupertinoActivityIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ),
              ExpenseList.sliver(
                context: context,
                expenses: expenses,
                onDelete: (expense) async {
                  await ref
                      .read(expenseNotifierProvider.notifier)
                      .deleteExpense(expense.id);
                },
                onEdit: (expense) => _editExpense(context, expense),
              ),
            ];
          },
          loading: () => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: PlatformWidgets.buildLoadingIndicator()),
            ),
          ],
          error: (error, stack) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 64,
                      color: AppConstants.errorColor,
                      semanticLabel: localizations.errorLoadingExpenses,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(localizations.errorLoadingExpenses,
                        style: AppTextStyles.heading3),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      error.toString(),
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    PlatformWidgets.buildButton(
                      context: context,
                      onPressed: () {
                        ref.invalidate(expenseNotifierProvider);
                      },
                      child: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Android: keep Column+Expanded
      return PlatformWidgets.buildRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expenseNotifierProvider);
        },
        child: expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return _buildEmptyState(localizations);
            }
            return Column(
              children: [
                statsAsync.when(
                  data: (stats) => ExpenseSummaryCard(stats: stats),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                Expanded(
                  child: ExpenseList(
                    expenses: expenses,
                    onDelete: (expense) async {
                      await ref
                          .read(expenseNotifierProvider.notifier)
                          .deleteExpense(expense.id);
                    },
                    onEdit: (expense) => _editExpense(context, expense),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: PlatformWidgets.buildLoadingIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppConstants.errorColor,
                  semanticLabel: localizations.errorLoadingExpenses,
                ),
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  localizations.errorLoadingExpenses,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  error.toString(),
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingM),
                PlatformWidgets.buildButton(
                  context: context,
                  onPressed: () {
                    ref.invalidate(expenseNotifierProvider);
                  },
                  child: Text(localizations.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          PlatformWidgets.isIOS
              ? CupertinoIcons.creditcard
              : Icons.account_balance_wallet_outlined,
          size: 64,
          color: AppConstants.textTertiary,
          semanticLabel: localizations.noExpenses,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Text(localizations.noExpenses, style: AppTextStyles.heading3),
        const SizedBox(height: AppConstants.paddingS),
        Text(
          localizations.addFirstExpense,
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
