import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_card.dart';
import '../../../../shared/widgets/platform_widgets.dart';

class BudgetManagementScreen extends ConsumerStatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  ConsumerState<BudgetManagementScreen> createState() =>
      _BudgetManagementScreenState();
}

class _BudgetManagementScreenState
    extends ConsumerState<BudgetManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  String _selectedPeriod = 'monthly';
  final List<String> _periods = ['weekly', 'monthly', 'yearly'];

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.buildTextField(
                context: context,
                label: 'Category',
                controller: _categoryController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PlatformWidgets.buildTextField(
                context: context,
                label: 'Amount',
                hint: '\$0.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PlatformWidgets.buildPlatformDropdown<String>(
                context: context,
                value: _selectedPeriod,
                items: _periods,
                itemBuilder: (period) => Text(period.capitalize()),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
                label: 'Period',
              ),
            ],
          ),
        ),
        actions: [
          PlatformWidgets.buildButton(
            context: context,
            onPressed: () => Navigator.of(context).pop(),
            isPrimary: false,
            child: const Text('Cancel'),
          ),
          PlatformWidgets.buildButton(
            context: context,
            onPressed: _addBudget,
            isPrimary: true,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addBudget() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final categoryId = _categoryController.text;
      final now = DateTime.now();

      // Calculate start and end dates based on period
      DateTime startDate, endDate;
      switch (_selectedPeriod) {
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        default:
          startDate = now;
          endDate = now.add(const Duration(days: 30));
      }

      final budget = Budget(
        id: const Uuid().v4(),
        categoryId: categoryId,
        amount: amount,
        period: _selectedPeriod,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
      );

      ref.read(budgetNotifierProvider.notifier).createBudget(budget);

      _amountController.clear();
      _categoryController.clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final budgetNotifier = ref.watch(budgetNotifierProvider);

    return PlatformWidgets.buildScaffold(
      context: context,
      appBar: PlatformWidgets.buildAppBar(
        context: context,
        title: 'Budget Management',
        actions: [
          PlatformWidgets.platformActionButton(
            context: context,
            icon: Icons.add,
            onPressed: _showAddBudgetDialog,
            tooltip: 'Add Budget',
          ),
        ],
      ),
      body: budgetNotifier.when(
        loading: () => Center(child: PlatformWidgets.buildLoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (_) => budgetsAsync.when(
          loading: () => Center(child: PlatformWidgets.buildLoadingIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
          data: (budgets) => budgets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No budgets yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first budget',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BudgetCard(budget: budget),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
