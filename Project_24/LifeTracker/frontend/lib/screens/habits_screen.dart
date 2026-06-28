import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/add_habit_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/habit_provider.dart';
import '../utils/habit_notification_helper.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/habit_list_card.dart';
import '../widgets/lists/async_entity_list_body.dart';
import '../widgets/offline_sync_banner.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadHabits();
    });
  }

  Future<void> _openAddHabit() async {
    await Navigator.of(context).push(
      AddHabitPageRoute(
        settings: const RouteSettings(name: '/add-habit'),
      ),
    );
    if (mounted) {
      await context.read<HabitProvider>().loadHabits();
    }
  }

  Future<void> _onDelete(BuildContext context, int habitId, String habitName) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete habit',
      message: 'Are you sure you want to delete "$habitName"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    await HabitNotificationHelper.cancelForHabit(habitId);

    if (!context.mounted) return;

    final provider = context.read<HabitProvider>();
    final success = await provider.deleteHabit(habitId);

    if (!context.mounted) return;

    SnackBarUtils.showMessage(
      context,
      success ? 'Habit deleted' : provider.errorMessage ?? 'Failed to delete habit',
      isError: !success && provider.errorMessage != null,
    );
  }

  void _showErrorSnackBar(BuildContext context, String? message) {
    if (message == null) return;
    SnackBarUtils.showError(context, message);
    context.read<HabitProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (provider.errorMessage != null && provider.habits.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, provider.errorMessage);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_screen_fab',
        onPressed: _openAddHabit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Quest'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AsyncEntityListBody(
          isLoading: provider.isLoading,
          isEmpty: provider.habits.isEmpty,
          errorMessage: provider.errorMessage,
          onRefresh: provider.loadHabits,
          topBanner: OfflineSyncBanner(
            isOffline: provider.isOffline,
            syncMessage: provider.syncMessage,
            lastSyncedAt: provider.lastSyncedAt,
            isRefreshing: provider.isRefreshing,
            hasPendingSync: provider.hasPendingSync,
          ),
          headerTitle: 'Daily Quests',
          headerSubtitle: 'Complete the rites you want to build consistency around.',
          loadingMessage: 'Loading quests...',
          errorTitle: 'No data available',
          emptyIcon: Icons.check_circle_outline,
          emptyTitle: 'No quests yet',
          emptyMessage: 'Tap the button below to create your first quest and start building consistency.',
          emptyActionLabel: 'Add Quest',
          onEmptyAction: _openAddHabit,
          itemCount: provider.habits.length,
          itemBuilder: (context, index) {
            final habit = provider.habits[index];
            final completed = provider.isCompletedToday(habit.id);

            return HabitListCard(
              key: ValueKey(habit.id),
              habit: habit,
              completed: completed,
              isPendingSync: provider.syncStatusForHabit(habit.id)?.isPending ?? false,
              onTap: () => AppNavigator.openHabitDetails(context, habit.id),
              onComplete: () => provider.completeHabit(habit.id),
              onUndo: () => provider.undoHabit(habit.id),
              onDelete: () => _onDelete(context, habit.id, habit.name),
            );
          },
        ),
      ),
    );
  }
}
