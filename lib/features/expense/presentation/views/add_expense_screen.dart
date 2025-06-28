import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late double _amount;
  late ExpenseCategory _category;
  late ExpenseType _type;
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _title = e?.title ?? '';
    _description = e?.description ?? '';
    _amount = e?.amount ?? 0.0;
    _category = e?.category ?? ExpenseCategory.other;
    _type = e?.type ?? ExpenseType.expense;
    _date = e?.date ?? DateTime.now();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    try {
      if (widget.expense != null) {
        // Edit
        final updated = widget.expense!.copyWith(
          title: _title,
          description: _description,
          amount: _amount,
          category: _category,
          type: _type,
          date: _date,
          updatedAt: DateTime.now(),
        );
        await ref.read(expenseNotifierProvider.notifier).updateExpense(updated);
      } else {
        // Add new
        await ref.read(expenseNotifierProvider.notifier).addExpense(
              title: _title,
              description: _description,
              amount: _amount,
              category: _category,
              type: _type,
              date: _date,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to ${widget.expense != null ? 'edit' : 'add'} expense: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onSaved: (v) => _title = v ?? '',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    onSaved: (v) => _description = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _amount == 0.0 ? '' : _amount.toString(),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _amount = double.tryParse(v ?? '') ?? 0.0,
                    validator: (v) => (double.tryParse(v ?? '') ?? 0.0) <= 0
                        ? 'Enter a valid amount'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ExpenseCategory.values
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? ExpenseCategory.other),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ExpenseType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _type = v ?? ExpenseType.expense),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(widget.expense != null
                              ? 'Save Changes'
                              : 'Add Expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
