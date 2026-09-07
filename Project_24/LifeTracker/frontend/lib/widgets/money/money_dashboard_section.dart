import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_dashboard_response.dart';
import '../../models/expense_type.dart';
import '../../providers/expense_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../fade_in_section.dart';
import '../glass_card.dart';
import 'money_animated_amount.dart';
import 'money_charts.dart';
import 'money_dashboard_sections.dart';
import 'money_lent_section.dart';
import 'target_salary_card.dart';

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
            const MoneyLentSection(),
            const SizedBox(height: AppSpacing.sectionGap),
            const TargetSalaryCard(),
            const SizedBox(height: AppSpacing.sectionGap),
            _SummaryCardsGrid(
              personal: data.personalSpentThisMonth,
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

  void _showSetIncomeDialog(BuildContext context, double currentIncome) {
    final controller = TextEditingController(
      text: currentIncome > 0 ? currentIncome.toStringAsFixed(0) : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actionsOverflowDirection: VerticalDirection.down,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              const Icon(Icons.savings_rounded, color: Color(0xFFC4B28B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set Monthly Income',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter total income received for this month to track remaining vault savings.',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Monthly Income (₹)',
                    hintText: 'e.g. 50000',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B28B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final val = double.tryParse(controller.text.trim()) ?? 0.0;
                context.read<ExpenseProvider>().setMonthlyIncome(val);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save Income', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    const goldColor = Color(0xFFC4B28B);
    final provider = context.watch<ExpenseProvider>();
    final income = provider.monthlyIncome;
    final remaining = provider.remainingVaultBalance;
    final hasIncome = income > 0;
    final savingsPct = hasIncome ? ((remaining / income) * 100).clamp(0.0, 100.0) : 0.0;

    return GlassCard(
      borderRadius: 24,
      borderColor: goldColor.withValues(alpha: 0.35),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: goldColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Iron Bank Vault · $monthLabel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _showSetIncomeDialog(context, income),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(hasIncome ? Icons.edit_rounded : Icons.add_rounded, size: 14, color: goldColor),
                        const SizedBox(width: 4),
                        Text(
                          hasIncome ? 'Edit Income' : '+ Set Income',
                          style: const TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Balance Display
          Text(
            hasIncome ? 'Remaining Vault Savings' : 'Total Spent This Month',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyAnimatedAmount(
              value: hasIncome ? remaining : totalSpent,
              style: theme.textTheme.displaySmall?.copyWith(
                color: hasIncome
                    ? (remaining >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF5252))
                    : Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics Breakdown Card
          if (hasIncome) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MoneyAnimatedAmount(
                            value: income,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 24, width: 1, color: Colors.white24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: MoneyAnimatedAmount(
                              value: totalSpent,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF8A80)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (provider.totalOutstandingLent > 0) ...[
                    Container(height: 24, width: 1, color: Colors.white24),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lent',
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: MoneyAnimatedAmount(
                                value: provider.totalOutstandingLent,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Container(height: 24, width: 1, color: Colors.white24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved',
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${savingsPct.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: goldColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (savingsPct / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white12,
                color: remaining >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
              ),
            ),
          ] else ...[
            // Prompt Card when Income is not set yet
            InkWell(
              onTap: () => _showSetIncomeDialog(context, 0.0),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_card_rounded, color: goldColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set Monthly Income to track vault savings & balance',
                        style: TextStyle(fontSize: 12, color: goldColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: goldColor, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCardsGrid extends StatelessWidget {
  const _SummaryCardsGrid({
    required this.personal,
    required this.family,
    required this.isWide,
  });

  final double personal;
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
