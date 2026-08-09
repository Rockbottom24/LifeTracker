import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout/workout_schedule_model.dart';
import '../models/workout/workout_template_model.dart';
import '../providers/workout_provider.dart';
import '../screens/edit_template_screen.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadScheduleAndTemplates(date: _selectedDate);
    });
  }

  Future<void> _refresh() async {
    await context.read<WorkoutProvider>().loadScheduleAndTemplates(date: _selectedDate);
  }

  Future<void> _missedToday() async {
    final provider = context.read<WorkoutProvider>();
    final ok = await provider.missedToday();
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showMessage(context, 'Today marked as missed. Cycle auto-shifted to tomorrow!');
    } else if (provider.errorMessage != null) {
      SnackBarUtils.showError(context, provider.errorMessage!);
    }
  }

  Future<void> _completeWorkout(WorkoutScheduleModel schedule) async {
    final provider = context.read<WorkoutProvider>();
    final ok = await provider.completeWorkout(schedule.id);
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showMessage(context, 'Workout completed! Great work! 💪');
    } else if (provider.errorMessage != null) {
      SnackBarUtils.showError(context, provider.errorMessage!);
    }
  }

  void _openEditTemplate([WorkoutTemplateModel? template]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditTemplateScreen(template: template),
      ),
    );
  }

  void _showTemplateDetailsModal(WorkoutTemplateModel template) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: template.isPreset ? Colors.blue.withValues(alpha: 0.15) : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          template.isPreset ? 'PRESET' : 'CUSTOM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: template.isPreset ? Colors.blue : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (template.description != null && template.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      template.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Exercises (${template.exercises.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...template.exercises.map((ex) => _buildExerciseRow(ex, theme)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (!template.isPreset) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _openEditTemplate(template);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Template'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: PrimaryButton(
                          label: 'Done',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WorkoutProvider>();

    if (provider.isLoading && provider.weeklySchedule.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    WorkoutScheduleModel? activeSchedule;
    for (final item in provider.weeklySchedule) {
      if (DateUtils.isSameDay(item.scheduledDate, _selectedDate)) {
        activeSchedule = item;
        break;
      }
    }
    activeSchedule ??= provider.todaySchedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Realm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildWeeklyStrip(provider, theme),
              const SizedBox(height: AppSpacing.lg),
              if (activeSchedule != null) _buildScheduleCard(activeSchedule, provider, theme),
              const SizedBox(height: AppSpacing.xl),
              _buildTemplatesHeader(theme),
              const SizedBox(height: AppSpacing.sm),
              _buildTemplatesList(provider, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStrip(WorkoutProvider provider, ThemeData theme) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final startDate = provider.weeklySchedule.isNotEmpty
        ? provider.weeklySchedule.first.scheduledDate
        : _selectedDate;
    final endDate = startDate.plusDays(6);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Week',
                  onPressed: () {
                    final prevWeek = _selectedDate.subtract(const Duration(days: 7));
                    setState(() => _selectedDate = prevWeek);
                    provider.loadScheduleAndTemplates(date: prevWeek);
                  },
                ),
                Text(
                  '${DateFormat('MMM d').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Week',
                  onPressed: () {
                    final nextWeek = _selectedDate.add(const Duration(days: 7));
                    setState(() => _selectedDate = nextWeek);
                    provider.loadScheduleAndTemplates(date: nextWeek);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(provider.weeklySchedule.length, (index) {
                  final schedule = provider.weeklySchedule[index];
                  final dayName = dayNames[schedule.scheduledDate.weekday - 1];
                  final isSelected = DateUtils.isSameDay(schedule.scheduledDate, _selectedDate);
                  final isToday = DateUtils.isSameDay(schedule.scheduledDate, DateTime.now());

                  Color badgeColor;
                  IconData badgeIcon;
                  if (schedule.isCompleted) {
                    badgeColor = Colors.green;
                    badgeIcon = Icons.check_circle_rounded;
                  } else if (schedule.isMissed) {
                    badgeColor = Colors.redAccent;
                    badgeIcon = Icons.cancel_rounded;
                  } else if (schedule.isRest) {
                    badgeColor = Colors.amber;
                    badgeIcon = Icons.hotel_rounded;
                  } else {
                    badgeColor = theme.colorScheme.primary;
                    badgeIcon = Icons.fitness_center_rounded;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedDate = schedule.scheduledDate);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                              : (isToday ? theme.colorScheme.surfaceContainerHighest : Colors.transparent),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(badgeIcon, size: 20, color: badgeColor),
                            const SizedBox(height: 4),
                            Text(
                              '${schedule.scheduledDate.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(WorkoutScheduleModel schedule, WorkoutProvider provider, ThemeData theme) {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(schedule.scheduledDate);
    final isToday = DateUtils.isSameDay(schedule.scheduledDate, DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isToday ? 'TODAY • $formattedDate' : formattedDate).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schedule.customTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(schedule.status, theme),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (schedule.template != null && schedule.template!.exercises.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Exercises (${schedule.template!.exercises.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...schedule.template!.exercises.map((ex) => _buildExerciseRow(ex, theme)),
            ] else if (schedule.isRest) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.bedtime_outlined, size: 44, color: theme.colorScheme.primary),
                    const SizedBox(height: 6),
                    Text('Rest & Recovery Day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Muscle growth happens during rest.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!schedule.isCompleted && !schedule.isRest) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Complete Workout',
                    icon: Icons.check_circle_outline,
                    isLoading: provider.isActionLoading,
                    onPressed: () => _completeWorkout(schedule),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: provider.isActionLoading ? null : _missedToday,
                      icon: const Icon(Icons.forward_rounded, color: Colors.orange),
                      label: const Text('Missed Today (Shift Cycle)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (schedule.isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Completed! Great effort!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        bg = Colors.green.withValues(alpha: 0.18);
        fg = Colors.green;
        label = 'COMPLETED';
      case 'MISSED':
        bg = Colors.red.withValues(alpha: 0.18);
        fg = Colors.red;
        label = 'MISSED';
      case 'REST':
        bg = Colors.amber.withValues(alpha: 0.18);
        fg = Colors.amber.shade800;
        label = 'REST DAY';
      default:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        label = 'PLANNED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildExerciseRow(WorkoutTemplateExerciseModel ex, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text('${ex.sequenceOrder}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ex.exerciseName,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${ex.sets}×${ex.reps}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
            child: Text('${ex.restSeconds}s rest', style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Workout Templates & Presets',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () => _openEditTemplate(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildTemplatesList(WorkoutProvider provider, ThemeData theme) {
    if (provider.templates.isEmpty) {
      return const EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'No Templates Found',
        message: 'Create a custom workout template or load pre-built PDF routines.',
      );
    }

    return Column(
      children: provider.templates.map((template) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => _showTemplateDetailsModal(template),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: template.isPreset ? Colors.blue.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(
                template.isPreset ? Icons.verified_rounded : Icons.edit_note_rounded,
                color: template.isPreset ? Colors.blue : theme.colorScheme.primary,
              ),
            ),
            title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${template.category} • ${template.exercises.length} Exercises',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}

extension _DateTimeUtils on DateTime {
  DateTime plusDays(int days) => add(Duration(days: days));
}
