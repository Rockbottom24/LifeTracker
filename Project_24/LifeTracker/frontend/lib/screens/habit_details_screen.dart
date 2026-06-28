import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit_response.dart';
import '../navigation/add_habit_page_route.dart';
import '../providers/dashboard_provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/habit_notification_helper.dart';
import '../utils/habit_ui_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class HabitDetailsScreen extends StatefulWidget {
  const HabitDetailsScreen({super.key, required this.habitId});

  final int habitId;

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HabitProvider>();
      provider.loadCategories();
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  HabitResponse? _currentHabit(HabitProvider provider) {
    return provider.findHabitById(widget.habitId);
  }

  Future<void> _openEdit(HabitResponse habit) async {
    await Navigator.of(context).push(
      AddHabitPageRoute(
        settings: RouteSettings(name: '/edit-habit/${habit.id}'),
        habit: habit,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onComplete(HabitProvider provider, HabitResponse habit, bool completed) async {
    if (completed) {
      await provider.undoHabit(habit.id);
    } else {
      await provider.completeHabit(habit.id);
    }
  }

  Future<void> _onDelete(HabitProvider provider, HabitResponse habit) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete habit',
      message: 'Are you sure you want to delete "${habit.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    await HabitNotificationHelper.cancelForHabit(habit.id);
    final success = await provider.deleteHabit(habit.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to delete habit');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final habit = _currentHabit(provider);

    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final accentColor = HabitUiUtils.colorFromHex(habit.colorHex, theme.colorScheme);
    final completed = provider.isCompletedToday(habit.id);
    final categoryName = provider.categoryNameForHabit(habit) ?? 'Not specified';
    final summary = _dashboardSummary(dashboard);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
          ),
          children: [
            ResponsiveFormContainer(
              child: Column(
                children: [
                  DetailHeaderCard(
                    icon: HabitUiUtils.iconFromName(habit.iconName),
                    iconColor: accentColor,
                    title: habit.name,
                    subtitle: habit.description,
                    chips: [
                      DetailStatChip(
                        label: habit.frequencyLabel,
                        color: theme.colorScheme.secondaryContainer,
                      ),
                      if (completed)
                        DetailStatChip(
                          label: 'Completed today',
                          color: theme.colorScheme.primaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      children: [
                        DetailInfoRow(icon: Icons.category_outlined, label: 'Category', value: categoryName),
                        DetailInfoRow(icon: Icons.schedule_outlined, label: 'Reminder time', value: habit.formattedReminderTime ?? 'Not set'),
                        DetailInfoRow(icon: Icons.notifications_outlined, label: 'Notifications', value: habit.notificationsEnabled ? 'Enabled' : 'Disabled'),
                        DetailInfoRow(icon: Icons.local_fire_department_outlined, label: 'Current streak', value: summary.currentStreak),
                        DetailInfoRow(icon: Icons.emoji_events_outlined, label: 'Longest streak', value: summary.longestStreak),
                        DetailInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Started on',
                          value: dateFormat.format(habit.startDate),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  DetailActionsSection(
                    children: [
                      PrimaryButton(
                        label: completed ? 'Undo completion' : 'Complete habit',
                        expand: true,
                        icon: completed ? Icons.undo : Icons.check_circle_outline,
                        onPressed: () => _onComplete(provider, habit, completed),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryActionButton(
                              label: 'Edit',
                              icon: Icons.edit_outlined,
                              onPressed: () => _openEdit(habit),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SecondaryActionButton(
                              label: 'Delete',
                              icon: Icons.delete_outline,
                              isDestructive: true,
                              onPressed: () => _onDelete(provider, habit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StreakSummary _dashboardSummary(DashboardProvider dashboard) {
    final summary = dashboard.dashboard?.summary;

    if (summary == null) {
      return const _StreakSummary(currentStreak: 'Not available', longestStreak: 'Not available');
    }

    return _StreakSummary(
      currentStreak: '${summary.currentStreak} days',
      longestStreak: '${summary.longestStreak} days',
    );
  }
}

class _StreakSummary {
  const _StreakSummary({required this.currentStreak, required this.longestStreak});

  final String currentStreak;
  final String longestStreak;
}
