import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/journal_provider.dart';
import '../providers/local_auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/food_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/workout_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/money_screen.dart';
import '../screens/nutrition_screen.dart';
import '../screens/workouts_screen.dart';
import '../services/drive_backup_service.dart';
import '../services/google_auth_service.dart';
import '../services/widget_service.dart';
import '../sync/sync_engine.dart';
import '../theme/app_spacing.dart';
import '../utils/user_reminder_scheduler.dart';
import '../widgets/house_ambient_background.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({required this.syncEngine, super.key});

  final SyncEngine syncEngine;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> with WidgetsBindingObserver {
  static const _destinations = <NavDestinationConfig>[
    NavDestinationConfig(icon: Icons.castle_outlined, selectedIcon: Icons.castle, label: 'The Realm'),
    NavDestinationConfig(icon: Icons.task_alt_outlined, selectedIcon: Icons.task_alt, label: 'Daily Quests'),
    NavDestinationConfig(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center, label: 'Training'),
    NavDestinationConfig(icon: Icons.auto_stories_outlined, selectedIcon: Icons.auto_stories, label: 'White Book'),
    NavDestinationConfig(icon: Icons.account_balance_outlined, selectedIcon: Icons.account_balance, label: 'Iron Bank'),
    NavDestinationConfig(icon: Icons.local_dining_outlined, selectedIcon: Icons.local_dining, label: 'Royal Kitchen'),
  ];

  int _selectedIndex = 0;
  int _maxWarmupIndex = 0;
  late final PageController _pageController;
  Timer? _syncTimer;
  Timer? _warmupTimer;
  bool _remindersScheduled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
      _startWarmupTimer();
    });
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (_) => _syncInBackground());
  }

  void _startWarmupTimer() {
    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_maxWarmupIndex < _destinations.length - 1) {
        setState(() {
          _maxWarmupIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    _pageController.dispose();
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

  void _refreshAll() {
    if (!mounted) return;

    // Load active home screen (Dashboard) instantly for <50ms startup
    context.read<DashboardProvider>().loadDashboard();

    // Stagger background provider loads across frames to keep UI 60fps responsive
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      context.read<HabitProvider>().loadHabits();
      context.read<HabitProvider>().loadCategories();
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      context.read<WorkoutProvider>().loadScheduleAndTemplates();
      context.read<JournalProvider>().loadEntries();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<ExpenseProvider>().refreshExpenseData();
      context.read<FoodProvider>().loadFoods();
      context.read<MealProvider>().refreshNutritionData();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (!_remindersScheduled) {
        const localUserId = 1;
        UserReminderScheduler.rescheduleForUser(
          userId: localUserId,
          habits: context.read<HabitProvider>().habits,
          sessions: context.read<LearningProvider>().sessions,
        );
        _remindersScheduled = true;
      }

      // Check for weekly Sunday auto-backup
      try {
        final googleAuth = context.read<GoogleAuthService>();
        DriveBackupService.checkSundayAutoBackup(googleAuth);
      } catch (_) {}

      // Refresh Android Home Screen Widget
      try {
        final hp = context.read<HabitProvider>();
        final auth = context.read<LocalAuthProvider>();
        final meal = context.read<MealProvider>();
        final workout = context.read<WorkoutProvider>();

        final active = hp.todayHabits;
        final done = active.where((h) => hp.isCompletedToday(h.id)).length;

        final summary = meal.todaySummary;
        final kcal = summary?.calories.round() ?? 0;
        final p = summary?.protein.round() ?? 0;
        final nutritionStr = kcal > 0 ? '$kcal kcal • ${p}g P' : 'Log Meals 🍎';

        final sched = workout.todaySchedule;
        final workoutToday = sched?.template?.name ?? (sched?.customTitle ?? 'Rest Day 🛡️');

        WidgetService.updateWidgetData(
          houseKey: auth.houseKey ?? 'stark',
          completedQuests: done,
          totalQuests: active.length,
          streakDays: 1,
          workoutName: workoutToday,
          nutritionText: nutritionStr,
        );
      } catch (_) {}
    });
  }

  void _ensureTabLoaded(int index) {
    switch (index) {
      case 1:
        context.read<HabitProvider>().loadHabits();
        break;
      case 2:
        context.read<WorkoutProvider>().loadScheduleAndTemplates();
        break;
      case 3:
        context.read<JournalProvider>().loadEntries();
        break;
      case 4:
        context.read<ExpenseProvider>().refreshExpenseData();
        break;
      case 5:
        context.read<FoodProvider>().loadFoods();
        context.read<MealProvider>().refreshNutritionData();
        break;
    }
  }

  void _reloadLocalState() {
    context.read<DashboardProvider>().loadDashboard();
    context.read<HabitProvider>().loadHabits();
    context.read<WorkoutProvider>().loadScheduleAndTemplates();
    context.read<JournalProvider>().loadEntries();
    context.read<ExpenseProvider>().refreshExpenseData();
    context.read<FoodProvider>().loadFoods();
    context.read<MealProvider>().refreshNutritionData();
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LocalAuthProvider>();
    return HouseAmbientBackground(
      houseKeyOverride: auth.houseKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: [
            LazyTabWrapper(index: 0, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const DashboardScreen()),
            LazyTabWrapper(index: 1, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const HabitsScreen()),
            LazyTabWrapper(index: 2, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const WorkoutsScreen()),
            LazyTabWrapper(index: 3, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const JournalScreen()),
            LazyTabWrapper(index: 4, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const MoneyScreen()),
            LazyTabWrapper(index: 5, selectedIndex: _selectedIndex, maxWarmupIndex: _maxWarmupIndex, child: const NutritionScreen()),
          ],
        ),
        bottomNavigationBar: PremiumBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations,
        ),
      ),
    );
  }
}

class LazyTabWrapper extends StatefulWidget {
  const LazyTabWrapper({
    required this.index,
    required this.selectedIndex,
    required this.maxWarmupIndex,
    required this.child,
    super.key,
  });

  final int index;
  final int selectedIndex;
  final int maxWarmupIndex;
  final Widget child;

  @override
  State<LazyTabWrapper> createState() => _LazyTabWrapperState();
}

class _LazyTabWrapperState extends State<LazyTabWrapper> with AutomaticKeepAliveClientMixin {
  bool _initialized = false;

  @override
  bool get wantKeepAlive => _initialized;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.index == widget.selectedIndex || widget.index <= widget.maxWarmupIndex) {
      _initialized = true;
    }
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    return widget.child;
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

    const goldColor = Color(0xFFC4B28B);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? goldColor.withValues(alpha: 0.25)
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final destination = destinations[index];
                  final isSelected = index == selectedIndex;
                  final icon = isSelected ? destination.selectedIcon : destination.icon;

                  final activeColor = isDark ? goldColor : colorScheme.primary;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onDestinationSelected(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.4)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: Icon(
                                    icon,
                                    size: 22,
                                    color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 16,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        destination.label,
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
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
          ),
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
