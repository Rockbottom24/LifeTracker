import 'package:flutter/material.dart';

import '../../constants/expense_form_options.dart';
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
    required this.selectedCategory,
    required this.selectedPaymentMode,
    required this.categoryError,
    required this.expenseDate,
    required this.onCategoryChanged,
    required this.onPaymentModeChanged,
    required this.onPickDate,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final String? selectedCategory;
  final String? selectedPaymentMode;
  final String? categoryError;
  final DateTime expenseDate;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onPaymentModeChanged;
  final VoidCallback onPickDate;

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
              value: selectedCategory,
              hint: 'Select a category',
              errorText: categoryError,
              items: ExpenseFormOptions.categories
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: onCategoryChanged,
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
