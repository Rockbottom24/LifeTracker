import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_response.dart';
import '../models/meal_type.dart';
import '../models/workout/workout_schedule_model.dart';
import '../providers/habit_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';

class HistoryDashboardScreen extends StatefulWidget {
  const HistoryDashboardScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HistoryDashboardScreen> createState() => _HistoryDashboardScreenState();
}

class _HistoryDashboardScreenState extends State<HistoryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const gold = Color(0xFFC4B28B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Historical Chronicle'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_rounded), text: 'Nutrition'),
            Tab(icon: Icon(Icons.military_tech_rounded), text: 'Quests'),
            Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Training'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month_rounded, size: 20, color: gold),
                  label: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(
                        () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setState(
                        () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNutritionHistoryTab(context, theme, gold, isDark),
                _buildQuestsHistoryTab(context, theme, gold, isDark),
                _buildTrainingHistoryTab(context, theme, gold, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nutrition Tab ──────────────────────────────────────────────────────────
  Widget _buildNutritionHistoryTab(
      BuildContext context, ThemeData theme, Color gold, bool isDark) {
    final mealProvider = context.watch<MealProvider>();
    final allMeals = mealProvider.meals;
    final goals = mealProvider.goals;

    final dateMeals = allMeals.where((m) => _isSameDay(m.mealDate, _selectedDate)).toList();

    double totalCal = 0, totalP = 0, totalC = 0, totalF = 0, totalFib = 0;
    for (final m in dateMeals) {
      totalCal += m.totalCalories;
      totalP += m.totalProtein;
      totalC += m.totalCarbs;
      totalF += m.totalFat;
      totalFib += m.totalFiber;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Daily Nutrient Macro Summary Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Daily Nutrition Record',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${totalCal.round()} / ${goals.calorieGoal.round()} kcal',
                    style: TextStyle(fontWeight: FontWeight.bold, color: gold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMacroProgressRow('Protein', totalP, goals.proteinGoal, 'g', Colors.redAccent),
              const SizedBox(height: 8),
              _buildMacroProgressRow('Carbs', totalC, goals.carbsGoal, 'g', Colors.lightBlueAccent),
              const SizedBox(height: 8),
              _buildMacroProgressRow('Fats', totalF, goals.fatGoal, 'g', Colors.amberAccent),
              const SizedBox(height: 8),
              _buildMacroProgressRow('Fiber', totalFib, goals.fiberGoal, 'g', Colors.greenAccent),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Logged Meals for Selected Date
        Text('Meals Logged (${dateMeals.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),

        if (dateMeals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                'No meals recorded for this date.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...dateMeals.map((meal) => _buildMealItemCard(meal, theme, isDark)),
      ],
    );
  }

  Widget _buildMacroProgressRow(
      String label, double current, double goal, String unit, Color barColor) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${current.round()}/${goal.round()} $unit',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white10,
            color: barColor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMealItemCard(MealResponse meal, ThemeData theme, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC4B28B).withValues(alpha: 0.2),
          child: Icon(_mealIcon(meal.mealType), color: const Color(0xFFC4B28B), size: 20),
        ),
        title: Text(
          meal.mealType.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${meal.totalCalories.round()} kcal • P:${meal.totalProtein.round()}g C:${meal.totalCarbs.round()}g F:${meal.totalFat.round()}g',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        children: meal.items
            .map(
              (item) => ListTile(
                dense: true,
                title: Text(item.foodName),
                subtitle: Text('${item.quantity} ${item.unit}'),
                trailing: Text('${item.calories.round()} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
            .toList(),
      ),
    );
  }

  IconData _mealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast_rounded;
      case MealType.lunch:
        return Icons.lunch_dining_rounded;
      case MealType.dinner:
        return Icons.dinner_dining_rounded;
      case MealType.snack:
        return Icons.cookie_rounded;
    }
  }

  // ── Quests Tab ─────────────────────────────────────────────────────────────
  Widget _buildQuestsHistoryTab(
      BuildContext context, ThemeData theme, Color gold, bool isDark) {
    final habitProvider = context.watch<HabitProvider>();
    final habits = habitProvider.habitsForDate(_selectedDate);

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final completedCount = isToday
        ? habits.where((h) => habitProvider.isCompletedToday(h.id)).length
        : 0;

    int totalPointsAvailable = 0;
    int pointsEarned = 0;

    for (final h in habits) {
      totalPointsAvailable += h.points;
      if (isToday && habitProvider.isCompletedToday(h.id)) {
        pointsEarned += h.points;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Honour Points Score Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Honour Points Scored',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '$pointsEarned / $totalPointsAvailable pts',
                    style: TextStyle(fontWeight: FontWeight.bold, color: gold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalPointsAvailable > 0
                      ? (pointsEarned / totalPointsAvailable).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: Colors.white10,
                  color: gold,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$completedCount of ${habits.length} quests completed for selected date',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Quests Chronicle (${habits.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),

        if (habits.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text('No quests scheduled for selected date.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...habits.map((h) {
            final isDone = isToday && habitProvider.isCompletedToday(h.id);
            return GlassCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : Colors.grey,
                ),
                title: Text(
                  h.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('+${h.points} honour points'),
                trailing: Chip(
                  label: Text(isDone ? 'Completed' : 'Pending',
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor:
                      isDone ? Colors.green.withValues(alpha: 0.2) : Colors.black12,
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Training Tab ───────────────────────────────────────────────────────────
  Widget _buildTrainingHistoryTab(
      BuildContext context, ThemeData theme, Color gold, bool isDark) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final weeklySchedule = workoutProvider.weeklySchedule;

    final dateSchedule = weeklySchedule.where((s) => _isSameDay(s.scheduledDate, _selectedDate)).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scheduled Workouts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Chip(
                label: Text('${dateSchedule.length} Assigned', style: const TextStyle(color: Colors.black)),
                backgroundColor: gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (dateSchedule.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text('No training session scheduled for this date.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...dateSchedule.map((sched) => _buildScheduleCard(sched, theme, gold)),
      ],
    );
  }

  Widget _buildScheduleCard(WorkoutScheduleModel sched, ThemeData theme, Color gold) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sched.customTitle ?? sched.template?.name ?? 'Training Session',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(sched.status),
                backgroundColor: sched.status == 'COMPLETED' ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
              ),
            ],
          ),
          if (sched.template != null && sched.template!.exercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Exercises (${sched.template!.exercises.length}):',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            ...sched.template!.exercises.map(
              (ex) => Text('• ${ex.exerciseName} (${ex.sets} sets x ${ex.reps} reps)'),
            ),
          ],
        ],
      ),
    );
  }
}
