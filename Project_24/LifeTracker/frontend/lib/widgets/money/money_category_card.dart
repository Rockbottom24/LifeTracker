import 'package:flutter/material.dart';

import '../../models/expense_type.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_summary_mapper.dart';
import '../../utils/expense_ui_utils.dart';

class MoneyCategoryCard extends StatelessWidget {
  const MoneyCategoryCard({
    super.key,
    required this.expenseType,
    required this.summary,
    required this.onTap,
  });

  final ExpenseType expenseType;
  final ExpenseTypeSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = ExpenseUiUtils.gradientForType(expenseType, scheme);
    final icon = ExpenseUiUtils.iconForType(expenseType);
    final latest = summary.latestExpense;

    return Material(
      elevation: 2,
      shadowColor: gradient.first.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: scheme.onPrimary, size: 28),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary.withValues(alpha: 0.9)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  expenseType.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ExpenseUiUtils.formatAmount(summary.totalAmount),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${summary.transactionCount} transaction${summary.transactionCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Latest: ${latest.title} • ${ExpenseUiUtils.formatAmount(latest.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
