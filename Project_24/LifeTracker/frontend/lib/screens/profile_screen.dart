import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout/workout_schedule_model.dart';
import '../providers/habit_provider.dart';
import '../providers/local_auth_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../widgets/chronicle_card.dart';
import '../widgets/glass_card.dart';
import 'history_dashboard_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MealProvider>().loadDashboard();
      context.read<WorkoutProvider>().loadScheduleAndTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<LocalAuthProvider>();
    final meal = context.watch<MealProvider>();
    final workout = context.watch<WorkoutProvider>();
    final habit = context.watch<HabitProvider>();

    final house = HouseTheme.fromKey(auth.houseKey);
    const gold = Color(0xFFC4B28B);
    const cardRadius = 20.0;

    // Compute habit stats from HabitProvider
    final allHabits = habit.todayHabits;
    final completed = allHabits.where((h) => habit.isCompletedToday(h.id)).length;
    final total = allHabits.length;
    final habitPct = total > 0 ? completed / total : 0.0;

    // Today's workout
    final today = DateTime.now();
    WorkoutScheduleModel? todaySchedule;
    for (final s in workout.weeklySchedule) {
      if (DateUtils.isSameDay(s.scheduledDate, today)) {
        todaySchedule = s;
        break;
      }
    }
    todaySchedule ??= workout.todaySchedule;

    // Nutrition
    final nutrition = meal.todaySummary;
    final goals = meal.goals;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<MealProvider>().loadDashboard();
          context.read<WorkoutProvider>().loadScheduleAndTemplates();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          children: [
            // ── Hero Card ────────────────────────────────────────────────────
            GlassCard(
              borderRadius: cardRadius,
              borderColor: gold.withValues(alpha: 0.35),
              borderWidth: 1.2,
              backgroundColor: Colors.black.withValues(alpha: 0.28),
              gradient: LinearGradient(
                colors: house.bannerGradient.map((c) => c.withValues(alpha: 0.38)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: house.accent.withValues(alpha: 0.25),
                          border: Border.all(color: gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: house.accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: auth.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  auth.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(house.icon, color: gold, size: 30),
                                ),
                              )
                            : Icon(house.icon, color: gold, size: 30),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.firstName ?? 'Traveler',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'House ${house.name} · ${house.displayName}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (auth.email != null)
                              Text(
                                auth.email!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Sigil
                      Text(house.sigil, style: const TextStyle(fontSize: 36, color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, color: gold, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            house.motto,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: gold,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Realm Honor Badges ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(house.icon, color: gold, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'House Rank',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          habitPct >= 0.8 ? 'Lord Commander' : (habitPct >= 0.4 ? 'Warden' : 'Knight'),
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: gold, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'Daily Quests',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completed / $total Done',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'Energy Intake',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nutrition.calories.round()} kcal',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Habits Today ─────────────────────────────────────────────────
            _sectionLabel('⚔️  Habits Today', theme),
            const SizedBox(height: AppSpacing.sm),
            ChronicleCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryDashboardScreen(initialTabIndex: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quests Completed', style: theme.textTheme.titleMedium),
                      Text(
                        '$completed / $total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: habitPct,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: const Color(0xFFC4B28B),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total == 0
                            ? 'No habits scheduled for today.'
                            : '${(habitPct * 100).round()}% of daily quests done',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Text(
                        'View History →',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Training ─────────────────────────────────────────────────────
            _sectionLabel('🏋️  Training Today', theme),
            const SizedBox(height: AppSpacing.sm),
            ChronicleCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryDashboardScreen(initialTabIndex: 2),
                ),
              ),
              child: todaySchedule == null
                  ? Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No workout scheduled for today.',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'History →',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gold),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _workoutStatusColor(todaySchedule.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _workoutStatusIcon(todaySchedule.status),
                            color: _workoutStatusColor(todaySchedule.status),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todaySchedule.customTitle,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              if (todaySchedule.template != null)
                                Text(
                                  '${todaySchedule.template!.exercises.length} exercises',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _StatusBadge(todaySchedule.status),
                      ],
                    ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Nutrition ─────────────────────────────────────────────────────
            _sectionLabel('🥗  Nutrition Today', theme),
            const SizedBox(height: AppSpacing.sm),
            ChronicleCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryDashboardScreen(initialTabIndex: 0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calories', style: theme.textTheme.titleMedium),
                      Row(
                        children: [
                          Text(
                            '${nutrition.calories.round()} / ${goals.calorieGoal.round()} kcal',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goals.calorieGoal > 0
                          ? (nutrition.calories / goals.calorieGoal).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: Colors.orange,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroChip(
                          label: 'Protein',
                          value: nutrition.protein.round(),
                          goal: goals.proteinGoal.round(),
                          color: Colors.blue.shade300,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MacroChip(
                          label: 'Carbs',
                          value: nutrition.carbs.round(),
                          goal: goals.carbsGoal.round(),
                          color: Colors.amber.shade300,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MacroChip(
                          label: 'Fat',
                          value: nutrition.fat.round(),
                          goal: goals.fatGoal.round(),
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── This Week's Training Strip ─────────────────────────────────
            if (workout.weeklySchedule.isNotEmpty) ...[
              _sectionLabel('📅  This Week', theme),
              const SizedBox(height: AppSpacing.sm),
              ChronicleCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: workout.weeklySchedule.map((s) {
                    final isToday = DateUtils.isSameDay(s.scheduledDate, today);
                    return _WeekDayDot(schedule: s, isToday: isToday, theme: theme);
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Color _workoutStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'MISSED':
        return Colors.red;
      case 'REST':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _workoutStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'MISSED':
        return Icons.cancel_rounded;
      case 'REST':
        return Icons.hotel_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text('${value}g', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text('/ ${goal}g', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
      case 'MISSED':
        color = Colors.red;
      case 'REST':
        color = Colors.amber;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({required this.schedule, required this.isToday, required this.theme});
  final WorkoutScheduleModel schedule;
  final bool isToday;
  final ThemeData theme;

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    if (schedule.isCompleted) {
      dotColor = Colors.green;
    } else if (schedule.isMissed) {
      dotColor = Colors.red;
    } else if (schedule.isRest) {
      dotColor = Colors.amber;
    } else {
      dotColor = theme.colorScheme.primary.withValues(alpha: 0.4);
    }
    final dayName = _dayNames[(schedule.scheduledDate.weekday - 1) % 7];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayName,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${schedule.scheduledDate.day}',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
