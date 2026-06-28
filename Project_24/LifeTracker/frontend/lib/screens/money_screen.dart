import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_type.dart';
import '../navigation/add_expense_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/expense_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/expense_ui_utils.dart';
import '../widgets/loading_view.dart';
import '../widgets/money/expense_list_card.dart';
import '../widgets/money/money_category_card.dart';
import '../widgets/money/money_dashboard_section.dart';
import '../widgets/responsive_form_container.dart';
import '../widgets/section_title.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().refreshExpenseData();
    });
  }

  Future<void> _openList(ExpenseType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/money/${type.apiValue}'),
        builder: (_) => ExpenseListScreen(expenseType: type),
      ),
    );
    if (mounted) {
      await context.read<ExpenseProvider>().refreshExpenseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Iron Bank')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshExpenseData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveFormContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle(
                          title: 'Iron Bank',
                          subtitle: 'Track personal, shared living, and family expenses.',
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        MoneyDashboardSection(
                          dashboard: provider.dashboard,
                          isLoading: provider.isDashboardLoading,
                          errorMessage: provider.dashboardErrorMessage,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const SectionTitle(
                          title: 'Holdings',
                          subtitle: 'Browse and manage expenses by type.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (provider.isLoading && provider.expenses.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingView(message: 'Loading expenses...')),
                )
              else if (provider.errorMessage != null && provider.expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.listBottomInset,
                  ),
                  sliver: SliverList.separated(
                    itemCount: ExpenseType.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionGap),
                    itemBuilder: (context, index) {
                      final type = ExpenseType.values[index];
                      return MoneyCategoryCard(
                        expenseType: type,
                        summary: provider.summaryFor(type),
                        onTap: () => _openList(type),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key, required this.expenseType});

  final ExpenseType expenseType;

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      AddExpensePageRoute(
        settings: RouteSettings(name: '/add-expense/${widget.expenseType.apiValue}'),
        expenseType: widget.expenseType,
      ),
    );
    if (mounted) {
      await context.read<ExpenseProvider>().refreshExpenseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final items = provider.expensesForType(widget.expenseType);

    return Scaffold(
      appBar: AppBar(title: Text(widget.expenseType.label)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expense_list_fab_${widget.expenseType.apiValue}',
        onPressed: _openAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadExpenses,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveFormContainer(
                    child: SectionTitle(
                      title: widget.expenseType.listTitle,
                      subtitle:
                          'Total ${ExpenseUiUtils.formatAmount(provider.summaryFor(widget.expenseType).totalAmount)} across ${items.length} transaction${items.length == 1 ? '' : 's'}.',
                    ),
                  ),
                ),
              ),
              if (provider.isLoading && items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingView(message: 'Loading expenses...')),
                )
              else if (provider.errorMessage != null && items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(provider.errorMessage!)),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ExpenseUiUtils.iconForType(widget.expenseType),
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap Add Expense to record your first transaction.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.listBottomInset,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionGap),
                    itemBuilder: (context, index) {
                      final expense = items[index];
                      return ExpenseListCard(
                        key: ValueKey(expense.id),
                        expense: expense,
                        onTap: () => AppNavigator.openExpenseDetails(context, expense.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
