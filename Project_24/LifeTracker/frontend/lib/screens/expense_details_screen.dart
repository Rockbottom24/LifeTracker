import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_response.dart';
import '../navigation/add_expense_page_route.dart';
import '../providers/expense_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/expense_ui_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  const ExpenseDetailsScreen({super.key, required this.expenseId});

  final int expenseId;

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ExpenseProvider>();
      if (provider.findExpenseById(widget.expenseId) == null) {
        await provider.loadExpenses();
      }
    });
  }

  Future<void> _openEdit(ExpenseResponse expense) async {
    await Navigator.of(context).push(
      AddExpensePageRoute(
        settings: RouteSettings(name: '/edit-expense/${expense.id}'),
        expenseType: expense.expenseType,
        expense: expense,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(ExpenseResponse expense) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete expense',
      message: 'Are you sure you want to delete "${expense.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ExpenseProvider>();
    final ok = await provider.deleteExpense(expense.id);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      return;
    }

    SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to delete expense');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expense = provider.findExpenseById(widget.expenseId);

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final accent = ExpenseUiUtils.colorForType(expense.expenseType, theme.colorScheme);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
          ),
          children: [
            ResponsiveFormContainer(
              child: Column(
                children: [
                  DetailHeaderCard(
                    icon: ExpenseUiUtils.iconForType(expense.expenseType),
                    iconColor: accent,
                    title: expense.title,
                    subtitle: expense.description,
                    chips: [
                      DetailStatChip(
                        label: expense.expenseType.shortLabel,
                        color: theme.colorScheme.primaryContainer,
                      ),
                      DetailStatChip(
                        label: expense.category,
                        color: theme.colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      children: [
                        DetailInfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Amount',
                          value: ExpenseUiUtils.formatAmount(expense.amount),
                        ),
                        DetailInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Expense date',
                          value: ExpenseUiUtils.formatDate(expense.expenseDate),
                        ),
                        DetailInfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Payment mode',
                          value: expense.paymentMode ?? 'Not set',
                        ),
                        DetailInfoRow(
                          icon: Icons.sticky_note_2_outlined,
                          label: 'Notes',
                          value: expense.notes ?? 'None',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  DetailActionsSection(
                    children: [
                      PrimaryButton(
                        label: 'Edit',
                        expand: true,
                        icon: Icons.edit_outlined,
                        onPressed: () => _openEdit(expense),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryActionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        isDestructive: true,
                        onPressed: () => _delete(expense),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
