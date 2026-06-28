import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_dashboard_response.dart';
import '../../models/expense_type.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../fade_in_section.dart';
import 'money_animated_amount.dart';
import 'money_charts.dart';
import 'money_dashboard_sections.dart';

class MoneyDashboardSection extends StatelessWidget {
  const MoneyDashboardSection({
    super.key,
    required this.dashboard,
    required this.isLoading,
    this.errorMessage,
  });

  final ExpenseDashboardResponse? dashboard;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && dashboard == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboard == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          errorMessage ?? 'Unable to load dashboard analytics.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final data = dashboard!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInSection(
              index: 0,
              child: _DashboardHero(totalSpent: data.totalSpentThisMonth),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SummaryCardsGrid(
              personal: data.personalSpentThisMonth,
              sharedLiving: data.sharedLivingSpentThisMonth,
              family: data.familySpentThisMonth,
              isWide: isWide,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: MoneyTrendChart(trend: data.monthlyTrend)),
                  const SizedBox(width: AppSpacing.sectionGap),
                  Expanded(child: MoneyCategoryChart(breakdown: data.categoryBreakdown)),
                ],
              )
            else ...[
              MoneyTrendChart(trend: data.monthlyTrend),
              MoneyCategoryChart(breakdown: data.categoryBreakdown),
            ],
            MoneyInsightsSection(insights: data.insights),
            MoneyComparisonSection(comparison: data.monthlyComparison),
            MoneyRecentTimeline(transactions: data.recentTransactions),
          ],
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.totalSpent});

  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.82),
            theme.colorScheme.tertiary.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent This Month',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyAnimatedAmount(
            value: totalSpent,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.88),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                monthLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCardsGrid extends StatelessWidget {
  const _SummaryCardsGrid({
    required this.personal,
    required this.sharedLiving,
    required this.family,
    required this.isWide,
  });

  final double personal;
  final double sharedLiving;
  final double family;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        label: 'Personal Expenses',
        amount: personal,
        type: ExpenseType.personal,
        index: 1,
      ),
      _SummaryCardData(
        label: 'Shared Living',
        amount: sharedLiving,
        type: ExpenseType.sharedLiving,
        index: 1,
      ),
      _SummaryCardData(
        label: 'Family Support',
        amount: family,
        type: ExpenseType.family,
        index: 1,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: _AnimatedSummaryCard(data: cards[i])),
          ],
        ],
      );
    }

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 220,
            child: _AnimatedSummaryCard(data: cards[index]),
          );
        },
      ),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.amount,
    required this.type,
    required this.index,
  });

  final String label;
  final double amount;
  final ExpenseType type;
  final int index;
}

class _AnimatedSummaryCard extends StatelessWidget {
  const _AnimatedSummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = ExpenseUiUtils.gradientForType(data.type, scheme);

    return FadeInSection(
      index: data.index,
      child: Material(
        elevation: 2,
        shadowColor: gradient.first.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ExpenseUiUtils.iconForType(data.type),
                  color: scheme.onPrimary.withValues(alpha: 0.92),
                ),
                const Spacer(),
                Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                MoneyAnimatedAmount(
                  value: data.amount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
