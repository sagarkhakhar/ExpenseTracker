import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../../data/datasources/expense_local_data_source_impl.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
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
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _amountController = TextEditingController(
        text: e?.amount == null || e!.amount == 0.0 ? '' : e.amount.toString());
    _category = e?.category ?? 'other';
    _type = e?.type ?? ExpenseType.expense;
    _date = e?.date ?? DateTime.now();
    _isRecurring = e?.isRecurring ?? false;
    _recurringFrequency = e?.recurringFrequency;
    _nextOccurrence = e?.nextOccurrence;
    _endDate = e?.endDate;
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
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
      PlatformWidgets.showPlatformSnackbar(
        context: context,
        message: 'Please select a valid category.',
      );
      return;
    }
    if (_amountController.text.trim().isEmpty ||
        double.tryParse(_amountController.text.trim()) == null ||
        double.tryParse(_amountController.text.trim())! <= 0 ||
        double.tryParse(_amountController.text.trim())! > 1000000) {
      PlatformWidgets.showPlatformSnackbar(
        context: context,
        message: 'Enter a valid, positive amount (max \$1,000,000).',
      );
      return;
    }
    if (_type == ExpenseType.income &&
        double.tryParse(_amountController.text.trim())! < 0) {
      PlatformWidgets.showPlatformSnackbar(
        context: context,
        message: 'Income cannot be negative.',
      );
      return;
    }
    if (_isRecurring) {
      if (_recurringFrequency == null || _recurringFrequency!.isEmpty) {
        PlatformWidgets.showPlatformSnackbar(
          context: context,
          message: 'Select a recurring frequency.',
        );
        return;
      }
      if (_nextOccurrence == null) {
        PlatformWidgets.showPlatformSnackbar(
          context: context,
          message: 'Select next occurrence date.',
        );
        return;
      }
      if (_nextOccurrence!.isBefore(_date)) {
        PlatformWidgets.showPlatformSnackbar(
          context: context,
          message: 'Next occurrence must be after or equal to the main date.',
        );
        return;
      }
      if (_endDate != null && _endDate!.isBefore(_nextOccurrence!)) {
        PlatformWidgets.showPlatformSnackbar(
          context: context,
          message: 'End date must be after next occurrence.',
        );
        return;
      }
    }
    setState(() => _loading = true);
    try {
      if (widget.expense != null) {
        // Edit
        final updated = widget.expense!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
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
          PlatformWidgets.showPlatformSnackbar(
            context: context,
            message: 'Invalid data. Please check all fields.',
          );
          setState(() => _loading = false);
          return;
        }
        await ref.read(expenseNotifierProvider.notifier).updateExpense(updated);
      } else {
        // Add new
        await ref.read(expenseNotifierProvider.notifier).addExpense(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
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
      PlatformWidgets.showPlatformSnackbar(
        context: context,
        message:
            'Failed to  ${widget.expense != null ? 'edit' : 'add'} expense: $e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    String expenseTypeLabel(ExpenseType type) {
      switch (type) {
        case ExpenseType.expense:
          return localizations.expense;
        case ExpenseType.income:
          return localizations.income;
      }
    }

    String frequencyLabel(String freq) {
      switch (freq) {
        case 'daily':
          return localizations.daily ?? 'Daily';
        case 'weekly':
          return localizations.weekly ?? 'Weekly';
        case 'monthly':
          return localizations.monthly ?? 'Monthly';
        case 'custom':
          return localizations.custom ?? 'Custom';
        default:
          return freq;
      }
    }

    final formFields = [
      PlatformWidgets.buildTextField(
        context: context,
        label: localizations.title,
        hint: localizations.enterTitle,
        controller: _titleController,
        validator: (v) =>
            (v == null || v.isEmpty) ? localizations.enterTitle : null,
        onChanged: (v) => _titleController.text = v,
      ),
      PlatformWidgets.buildTextField(
        context: context,
        label: localizations.description,
        hint: localizations.description,
        controller: _descriptionController,
        onChanged: (v) => _descriptionController.text = v,
      ),
      PlatformWidgets.buildTextField(
        context: context,
        label: localizations.amount,
        hint: localizations.enterAmount,
        controller: _amountController,
        keyboardType: TextInputType.number,
        validator: (v) => (v == null ||
                double.tryParse(v) == null ||
                double.tryParse(v)! <= 0)
            ? localizations.enterAmount
            : null,
        onChanged: (v) => _amountController.text = v,
      ),
      Row(
        children: [
          Expanded(
            child: PlatformWidgets.buildPlatformDropdown<String>(
              context: context,
              value: _categories.contains(_category)
                  ? _category
                  : (_categories.isNotEmpty ? _categories.first : 'other'),
              items: _categories.where((cat) => cat.trim().isNotEmpty).toList(),
              itemBuilder: (cat) => Text(cat),
              onChanged: (v) => setState(() => _category = v ?? 'other'),
              label: localizations.category,
            ),
          ),
          PlatformWidgets.platformActionButton(
            context: context,
            icon: PlatformWidgets.isIOS
                ? CupertinoIcons.settings
                : Icons.settings,
            tooltip: localizations.manageCategories,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) =>
                    _CategoryManagerDialog(onChanged: _loadCategories),
              );
            },
          ),
        ],
      ),
      PlatformWidgets.buildPlatformDropdown<ExpenseType>(
        context: context,
        value: _type,
        items: ExpenseType.values.toList(),
        itemBuilder: (t) => Text(expenseTypeLabel(t)),
        onChanged: (v) => setState(() => _type = v ?? ExpenseType.expense),
        label: localizations.type,
      ),
      PlatformWidgets.platformListTile(
        context: context,
        title: Text(localizations.date),
        subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
        trailing: PlatformWidgets.platformActionButton(
          context: context,
          icon: PlatformWidgets.isIOS
              ? CupertinoIcons.calendar
              : Icons.calendar_today,
          tooltip: localizations.date,
          onPressed: () async {
            final picked = await PlatformWidgets.showPlatformDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
      ),
      PlatformWidgets.buildSwitch(
        context: context,
        value: _isRecurring,
        onChanged: (val) => setState(() => _isRecurring = val),
        title: localizations.recurring,
      ),
      if (_isRecurring)
        PlatformWidgets.buildPlatformDropdown<String>(
          context: context,
          value: _recurringFrequency,
          items: _frequencyOptions,
          itemBuilder: (f) => Text(frequencyLabel(f)),
          onChanged: (v) => setState(() => _recurringFrequency = v),
          label: localizations.frequency,
        ),
      if (_isRecurring)
        PlatformWidgets.platformListTile(
          context: context,
          title: Text(localizations.nextOccurrence),
          subtitle: Text(_nextOccurrence != null
              ? '${_nextOccurrence!.toLocal()}'.split(' ')[0]
              : localizations.selectNextOccurrence),
          trailing: PlatformWidgets.platformActionButton(
            context: context,
            icon: PlatformWidgets.isIOS
                ? CupertinoIcons.calendar
                : Icons.calendar_today,
            tooltip: localizations.nextOccurrence,
            onPressed: () async {
              final picked = await PlatformWidgets.showPlatformDatePicker(
                context: context,
                initialDate: _nextOccurrence ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _nextOccurrence = picked);
            },
          ),
        ),
      if (_isRecurring)
        PlatformWidgets.platformListTile(
          context: context,
          title: Text(localizations.endDate),
          subtitle: Text(_endDate != null
              ? '${_endDate!.toLocal()}'.split(' ')[0]
              : localizations.endDateAfterNext),
          trailing: PlatformWidgets.platformActionButton(
            context: context,
            icon: PlatformWidgets.isIOS
                ? CupertinoIcons.calendar
                : Icons.calendar_today,
            tooltip: localizations.endDate,
            onPressed: () async {
              final picked = await PlatformWidgets.showPlatformDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
        ),
    ];

    final formContent = PlatformWidgets.isIOS
        ? CupertinoFormSection.insetGrouped(
            margin: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM, horizontal: 0),
            children: formFields
                .map((f) => CupertinoFormRow(
                      prefix: null,
                      child: f,
                    ))
                .toList(),
          )
        : Card(
            margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingM),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: formFields,
              ),
            ),
          );

    final saveButton = SafeArea(
      minimum: const EdgeInsets.all(AppConstants.paddingM),
      child: SizedBox(
        width: double.infinity,
        child: PlatformWidgets.buildButton(
          context: context,
          onPressed: _loading ? null : _submit,
          isLoading: _loading,
          child: Text(widget.expense != null
              ? localizations.saveChanges
              : localizations.addExpense),
        ),
      ),
    );

    return PlatformWidgets.buildScaffold(
      context: context,
      appBar: PlatformWidgets.buildAppBar(
        context: context,
        title: widget.expense != null
            ? localizations.editExpense
            : localizations.addExpense,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: PlatformWidgets.isIOS
              ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
              : const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: formContent,
        ),
      ),
      bottomNavigationBar: saveButton,
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
    final localizations = AppLocalizations.of(context)!;
    if (PlatformWidgets.isIOS) {
      return CupertinoAlertDialog(
        title: Text(localizations.manageCategories),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._categories.map((cat) => PlatformWidgets.platformListTile(
                      context: context,
                      title: _editing == cat
                          ? CupertinoTextField(
                              controller: _controller,
                              autofocus: true,
                              style: AppTextStyles.body1,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingS,
                                vertical: AppConstants.paddingS,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                                border: Border.all(
                                  color: CupertinoColors.separator,
                                  width: 0.5,
                                ),
                              ),
                              onSubmitted: (val) async {
                                final trimmed = val.trim();
                                if (trimmed.isEmpty) {
                                  PlatformWidgets.showPlatformSnackbar(
                                    context: context,
                                    message: localizations.categoryNameEmpty,
                                  );
                                  return;
                                }
                                if (_isDuplicateCategory(trimmed) &&
                                    trimmed != cat) {
                                  PlatformWidgets.showPlatformSnackbar(
                                    context: context,
                                    message: localizations.duplicateCategory,
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
                                PlatformWidgets.platformActionButton(
                                  context: context,
                                  icon: CupertinoIcons.pencil,
                                  tooltip: localizations.editExpense,
                                  onPressed: () {
                                    setState(() {
                                      _editing = cat;
                                      _controller.text = cat;
                                    });
                                  },
                                ),
                                PlatformWidgets.platformActionButton(
                                  context: context,
                                  icon: CupertinoIcons.delete,
                                  tooltip: localizations.delete,
                                  onPressed: () async {
                                    final success =
                                        await _ds.deleteCategory(cat);
                                    if (!success) {
                                      PlatformWidgets.showPlatformSnackbar(
                                        context: context,
                                        message: localizations.categoryInUse,
                                      );
                                    } else {
                                      _refresh();
                                    }
                                  },
                                ),
                              ],
                            ),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _controller,
                        placeholder: localizations.addCategory,
                        style: AppTextStyles.body1,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingS,
                          vertical: AppConstants.paddingS,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    PlatformWidgets.platformActionButton(
                      context: context,
                      icon: CupertinoIcons.add,
                      tooltip: localizations.addCategory,
                      onPressed: () async {
                        final val = _controller.text.trim();
                        if (val.isEmpty) {
                          PlatformWidgets.showPlatformSnackbar(
                            context: context,
                            message: localizations.categoryNameEmpty,
                          );
                          return;
                        }
                        if (_isDuplicateCategory(val)) {
                          PlatformWidgets.showPlatformSnackbar(
                            context: context,
                            message: localizations.duplicateCategory,
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
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(localizations.close, style: AppTextStyles.button),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Text(localizations.manageCategories),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._categories.map((cat) => PlatformWidgets.platformListTile(
                    context: context,
                    title: _editing == cat
                        ? TextField(
                            controller: _controller,
                            autofocus: true,
                            style: AppTextStyles.body1,
                            decoration: InputDecoration(
                              hintText: localizations.addCategory,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusM),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingS,
                                vertical: AppConstants.paddingS,
                              ),
                            ),
                          )
                        : Text(cat),
                    trailing: CategoryLocalDataSourceImpl.defaultCategories
                            .contains(cat)
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlatformWidgets.platformActionButton(
                                context: context,
                                icon: Icons.edit,
                                tooltip: localizations.editExpense,
                                onPressed: () {
                                  setState(() {
                                    _editing = cat;
                                    _controller.text = cat;
                                  });
                                },
                              ),
                              PlatformWidgets.platformActionButton(
                                context: context,
                                icon: Icons.delete,
                                tooltip: localizations.delete,
                                onPressed: () async {
                                  final success = await _ds.deleteCategory(cat);
                                  if (!success) {
                                    PlatformWidgets.showPlatformSnackbar(
                                      context: context,
                                      message: localizations.categoryInUse,
                                    );
                                  } else {
                                    _refresh();
                                  }
                                },
                              ),
                            ],
                          ),
                  )),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: PlatformWidgets.isIOS
                    ? CupertinoColors.separator
                    : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          InputDecoration(hintText: localizations.addCategory),
                      style: AppTextStyles.body1,
                    ),
                  ),
                  PlatformWidgets.platformActionButton(
                    context: context,
                    icon: Icons.add,
                    tooltip: localizations.addCategory,
                    onPressed: () async {
                      final val = _controller.text.trim();
                      if (val.isEmpty) {
                        PlatformWidgets.showPlatformSnackbar(
                          context: context,
                          message: localizations.categoryNameEmpty,
                        );
                        return;
                      }
                      if (_isDuplicateCategory(val)) {
                        PlatformWidgets.showPlatformSnackbar(
                          context: context,
                          message: localizations.duplicateCategory,
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
          PlatformWidgets.buildButton(
            context: context,
            onPressed: () => Navigator.of(context).pop(),
            isPrimary: false,
            child: Text(localizations.close, style: AppTextStyles.button),
          ),
        ],
      );
    }
  }
}
