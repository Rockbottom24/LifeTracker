import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/food_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/meal_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/learning_screen.dart';
import '../screens/money_screen.dart';
import '../screens/nutrition_screen.dart';
import '../services/api_client.dart';
import '../sync/sync_engine.dart';
import '../theme/app_spacing.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({required this.apiClient, required this.syncEngine, super.key});

  final DioApiClient apiClient;
  final SyncEngine syncEngine;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> with WidgetsBindingObserver {
  static const _destinations = <NavDestinationConfig>[
    NavDestinationConfig(icon: Icons.castle_outlined, selectedIcon: Icons.castle, label: 'The Realm'),
    NavDestinationConfig(icon: Icons.task_alt_outlined, selectedIcon: Icons.task_alt, label: 'Daily Quests'),
    NavDestinationConfig(icon: Icons.auto_stories_outlined, selectedIcon: Icons.auto_stories, label: 'The Citadel'),
    NavDestinationConfig(icon: Icons.account_balance_outlined, selectedIcon: Icons.account_balance, label: 'Iron Bank'),
    NavDestinationConfig(icon: Icons.local_dining_outlined, selectedIcon: Icons.local_dining, label: 'Royal Kitchen'),
  ];

  int _selectedIndex = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (_) => _syncInBackground());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _syncInBackground() async {
    if (!mounted) return;
    await widget.syncEngine.syncAll();
    if (!mounted) return;
    _reloadLocalState();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;

    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<HabitProvider>().loadHabits(),
      context.read<HabitProvider>().loadCategories(),
      context.read<LearningProvider>().loadSessions(),
      context.read<ExpenseProvider>().refreshExpenseData(),
      context.read<FoodProvider>().loadFoods(),
      context.read<MealProvider>().refreshNutritionData(),
    ]);
  }

  void _reloadLocalState() {
    context.read<DashboardProvider>().loadDashboard();
    context.read<HabitProvider>().loadHabits();
    context.read<LearningProvider>().loadSessions();
    context.read<ExpenseProvider>().refreshExpenseData();
    context.read<FoodProvider>().loadFoods();
    context.read<MealProvider>().refreshNutritionData();
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _refreshTabData(index);
  }

  void _refreshTabData(int index) {
    switch (index) {
      case 0:
        context.read<DashboardProvider>().loadDashboard();
        context.read<HabitProvider>().loadHabits();
        context.read<HabitProvider>().loadCategories();
        context.read<LearningProvider>().loadSessions();
      case 1:
        context.read<HabitProvider>().loadHabits();
        context.read<HabitProvider>().loadCategories();
      case 2:
        context.read<LearningProvider>().loadSessions();
      case 3:
        context.read<ExpenseProvider>().refreshExpenseData();
      case 4:
        context.read<FoodProvider>().loadFoods();
        context.read<MealProvider>().refreshNutritionData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardScreen(),
          HabitsScreen(),
          LearningScreen(),
          MoneyScreen(),
          NutritionScreen(),
        ],
      ),
      bottomNavigationBar: PremiumBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}

class PremiumBottomNavigationBar extends StatelessWidget {
  const PremiumBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestinationConfig> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.97),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final isSelected = index == selectedIndex;
            final icon = isSelected ? destination.selectedIcon : destination.icon;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onDestinationSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 26,
                            child: Icon(
                              icon,
                              size: 24,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 18,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  destination.label,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NavDestinationConfig {
  const NavDestinationConfig({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
