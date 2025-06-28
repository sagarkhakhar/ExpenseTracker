import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_list.dart';
import '../widgets/add_expense_fab.dart';
import 'stats_screen.dart';
import 'add_expense_screen.dart';

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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Stats',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? const AddExpenseFAB() : null,
    );
  }
}

class ExpenseOverviewTab extends ConsumerWidget {
  const ExpenseOverviewTab({super.key});

  void _editExpense(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expense: expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final statsAsync = ref.watch(expenseStatsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expenseNotifierProvider);
        },
        child: expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return _buildEmptyState();
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
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  'Error loading expenses',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  error.toString(),
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingM),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(expenseNotifierProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppConstants.textTertiary,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text('No expenses yet', style: AppTextStyles.heading3),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Add your first expense to get started',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
