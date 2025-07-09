import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../../data/datasources/expense_local_data_source_impl.dart';

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
  late String _category;
  late ExpenseType _type;
  late DateTime _date;
  bool _loading = false;
  List<String> _categories = [];
  bool _isRecurring = false;
  String? _recurringFrequency;
  DateTime? _nextOccurrence;
  DateTime? _endDate;
  final List<String> _frequencyOptions = [
    'daily',
    'weekly',
    'monthly',
    'custom'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _title = e?.title ?? '';
    _description = e?.description ?? '';
    _amount = e?.amount ?? 0.0;
    _category = e?.category ?? 'other';
    _type = e?.type ?? ExpenseType.expense;
    _date = e?.date ?? DateTime.now();
    _isRecurring = e?.isRecurring ?? false;
    _recurringFrequency = e?.recurringFrequency;
    _nextOccurrence = e?.nextOccurrence;
    _endDate = e?.endDate;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final ds = CategoryLocalDataSourceImpl();
    await ds.init();
    setState(() {
      _categories = ds.getCategories();
      if (!_categories.contains(_category)) {
        _category = _categories.isNotEmpty ? _categories.first : 'other';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Additional manual validation
    if (_category.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid category.')),
      );
      return;
    }
    if (_amount.isNaN ||
        _amount.isInfinite ||
        _amount <= 0 ||
        _amount > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Enter a valid, positive amount (max \$1,000,000).')),
      );
      return;
    }
    if (_type == ExpenseType.income && _amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income cannot be negative.')),
      );
      return;
    }
    if (_isRecurring) {
      if (_recurringFrequency == null || _recurringFrequency!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a recurring frequency.')),
        );
        return;
      }
      if (_nextOccurrence == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select next occurrence date.')),
        );
        return;
      }
      if (_nextOccurrence!.isBefore(_date)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Next occurrence must be after or equal to the main date.')),
        );
        return;
      }
      if (_endDate != null && _endDate!.isBefore(_nextOccurrence!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End date must be after next occurrence.')),
        );
        return;
      }
    }
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
          isRecurring: _isRecurring,
          recurringFrequency: _isRecurring ? _recurringFrequency : null,
          nextOccurrence: _isRecurring ? _nextOccurrence : null,
          endDate: _isRecurring ? _endDate : null,
        );
        // Defensive validation before saving
        if (updated.title.trim().isEmpty ||
            updated.category.trim().isEmpty ||
            updated.amount.isNaN ||
            updated.amount.isInfinite ||
            updated.amount <= 0 ||
            (_isRecurring &&
                (_recurringFrequency == null ||
                    _recurringFrequency!.isEmpty ||
                    _nextOccurrence == null ||
                    (_endDate != null &&
                        _endDate!.isBefore(_nextOccurrence!))))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid data. Please check all fields.')),
          );
          setState(() => _loading = false);
          return;
        }
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
              isRecurring: _isRecurring,
              recurringFrequency: _isRecurring ? _recurringFrequency : null,
              nextOccurrence: _isRecurring ? _nextOccurrence : null,
              endDate: _isRecurring ? _endDate : null,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to  ${widget.expense != null ? 'edit' : 'add'} expense: $e')),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _categories.contains(_category)
                              ? _category
                              : (_categories.isNotEmpty
                                  ? _categories.first
                                  : null),
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: _categories
                              .where((cat) => cat.trim().isNotEmpty)
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? 'other'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Manage Categories',
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => _CategoryManagerDialog(
                                onChanged: _loadCategories),
                          );
                        },
                      ),
                    ],
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
                  const SizedBox(height: 16),
                  // Recurring toggle
                  SwitchListTile(
                    value: _isRecurring,
                    title: const Text('Recurring'),
                    onChanged: (val) => setState(() => _isRecurring = val),
                  ),
                  if (_isRecurring) ...[
                    DropdownButtonFormField<String>(
                      value: _recurringFrequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: _frequencyOptions
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child:
                                    Text(f[0].toUpperCase() + f.substring(1)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _recurringFrequency = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select frequency' : null,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Next Occurrence'),
                      subtitle: Text(_nextOccurrence != null
                          ? '${_nextOccurrence!.toLocal()}'.split(' ')[0]
                          : 'Select date'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _nextOccurrence ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _nextOccurrence = picked);
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date (optional)'),
                      subtitle: Text(_endDate != null
                          ? '${_endDate!.toLocal()}'.split(' ')[0]
                          : 'Select date'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                  ],
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

class _CategoryManagerDialog extends StatefulWidget {
  final VoidCallback onChanged;
  const _CategoryManagerDialog({required this.onChanged});

  @override
  State<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<_CategoryManagerDialog> {
  late CategoryLocalDataSourceImpl _ds;
  List<String> _categories = [];
  final _controller = TextEditingController();
  String? _editing;

  @override
  void initState() {
    super.initState();
    _ds = CategoryLocalDataSourceImpl();
    _ds.init().then((_) {
      setState(() => _categories = _ds.getCategories());
    });
  }

  void _refresh() {
    setState(() => _categories = _ds.getCategories());
    widget.onChanged();
  }

  bool _isDuplicateCategory(String val) {
    return _categories.any((cat) => cat.toLowerCase() == val.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._categories.map((cat) => ListTile(
                  title: _editing == cat
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          onSubmitted: (val) async {
                            final trimmed = val.trim();
                            if (trimmed.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Category name cannot be empty.')),
                              );
                              return;
                            }
                            if (_isDuplicateCategory(trimmed) &&
                                trimmed != cat) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Duplicate category name.')),
                              );
                              return;
                            }
                            await _ds.editCategory(cat, trimmed);
                            _editing = null;
                            _controller.clear();
                            _refresh();
                          },
                        )
                      : Text(cat),
                  trailing: CategoryLocalDataSourceImpl.defaultCategories
                          .contains(cat)
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _editing = cat;
                                  _controller.text = cat;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final success = await _ds.deleteCategory(cat);
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Cannot delete: Category is in use.')),
                                  );
                                } else {
                                  _refresh();
                                }
                              },
                            ),
                          ],
                        ),
                )),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Add new category'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final val = _controller.text.trim();
                    if (val.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Category name cannot be empty.')),
                      );
                      return;
                    }
                    if (_isDuplicateCategory(val)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Duplicate category name.')),
                      );
                      return;
                    }
                    await _ds.addCategory(val);
                    _controller.clear();
                    _refresh();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
