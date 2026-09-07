import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/add_habit_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/local_auth_provider.dart';
import '../providers/habit_provider.dart';
import '../utils/habit_notification_helper.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/habit_list_card.dart';
import '../widgets/lists/async_entity_list_body.dart';
import '../widgets/offline_sync_banner.dart';

import '../services/user_xp_manager.dart';
import '../widgets/house_level_up_dialog.dart';
import '../widgets/focus_shield_dialog.dart';
import 'scrolls_library_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

    final userId = 1;
    if (userId != null) {
      await HabitNotificationHelper.cancelForHabit(userId: userId, habitId: habitId);
    }

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
    super.build(context);
    final provider = context.watch<HabitProvider>();
    final todayHabits = provider.todayHabits;
    final hasAnyHabits = provider.habits.isNotEmpty;

    if (provider.errorMessage != null && provider.habits.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, provider.errorMessage);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
        actions: [
          IconButton(
            tooltip: 'Focus Shield 🛡️',
            icon: const Icon(Icons.shield_rounded, color: Color(0xFFC4B28B)),
            onPressed: () => FocusShieldDialog.show(context),
          ),
          IconButton(
            tooltip: 'Scrolls Library 📚',
            icon: const Icon(Icons.auto_stories_rounded, color: Color(0xFFC4B28B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ScrollsLibraryScreen(),
                ),
              );
            },
          ),
        ],
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
          isEmpty: todayHabits.isEmpty,
          errorMessage: provider.errorMessage,
          onRefresh: provider.loadHabits,
          headerTitle: 'Daily Quests',
          headerSubtitle: 'Complete the rites you want to build consistency around.',
          loadingMessage: 'Loading quests...',
          errorTitle: 'No data available',
          emptyIcon: Icons.check_circle_outline,
          emptyTitle: hasAnyHabits ? 'No quests scheduled today' : 'No quests yet',
          emptyMessage: hasAnyHabits
              ? 'No quests are scheduled for today. Tap below to add a new quest.'
              : 'Tap the button below to create your first quest and start building consistency.',
          emptyActionLabel: 'Add Quest',
          onEmptyAction: _openAddHabit,
          itemCount: todayHabits.length,
          itemBuilder: (context, index) {
            final habit = todayHabits[index];
            final completed = provider.isCompletedToday(habit.id);
            final streak = provider.streakForHabit(habit.id);

            return HabitListCard(
              key: ValueKey(habit.id),
              habit: habit,
              completed: completed,
              streak: streak,
              isPendingSync: provider.syncStatusForHabit(habit.id)?.isPending ?? false,
              onTap: () => AppNavigator.openHabitDetails(context, habit.id),
              onComplete: () async {
                final auth = context.read<LocalAuthProvider>();
                final house = auth.house;
                final oldXp = await UserXpManager.getXp();
                final oldLevel = UserXpManager.getLevel(oldXp);

                await provider.completeHabit(habit.id);

                final newXp = await UserXpManager.getXp();
                final newLevel = UserXpManager.getLevel(newXp);

                if (context.mounted && newLevel > oldLevel) {
                  final rank = UserXpManager.getRank(newLevel);
                  HouseLevelUpDialog.show(context, newLevel: newLevel, rankTitle: rank, house: house);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text(house.sigil, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quest "${habit.name}" Completed for House ${house.name}! "${house.motto}"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: house.bannerGradient[1],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: house.accent.withValues(alpha: 0.6)),
                      ),
                      duration: const Duration(milliseconds: 2200),
                    ),
                  );
                }
              },
              onUndo: () => provider.undoHabit(habit.id),
              onDelete: () => _onDelete(context, habit.id, habit.name),
            );
          },
        ),
      ),
    );
  }
}
