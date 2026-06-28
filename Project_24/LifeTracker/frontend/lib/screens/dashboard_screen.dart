import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_response.dart';
import '../navigation/add_habit_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/learning_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../utils/dashboard_view_data_mapper.dart';
import '../widgets/offline_sync_banner.dart';
import '../widgets/dashboard/dashboard_hero_card.dart';
import '../widgets/dashboard/dashboard_skeleton.dart';
import '../widgets/dashboard/progress_ring_card.dart';
import '../widgets/dashboard/stats_grid.dart';
import '../widgets/dashboard/todays_habits_section.dart';
import '../widgets/dashboard/todays_learning_section.dart';
import '../widgets/dashboard/upcoming_reminder_card.dart';
import '../widgets/dashboard/weekly_progress_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_form_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<HabitProvider>().loadHabits(),
      context.read<LearningProvider>().loadSessions(),
    ]);
  }

  Future<void> _completeHabit(int habitId) async {
    await context.read<HabitProvider>().completeHabit(habitId);
    if (mounted) {
      await context.read<DashboardProvider>().loadDashboard();
    }
  }

  Future<void> _undoHabit(int habitId) async {
    await context.read<HabitProvider>().undoHabit(habitId);
    if (mounted) {
      await context.read<DashboardProvider>().loadDashboard();
    }
  }

  void _openHabitDetails(int habitId) {
    AppNavigator.openHabitDetails(context, habitId);
  }

  void _openCreateHabit() {
    Navigator.of(context).push(
      AddHabitPageRoute(settings: const RouteSettings(name: '/add-habit')),
    );
  }

  void _openLearningDetails(int sessionId) {
    AppNavigator.openLearningDetails(context, sessionId);
  }

  Future<void> _quickStartLearning(int sessionId) async {
    await context.read<LearningProvider>().startSession(sessionId);
    if (mounted) _openLearningDetails(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final learningProvider = context.watch<LearningProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = dashboardProvider.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Realm'),
        actions: [
          IconButton(
            onPressed: dashboardProvider.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(dashboardProvider, habitProvider, learningProvider, auth, dashboard),
        ),
      ),
    );
  }

  Widget _buildBody(
    DashboardProvider dashboardProvider,
    HabitProvider habitProvider,
    LearningProvider learningProvider,
    AuthProvider auth,
    DashboardResponse? dashboard,
  ) {
    if (dashboardProvider.isLoading && dashboard == null) {
      return const DashboardSkeleton();
    }

    if (dashboardProvider.errorMessage != null && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No data available',
            message: dashboardProvider.errorMessage!,
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
        ],
      );
    }

    if (dashboard == null) {
      return const SizedBox.shrink();
    }

    final viewData = DashboardViewDataMapper.from(
      response: dashboard,
      habits: habitProvider.habits,
    );
    final house = auth.house;
    final experience = (viewData.summary.completedHabits * 120) +
        (viewData.summary.totalHabits * 35) +
        (viewData.summary.currentStreak * 45);
    final level = (experience ~/ 500) + 1;
    final rank = _rankForLevel(level);

    if (viewData.summary.totalHabits == 0 &&
        habitProvider.habits.isEmpty &&
        learningProvider.sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EmptyState(
            icon: Icons.auto_graph_rounded,
            title: 'Welcome to LifeTracker',
            message: 'Create your first habit to begin building your streak.',
            actionLabel: 'Create Habit',
            onAction: _openCreateHabit,
          ),
        ],
      );
    }

    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        OfflineSyncBanner(
          isOffline: dashboardProvider.isOffline,
          syncMessage: dashboardProvider.syncMessage,
          lastSyncedAt: dashboardProvider.lastSyncedAt,
          isRefreshing: dashboardProvider.isRefreshing,
          hasPendingSync: dashboardProvider.hasPendingSync,
        ),
        ResponsiveFormContainer(
          child: isTablet
              ? _buildTabletLayout(viewData, learningProvider, auth, house, experience, level, rank)
              : _buildPhoneLayout(viewData, learningProvider, auth, house, experience, level, rank),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(
    DashboardViewData viewData,
    LearningProvider learningProvider,
    AuthProvider auth,
    HouseTheme house,
    int experience,
    int level,
    String rank,
  ) {
    return Column(
      children: [
        DashboardHeroCard(
          profileLabel: auth.profileLabel,
          house: house,
          houseMotto: house.motto,
          currentDate: viewData.currentDate,
          experience: experience,
          level: level,
          rank: rank,
        ),
        const SizedBox(height: AppSpacing.md),
        ProgressRingCard(summary: viewData.summary),
        const SizedBox(height: AppSpacing.md),
        TodaysLearningSection(
          sessions: learningProvider.todaySessions,
          onQuickStart: (session) => _quickStartLearning(session.id),
          onOpenDetails: _openLearningDetails,
        ),
        const SizedBox(height: AppSpacing.md),
        UpcomingReminderCard(reminder: viewData.upcomingReminder),
        const SizedBox(height: AppSpacing.md),
        TodaysHabitsSection(
          habits: viewData.todayHabits,
          onHabitTap: _openHabitDetails,
          onComplete: _completeHabit,
          onUndo: _undoHabit,
        ),
        const SizedBox(height: AppSpacing.md),
        WeeklyProgressCard(days: viewData.weeklyProgress),
        const SizedBox(height: AppSpacing.md),
        StatsGrid(summary: viewData.summary),
      ],
    );
  }

  Widget _buildTabletLayout(
    DashboardViewData viewData,
    LearningProvider learningProvider,
    AuthProvider auth,
    HouseTheme house,
    int experience,
    int level,
    String rank,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DashboardHeroCard(
                profileLabel: auth.profileLabel,
                house: house,
                houseMotto: house.motto,
                currentDate: viewData.currentDate,
                experience: experience,
                level: level,
                rank: rank,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: ProgressRingCard(summary: viewData.summary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TodaysLearningSection(
          sessions: learningProvider.todaySessions,
          onQuickStart: (session) => _quickStartLearning(session.id),
          onOpenDetails: _openLearningDetails,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: UpcomingReminderCard(reminder: viewData.upcomingReminder)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: WeeklyProgressCard(days: viewData.weeklyProgress)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TodaysHabitsSection(
          habits: viewData.todayHabits,
          onHabitTap: _openHabitDetails,
          onComplete: _completeHabit,
          onUndo: _undoHabit,
        ),
        const SizedBox(height: AppSpacing.md),
        StatsGrid(summary: viewData.summary),
      ],
    );
  }

  String _rankForLevel(int level) {
    if (level >= 20) return 'King';
    if (level >= 16) return 'Hand of the King';
    if (level >= 12) return 'Warden';
    if (level >= 8) return 'Lord';
    if (level >= 5) return 'Knight';
    if (level >= 3) return 'Squire';
    return 'Smallfolk';
  }
}
