import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_dashboard_response.dart';
import '../../models/expense_response.dart';
import '../../navigation/app_navigator.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class MoneyInsightsSection extends StatelessWidget {
  const MoneyInsightsSection({
    super.key,
    required this.insights,
  });

  final List<SpendingInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FadeInSection(
      index: 4,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Spending Insights',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < insights.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _InsightRow(insight: insights[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final SpendingInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              insight.message,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyComparisonSection extends StatelessWidget {
  const MoneyComparisonSection({
    super.key,
    required this.comparison,
  });

  final MonthlyComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInSection(
      index: 5,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Comparison',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This month vs last month',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ComparisonRow(label: 'Total', metric: comparison.total),
            const SizedBox(height: AppSpacing.md),
            _ComparisonRow(label: 'Personal', metric: comparison.personal),
            const SizedBox(height: AppSpacing.md),
            _ComparisonRow(label: 'Shared Living', metric: comparison.sharedLiving),
            const SizedBox(height: AppSpacing.md),
            _ComparisonRow(label: 'Family', metric: comparison.family),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.metric,
  });

  final String label;
  final ComparisonMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final changeColor = metric.isIncrease
        ? scheme.error
        : metric.isDecrease
            ? scheme.tertiary
            : scheme.onSurfaceVariant;
    final changeIcon = metric.isIncrease
        ? Icons.arrow_upward_rounded
        : metric.isDecrease
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _AmountColumn(
                  caption: 'This Month',
                  amount: metric.thisMonth,
                  emphasized: true,
                ),
              ),
              Icon(Icons.compare_arrows_rounded, color: scheme.outline),
              Expanded(
                child: _AmountColumn(
                  caption: 'Last Month',
                  amount: metric.lastMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(changeIcon, size: 18, color: changeColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${metric.isIncrease ? '+' : metric.isDecrease ? '-' : ''}${ExpenseUiUtils.formatAmount(metric.changeAmount.abs())} (${metric.changePercent.abs().toStringAsFixed(1)}%)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.caption,
    required this.amount,
    this.emphasized = false,
  });

  final String caption;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          ExpenseUiUtils.formatAmount(amount),
          style: (emphasized ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MoneyRecentTimeline extends StatelessWidget {
  const MoneyRecentTimeline({
    super.key,
    required this.transactions,
  });

  final List<ExpenseResponse> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupByDate(transactions);

    return FadeInSection(
      index: 6,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Latest 10 expenses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (transactions.isEmpty)
              Text(
                'No transactions yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final entry in grouped.entries) ...[
                Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < entry.value.length; i++)
                  _TimelineTile(
                    expense: entry.value[i],
                    isLast: i == entry.value.length - 1,
                    onTap: () => AppNavigator.openExpenseDetails(context, entry.value[i].id),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Map<String, List<ExpenseResponse>> _groupByDate(List<ExpenseResponse> items) {
    final map = <String, List<ExpenseResponse>>{};
    for (final item in items) {
      final key = _formatGroupDate(item.expenseDate);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMMd().format(date);
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.expense,
    required this.isLast,
    required this.onTap,
  });

  final ExpenseResponse expense;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ExpenseUiUtils.colorForType(expense.expenseType, scheme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ExpenseUiUtils.iconForType(expense.expenseType),
                            color: accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${expense.category} • ${expense.expenseType.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          ExpenseUiUtils.formatAmount(expense.amount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
