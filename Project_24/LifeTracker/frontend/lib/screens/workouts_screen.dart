import 'dart:async';

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

class _WorkoutsScreenState extends State<WorkoutsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && mounted) {
                          final ok = await context.read<WorkoutProvider>().assignTemplateToDate(template, picked);
                          if (mounted) {
                            Navigator.of(ctx).pop();
                            if (ok) {
                              SnackBarUtils.showMessage(context, 'Assigned "${template.name}" to ${DateFormat('MMM d, yyyy').format(picked)}!');
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.event_available_rounded, color: Color(0xFFC4B28B)),
                      label: Text('Assign to Date (${DateFormat('MMM d').format(_selectedDate)})'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignTemplateModal(DateTime targetDate) {
    final theme = Theme.of(context);
    final provider = context.read<WorkoutProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Assign Workout Plan',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            Navigator.pop(ctx);
                            _showAssignTemplateModal(picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(DateFormat('MMM d, yyyy').format(targetDate)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Select a workout template to schedule for ${DateFormat('EEEE, MMM d').format(targetDate)}:',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: provider.templates.isEmpty
                        ? const Center(child: Text('No templates found. Create one first!'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: provider.templates.length,
                            itemBuilder: (_, i) {
                              final t = provider.templates[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: t.isPreset ? Colors.blue.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      t.isPreset ? Icons.verified_rounded : Icons.fitness_center_rounded,
                                      color: t.isPreset ? Colors.blue : theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${t.category} · ${t.exercises.length} Exercises'),
                                  trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFC4B28B)),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final ok = await provider.assignTemplateToDate(t, targetDate);
                                    if (mounted && ok) {
                                      SnackBarUtils.showMessage(context, 'Assigned "${t.name}" to ${DateFormat('MMM d, yyyy').format(targetDate)}!');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
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
    super.build(context);
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
              const SizedBox(height: AppSpacing.md),
              _TrainingQuickToolsBar(provider: provider),
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
                Expanded(
                  child: Text(
                    '${DateFormat('MMM d').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _showAssignTemplateModal(schedule.scheduledDate),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Swap / Change Workout Template'),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: provider.isActionLoading ? null : _missedToday,
                      icon: const Icon(Icons.forward_rounded, color: Colors.orange),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Missed Today (Shift Cycle)'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (schedule.isRest) ...[
              OutlinedButton.icon(
                onPressed: () => _showAssignTemplateModal(schedule.scheduledDate),
                icon: const Icon(Icons.add_task_rounded),
                label: Text('Assign Workout Plan to ${DateFormat('MMM d').format(schedule.scheduledDate)}'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text('${ex.sequenceOrder}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.exerciseName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  // Allow wrapping instead of forcing 1 line which might truncate or overflow
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${ex.sets}×${ex.reps}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                      child: Text('${ex.restSeconds}s rest', style: const TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Workout Templates & Presets',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
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

// ── Training Quick Tools Bar ───────────────────────────────────────────────────

class _TrainingQuickToolsBar extends StatelessWidget {
  const _TrainingQuickToolsBar({required this.provider});
  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolChip(
            icon: Icons.emoji_events_outlined,
            label: 'Hall of Valor',
            color: Colors.amber,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _HallOfValorDialog(templates: provider.templates),
            ),
          ),
          const SizedBox(width: 8),
          _ToolChip(
            icon: Icons.timer_outlined,
            label: 'Rest Timer',
            color: Colors.lightBlue,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _RestTimerDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hall of Valor (PR Wall) Dialog ─────────────────────────────────────────────

class _HallOfValorDialog extends StatelessWidget {
  const _HallOfValorDialog({required this.templates});
  final List<WorkoutTemplateModel> templates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFC4B28B);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.emoji_events_outlined, color: Colors.amber),
          SizedBox(width: 8),
          Flexible(child: Text('Hall of Valor (PRs)', overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: templates.isEmpty
                ? [const Text('No workout templates recorded yet.')]
                : templates.expand((t) => t.exercises).map((ex) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gold.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded, size: 20, color: gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.exerciseName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text('${ex.sets} Sets · ${ex.reps} Reps', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${ex.restSeconds}s rest',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

// ── Rest Timer Dialog ──────────────────────────────────────────────────────────

class _RestTimerDialog extends StatefulWidget {
  const _RestTimerDialog();

  @override
  State<_RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<_RestTimerDialog> {
  int _secondsLeft = 90;
  int _totalSeconds = 90;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _secondsLeft = seconds;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _isRunning = false;
          timer.cancel();
        }
      });
    });
  }

  void _togglePause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else if (_secondsLeft > 0) {
      _startTimer(_secondsLeft);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _totalSeconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.lightBlue),
          SizedBox(width: 8),
          Text('Rest Timer'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: Colors.lightBlue.withValues(alpha: 0.15),
                  color: Colors.lightBlue,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(_isRunning ? 'Resting...' : (_secondsLeft == 0 ? 'Time Up! 💪' : 'Paused'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Play/Pause/Reset row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _togglePause,
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                iconSize: 28,
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(onPressed: () => _startTimer(30), child: const Text('30s')),
              OutlinedButton(onPressed: () => _startTimer(45), child: const Text('45s')),
              OutlinedButton(onPressed: () => _startTimer(60), child: const Text('60s')),
              OutlinedButton(onPressed: () => _startTimer(90), child: const Text('90s')),
              OutlinedButton(onPressed: () => _startTimer(120), child: const Text('2m')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

