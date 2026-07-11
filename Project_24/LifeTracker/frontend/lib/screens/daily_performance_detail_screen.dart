import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_performance_response.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/chronicle_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';

class DailyPerformanceDetailScreen extends StatefulWidget {
  const DailyPerformanceDetailScreen({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  State<DailyPerformanceDetailScreen> createState() => _DailyPerformanceDetailScreenState();
}

class _DailyPerformanceDetailScreenState extends State<DailyPerformanceDetailScreen> {
  DailyPerformanceResponse? _performance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final performance = await context.read<ProfileService>().getDailyPerformance(widget.date);
      if (!mounted) return;
      setState(() {
        _performance = performance;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEEE, MMM d').format(widget.date);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _performance == null) {
      return const LoadingView(message: 'Opening the day\'s chronicle...');
    }

    if (_error != null && _performance == null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load day',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    final day = _performance!;
    final theme = Theme.of(context);
    const gold = Color(0xFFC4B28B);
    final nutrition = day.nutrition;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ChronicleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Honor for this day',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${day.earnedPoints} / ${day.possiblePoints} points',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${day.completedHabits}/${day.plannedHabits} quests · '
                  '${day.completionPercentage.round()}% complete',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Habits',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (day.habits.isEmpty)
            ChronicleCard(
              child: Text(
                'No habits were planned for this date.',
                style: theme.textTheme.bodyLarge,
              ),
            )
          else
            ...day.habits.map(
              (habit) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ChronicleCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        habit.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: habit.completed ? gold : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.habitName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              habit.completed
                                  ? '+${habit.pointsAwarded} pts awarded'
                                  : '${habit.configuredPoints} pts available',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nutrition',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ChronicleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nutrition.calories.round()} / ${nutrition.calorieGoal.round()} kcal',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'P ${nutrition.protein.toStringAsFixed(1)}g · '
                  'C ${nutrition.carbs.toStringAsFixed(1)}g · '
                  'F ${nutrition.fat.toStringAsFixed(1)}g · '
                  'Fi ${nutrition.fiber.toStringAsFixed(1)}g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (nutrition.meals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ...nutrition.meals.map(
                    (meal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.mealType,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${meal.calories.round()} kcal',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
