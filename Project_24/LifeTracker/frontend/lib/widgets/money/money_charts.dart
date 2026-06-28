import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/expense_dashboard_response.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';
import 'money_category_colors.dart';

class MoneyTrendChart extends StatelessWidget {
  const MoneyTrendChart({
    super.key,
    required this.trend,
  });

  final List<MonthlyTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxAmount = trend.fold<double>(0, (max, point) => point.amount > max ? point.amount : max);
    final chartMax = maxAmount <= 0 ? 1000.0 : maxAmount * 1.15;

    return FadeInSection(
      index: 2,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending Trend',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Last 6 months',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 220,
              child: trend.isEmpty
                  ? Center(
                      child: Text(
                        'No spending data yet',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: chartMax,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: chartMax / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '₹${value.round()}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= trend.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    trend[index].monthLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < trend.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: trend[i].amount,
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      scheme.primary.withValues(alpha: 0.65),
                                      scheme.primary,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoneyCategoryChart extends StatelessWidget {
  const MoneyCategoryChart({
    super.key,
    required this.breakdown,
  });

  final List<CategoryBreakdownItem> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = breakdown.fold<double>(0, (sum, item) => sum + item.amount);

    return FadeInSection(
      index: 3,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This month by category',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (breakdown.isEmpty || total <= 0)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No category spending yet',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 520;
                  final chart = SizedBox(
                    height: 200,
                    width: isWide ? 200 : double.infinity,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        startDegreeOffset: -90,
                        sections: [
                          for (final item in breakdown)
                            PieChartSectionData(
                              value: item.amount,
                              title: '${item.percentage.round()}%',
                              color: MoneyCategoryColors.forCategory(item.category, scheme),
                              radius: 56,
                              titleStyle: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                            ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  final legend = Column(
                    children: [
                      for (final item in breakdown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: MoneyCategoryColors.forCategory(item.category, scheme),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  item.category,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                ExpenseUiUtils.formatAmount(item.amount),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        chart,
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(child: legend),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: AppSpacing.lg),
                      legend,
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
