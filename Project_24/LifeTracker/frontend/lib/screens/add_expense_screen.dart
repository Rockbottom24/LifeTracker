import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/create_expense_request.dart';
import '../models/expense_response.dart';
import '../models/expense_type.dart';
import '../models/update_expense_request.dart';
import '../providers/expense_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/forms/form_screen_scaffold.dart';
import '../widgets/money/add_expense_form_content.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.expenseType,
    this.expense,
  });

  final ExpenseType expenseType;
  final ExpenseResponse? expense;

  bool get isEditMode => expense != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late ExpenseType _selectedExpenseType;
  String? _selectedCategory;
  String? _selectedPaymentMode;
  String? _categoryError;
  DateTime _expenseDate = DateTime.now();
  String? _successMessage;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _selectedExpenseType = widget.expenseType;
    _prefill(widget.expense);
  }

  void _prefill(ExpenseResponse? expense) {
    if (expense == null) return;
    _selectedExpenseType = expense.expenseType;
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toStringAsFixed(2);
    _descriptionController.text = expense.description ?? '';
    _notesController.text = expense.notes ?? '';
    _selectedCategory = expense.category;
    _selectedPaymentMode = expense.paymentMode;
    _expenseDate = expense.expenseDate;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  bool _validateCategory() {
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      setState(() => _categoryError = 'Category is required');
      return false;
    }
    setState(() => _categoryError = null);
    return true;
  }

  Future<void> _save() async {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateCategory()) return;

    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    if (_isEditMode) {
      final ok = await provider.updateExpense(
        widget.expense!.id,
        UpdateExpenseRequest(
          expenseType: _selectedExpenseType,
          category: _selectedCategory!,
          title: _titleController.text.trim(),
          description: description.isEmpty ? null : description,
          amount: amount,
          expenseDate: _expenseDate,
          paymentMode: _selectedPaymentMode,
          notes: notes.isEmpty ? null : notes,
        ),
      );
      if (!mounted) return;
      if (!ok) {
        SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
        return;
      }
      setState(() => _successMessage = 'Expense updated successfully');
      return;
    }

    final created = await provider.createExpense(
      CreateExpenseRequest(
        expenseType: _selectedExpenseType,
        category: _selectedCategory!,
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        amount: amount,
        expenseDate: _expenseDate,
        paymentMode: _selectedPaymentMode,
        notes: notes.isEmpty ? null : notes,
      ),
    );
    if (!mounted) return;
    if (created == null) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
      return;
    }
    setState(() => _successMessage = '"${created.title}" created successfully');
  }

  Future<void> _showAddCategoryDialog() async {
    final textController = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Custom Category'),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Subscriptions, Books, Fuel',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newCategory == null || newCategory.isEmpty) return;

    final provider = context.read<ExpenseProvider>();
    final ok = await provider.addCategory(newCategory);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _selectedCategory = newCategory;
        _categoryError = null;
      });
      SnackBarUtils.showMessage(context, 'Category "$newCategory" added');
    } else {
      SnackBarUtils.showError(context, 'Category already exists or invalid');
    }
  }

  Future<void> _showRemoveCategoryDialog() async {
    final provider = context.read<ExpenseProvider>();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentCategories = provider.categories;
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remove Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the delete icon to remove a category from your selection list:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currentCategories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cat = currentCategories[index];
                        return ListTile(
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final ok = await provider.removeCategory(cat);
                              if (ok) {
                                setModalState(() {});
                                if (_selectedCategory == cat) {
                                  setState(() {
                                    _selectedCategory = provider.categories.isNotEmpty ? provider.categories.first : null;
                                  });
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final title = _isEditMode ? 'Edit Expense' : 'Add Expense';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FormScreenScaffold(
        formKey: _formKey,
        scrollController: _scrollController,
        onDismissKeyboard: _dismissKeyboard,
        successMessage: _successMessage,
        onSuccessComplete: () {
          if (mounted) Navigator.of(context).pop();
        },
        children: [
          SectionTitle(
            title: _isEditMode ? 'Update expense' : _selectedExpenseType.listTitle,
            subtitle: _isEditMode
                ? 'Update the details for this expense.'
                : 'Record a new ${_selectedExpenseType.shortLabel.toLowerCase()} expense.',
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AddExpenseFormContent(
            titleController: _titleController,
            amountController: _amountController,
            descriptionController: _descriptionController,
            notesController: _notesController,
            selectedExpenseType: _selectedExpenseType,
            selectedCategory: _selectedCategory,
            selectedPaymentMode: _selectedPaymentMode,
            categoryError: _categoryError,
            expenseDate: _expenseDate,
            categories: provider.categories,
            onExpenseTypeChanged: (type) => setState(() {
              if (type != null) _selectedExpenseType = type;
            }),
            onCategoryChanged: (value) => setState(() {
              _selectedCategory = value;
              _categoryError = null;
            }),
            onPaymentModeChanged: (value) => setState(() => _selectedPaymentMode = value),
            onPickDate: _pickDate,
            onAddCategory: _showAddCategoryDialog,
            onRemoveCategory: _showRemoveCategoryDialog,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          PrimaryButton(
            label: 'Save Expense',
            expand: true,
            icon: Icons.save_outlined,
            isLoading: provider.isSaving,
            loadingLabel: 'Saving...',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
