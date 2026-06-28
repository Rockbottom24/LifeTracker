import 'package:flutter/material.dart';

import '../../models/expense_response.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../app_chip.dart';
import '../lists/accent_list_card_shell.dart';

class ExpenseListCard extends StatelessWidget {
  const ExpenseListCard({
    super.key,
    required this.expense,
    required this.onTap,
  });

  final ExpenseResponse expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ExpenseUiUtils.colorForType(expense.expenseType, theme.colorScheme);

    return AccentListCardShell(
      accentColor: accent,
      icon: ExpenseUiUtils.iconForType(expense.expenseType),
      title: expense.title,
      subtitle: expense.category,
      onTap: onTap,
      footer: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppChip(
            icon: Icons.payments_outlined,
            label: ExpenseUiUtils.formatAmount(expense.amount),
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          AppChip(
            icon: Icons.calendar_today_outlined,
            label: ExpenseUiUtils.formatDate(expense.expenseDate),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          if (expense.paymentMode != null && expense.paymentMode!.isNotEmpty)
            AppChip(
              icon: Icons.account_balance_wallet_outlined,
              label: expense.paymentMode!,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              foregroundColor: theme.colorScheme.onTertiaryContainer,
            ),
        ],
      ),
    );
  }
}
