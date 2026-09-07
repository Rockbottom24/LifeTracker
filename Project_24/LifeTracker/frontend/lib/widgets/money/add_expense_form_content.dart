import 'package:flutter/material.dart';

import '../../constants/expense_form_options.dart';
import '../../models/expense_type.dart';
import '../../theme/app_spacing.dart';
import '../app_dropdown.dart';
import '../app_text_field.dart';
import '../form_section_card.dart';

class AddExpenseFormContent extends StatelessWidget {
  const AddExpenseFormContent({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.descriptionController,
    required this.notesController,
    required this.selectedExpenseType,
    required this.selectedCategory,
    required this.selectedPaymentMode,
    required this.categoryError,
    required this.expenseDate,
    required this.categories,
    required this.onExpenseTypeChanged,
    required this.onCategoryChanged,
    required this.onPaymentModeChanged,
    required this.onPickDate,
    required this.onAddCategory,
    required this.onRemoveCategory,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final ExpenseType selectedExpenseType;
  final String? selectedCategory;
  final String? selectedPaymentMode;
  final String? categoryError;
  final DateTime expenseDate;
  final List<String> categories;
  final ValueChanged<ExpenseType?> onExpenseTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onPaymentModeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onAddCategory;
  final VoidCallback onRemoveCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionCard(
          title: 'Expense details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            AppDropdown<ExpenseType>(
              label: 'Expense Type',
              value: selectedExpenseType,
              hint: 'Select type',
              items: ExpenseType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: onExpenseTypeChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: titleController,
              label: 'Title',
              hint: 'What did you spend on?',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              label: 'Category',
              value: categories.contains(selectedCategory) ? selectedCategory : null,
              hint: 'Select a category',
              errorText: categoryError,
              items: [
                ...categories.map(
                  (category) => DropdownMenuItem(value: category, child: Text(category)),
                ),
                DropdownMenuItem(
                  value: '__ADD_NEW_CATEGORY_ACTION__',
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFFC4B28B)),
                      SizedBox(width: 8),
                      Text('+ Add Custom Category...', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC4B28B))),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == '__ADD_NEW_CATEGORY_ACTION__') {
                  onAddCategory();
                } else {
                  onCategoryChanged(val);
                }
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Customization',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFC4B28B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onAddCategory,
                          icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFC4B28B)),
                          label: const Text(
                            '+ Add Category',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC4B28B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onRemoveCategory,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text(
                            'Remove Category',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: amountController,
              label: 'Amount',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Expense date', style: theme.textTheme.titleSmall),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(expenseDate),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: 'Pick date',
              ),
            ),
          ],
          ),
        ),
        FormSectionCard(
          title: 'Payment & notes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            AppDropdown<String>(
              label: 'Payment mode',
              value: selectedPaymentMode,
              hint: 'Select payment mode',
              items: ExpenseFormOptions.paymentModes
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: onPaymentModeChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Optional details',
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: notesController,
              label: 'Notes',
              hint: 'Optional notes',
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
          ),
        ),
      ],
    );
  }
}
